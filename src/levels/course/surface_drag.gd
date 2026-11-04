class_name SurfaceDrag
extends Node
## Off-piste slowdown: while the skater rolls on grass or gravel, adds extra
## drag on top of the skater's own physics, so concrete is fast and the rough
## is slow (design/levels/copperline-mountain.md §2.1 surface rule, §2.15).
## Lives on the course side so the skater controller stays untouched; the
## physics owner can fold it into a per-surface lookup later.

## Emitted when the ground under the skater changes between fast and slow;
## [param slow_name] is "" on concrete or a player-facing word ("GRASS").
signal slow_ground_changed(slow_name: String)

## The skater being slowed.
var skater: Skater
## The course that knows which surface is where.
var course: CourseBuilder

var _rules: Dictionary = {}
var _dust: CPUParticles3D
var _dust_mat: StandardMaterial3D
var _current: String = ""


func _ready() -> void:
	# Run after the skater has moved this frame.
	process_physics_priority = 10
	_rules = course.surface_rules
	_dust = CPUParticles3D.new()
	_dust.amount = 48
	_dust.lifetime = 0.7
	_dust.emitting = false
	_dust.local_coords = false
	_dust.direction = Vector3(0, 1, 0)
	_dust.spread = 50.0
	_dust.initial_velocity_min = 1.5
	_dust.initial_velocity_max = 3.5
	_dust.gravity = Vector3(0, -6, 0)
	_dust.scale_amount_min = 0.15
	_dust.scale_amount_max = 0.35
	var quad := BoxMesh.new()
	quad.size = Vector3(1, 1, 1)
	_dust.mesh = quad
	_dust_mat = StandardMaterial3D.new()
	_dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_dust.material_override = _dust_mat
	add_child(_dust)


## Player-facing name for a slow surface key, or "" for fast ground.
static func slow_label(key: String) -> String:
	match key:
		"grass":
			return "GRASS"
		"gravel":
			return "GRAVEL"
	return ""


## Extra deceleration (m/s²) for [param surface] at [param speed]:
## quadratic drag plus a constant rolling term, never more than the speed
## itself in one step and never below [param floor_speed] (so pushing still
## moves you on rough ground; softlock rule §2.16).
static func extra_decel(rule: Dictionary, speed: float) -> float:
	if rule.is_empty():
		return 0.0
	var d: float = float(rule.get("drag_v2", 0.0)) * speed * speed + float(rule.get("rolling", 0.0))
	var floor_speed: float = float(rule.get("min_speed", 4.0))
	if speed <= floor_speed:
		return 0.0
	return d


func _physics_process(dt: float) -> void:
	if skater == null or course == null:
		return
	var grounded: bool = skater.is_on_floor() and skater.state == Skater.State.GROUNDED
	var key: String = ""
	if grounded:
		key = CourseTerrain.Surface.keys()[course.surface_at(skater.global_position)].to_lower()
	var label: String = slow_label(key) if grounded else _current
	if skater.state == Skater.State.CRASHED:
		label = ""
	if label != _current:
		_current = label
		slow_ground_changed.emit(label)
	var moving: bool = skater.velocity.length() > 3.0
	_dust.emitting = grounded and label != "" and moving
	if _dust.emitting:
		_dust.global_position = skater.global_position + Vector3(0, 0.1, 0)
		_dust_mat.albedo_color = Color(0.45, 0.36, 0.22) if key == "grass" else Color(0.62, 0.58, 0.52)
	if not grounded:
		return
	var rule: Dictionary = _rules.get(key, {})
	var v: float = skater.velocity.length()
	var dec: float = extra_decel(rule, v)
	if dec <= 0.0 or v < 0.01:
		return
	var nv: float = maxf(v - dec * dt, float(rule.get("min_speed", 4.0)))
	skater.velocity *= nv / v
