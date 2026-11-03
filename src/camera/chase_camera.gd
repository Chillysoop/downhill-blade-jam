class_name ChaseCamera
extends Camera3D
## Third-person chase camera that trails the skater's direction of travel,
## looks ahead down the slope and widens its field of view with speed.

## The skater to follow.
@export var target: Skater
@export var distance: float = 5.5
@export var height: float = 2.4
@export var look_ahead: float = 6.0
@export var follow_sharpness: float = 7.0
@export var turn_sharpness: float = 4.0
@export var fov_slow: float = 70.0
@export var fov_fast: float = 92.0
@export var fov_speed_ref: float = 35.0

var _dir: Vector3 = Vector3.FORWARD


func _ready() -> void:
	# Driven every rendered frame from the skater's interpolated transform.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


## Jumps straight to the follow position (after a respawn).
func snap() -> void:
	if target == null:
		return
	_dir = target.heading * Vector3(1, 0, 1)
	_dir = _dir.normalized() if _dir.length() > 0.01 else Vector3.FORWARD
	global_position = _desired_position(target.global_position)
	reset_physics_interpolation()
	look_at(target.global_position + _dir * look_ahead + Vector3.UP, Vector3.UP)


func _process(dt: float) -> void:
	if target == null:
		return
	var tp: Vector3 = target.get_global_transform_interpolated().origin
	var v: Vector3 = target.velocity * Vector3(1, 0, 1)
	var want: Vector3 = v.normalized() if v.length() > 2.0 else (target.heading * Vector3(1, 0, 1)).normalized()
	if target.state != Skater.State.CRASHED and want.length() > 0.01:
		_dir = _dir.slerp(want, 1.0 - exp(-turn_sharpness * dt)).normalized()
	global_position = global_position.lerp(_desired_position(tp), 1.0 - exp(-follow_sharpness * dt))
	look_at(tp + _dir * look_ahead + Vector3.UP * 0.8, Vector3.UP)
	var k: float = clampf(target.get_speed() / fov_speed_ref, 0.0, 1.0)
	fov = lerpf(fov, lerpf(fov_slow, fov_fast, k), 1.0 - exp(-3.0 * dt))


func _desired_position(tp: Vector3) -> Vector3:
	return tp - _dir * distance + Vector3.UP * height
