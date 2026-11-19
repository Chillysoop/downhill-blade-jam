class_name ChaseCamera
extends Camera3D
## Third-person chase camera that trails the skater's direction of travel,
## aims down the slope ahead and widens its field of view with speed.
##
## Implements brief MVP feature 6 per
## design/quick-specs/camera-view-height-tweak-2026-11-04.md: the aim point
## drops (and the camera rises) with the smoothed ground grade, held while
## airborne or crashed, and terrain between the skater and the camera pulls
## the camera in so it never sits inside a wall.

## The skater to follow.
@export var target: Skater
## Camera tuning data. A default CameraTuning is used if none is assigned.
@export var tuning: CameraTuning

var _dir: Vector3 = Vector3.FORWARD
## Smoothed ground grade along _dir (rise over run, negative is downhill).
var _grade: float = 0.0


func _ready() -> void:
	# Driven every rendered frame from the skater's interpolated transform.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if tuning == null:
		tuning = CameraTuning.new()


## Jumps straight to the follow position (after a respawn or restart),
## re-reading the slope from the skater's current ground normal.
func snap() -> void:
	if target == null:
		return
	var tp: Vector3 = target.global_position
	_dir = target.heading * Vector3(1, 0, 1)
	_dir = _dir.normalized() if _dir.length() > 0.01 else Vector3.FORWARD
	_grade = _ground_grade()
	global_position = _clear_of_terrain(tp, _desired_position(tp))
	reset_physics_interpolation()
	look_at(_aim_point(tp), Vector3.UP)


func _process(dt: float) -> void:
	if target == null:
		return
	var t: CameraTuning = tuning
	var tp: Vector3 = target.get_global_transform_interpolated().origin
	var v: Vector3 = target.velocity * Vector3(1, 0, 1)
	var want: Vector3 = v.normalized() if v.length() > t.min_travel_speed else (target.heading * Vector3(1, 0, 1)).normalized()
	if target.state != Skater.State.CRASHED and want.length() > 0.01:
		_dir = _dir.slerp(want, 1.0 - exp(-t.turn_sharpness * dt)).normalized()
	# Grade is held while airborne or crashed so jumps do not swing the view.
	if target.state == Skater.State.GROUNDED:
		_grade = lerpf(_grade, _ground_grade(), 1.0 - exp(-t.slope_sharpness * dt))
	# Ease toward the follow position, then pull in at once if terrain blocks
	# it; the next frame eases back out from there.
	var eased: Vector3 = global_position.lerp(_desired_position(tp), 1.0 - exp(-t.follow_sharpness * dt))
	global_position = _clear_of_terrain(tp, eased)
	look_at(_aim_point(tp), Vector3.UP)
	var k: float = clampf(target.get_speed() / t.fov_speed_ref, 0.0, 1.0)
	fov = lerpf(fov, lerpf(t.fov_slow, t.fov_fast, k), 1.0 - exp(-t.fov_sharpness * dt))


## Ground grade along _dir from the skater's ground normal, clamped.
func _ground_grade() -> float:
	var n: Vector3 = target.ground_normal
	return clampf(-n.dot(_dir) / maxf(n.y, 0.2), tuning.grade_min, tuning.grade_max)


func _desired_position(tp: Vector3) -> Vector3:
	var t: CameraTuning = tuning
	return tp - _dir * t.distance + Vector3.UP * (t.height - _grade * t.distance * t.slope_follow)


func _aim_point(tp: Vector3) -> Vector3:
	var t: CameraTuning = tuning
	return tp + _dir * t.look_ahead + Vector3.UP * (t.aim_height + _grade * t.look_ahead * t.slope_follow)


## Casts from 1 m above the skater to [param pos]; if world geometry is in
## the way, returns the point clearance metres short of the hit.
func _clear_of_terrain(tp: Vector3, pos: Vector3) -> Vector3:
	var from: Vector3 = tp + Vector3.UP
	var query := PhysicsRayQueryParameters3D.create(from, pos, tuning.collision_mask, [target.get_rid()])
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return pos
	var hit_pos: Vector3 = hit["position"]
	var span: float = from.distance_to(hit_pos)
	return from + (pos - from).normalized() * maxf(span - tuning.clearance, 0.0)
