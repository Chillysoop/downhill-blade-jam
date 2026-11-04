class_name SurfaceDrag
extends Node
## Off-piste slowdown: while the skater rolls on grass or gravel, adds extra
## drag on top of the skater's own physics, so concrete is fast and the rough
## is slow (design/levels/copperline-mountain.md §2.1 surface rule, §2.15).
## Lives on the course side so the skater controller stays untouched; the
## physics owner can fold it into a per-surface lookup later.

## The skater being slowed.
var skater: Skater
## The course that knows which surface is where.
var course: CourseBuilder

var _rules: Dictionary = {}


func _ready() -> void:
	# Run after the skater has moved this frame.
	process_physics_priority = 10
	_rules = course.surface_rules


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
	if skater == null or course == null or not skater.is_on_floor():
		return
	if skater.state != Skater.State.GROUNDED:
		return
	var s: int = course.surface_at(skater.global_position)
	var key: String = CourseTerrain.Surface.keys()[s].to_lower()
	var rule: Dictionary = _rules.get(key, {})
	var v: float = skater.velocity.length()
	var dec: float = extra_decel(rule, v)
	if dec <= 0.0 or v < 0.01:
		return
	var nv: float = maxf(v - dec * dt, float(rule.get("min_speed", 4.0)))
	skater.velocity *= nv / v
