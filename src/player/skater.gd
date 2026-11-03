class_name Skater
extends CharacterBody3D
## The player: an inline skater driven by momentum and gravity.
##
## Controls (see InputSetup): steer, forward (push when slow, tuck when fast),
## brake, jump (hold to charge, release to pop). Movement rules live in
## SkateMath; every number lives in [member tuning].

## Emitted when the skater bails. [param reason] is shown to the player.
signal crashed(reason: String)
## Emitted after the skater is placed back at a spawn point.
signal respawned
## Emitted on a clean landing after real airtime.
signal landed(air_time: float)

enum State { GROUNDED, AIR, CRASHED }

## Movement tuning data.
@export var tuning: SkaterTuning
## Falling below this height counts as falling off the course.
@export var kill_height: float = -200.0

## Optional input source for bots and tests. Must return a Dictionary with
## steer, forward, brake (floats) and jump (bool).
var input_override: Callable
## When true the skater ignores input and brakes to a stop (after the finish).
var auto_brake: bool = false

var state: State = State.AIR
## Facing direction, kept tangent to the ground while grounded.
var heading: Vector3 = Vector3.FORWARD
var ground_normal: Vector3 = Vector3.UP
var tucking: bool = false
var jump_charge: float = 0.0
var air_time: float = 0.0
var crash_reason: String = ""

var _charging: bool = false
var _since_ground: float = 0.0
var _last_ground_normal: Vector3 = Vector3.UP
var _snap_block: float = 0.0
var _crash_timer: float = 0.0
var _spawn: Transform3D = Transform3D.IDENTITY
var _steer_smoothed: float = 0.0
var _hop_buffer: float = 0.0
var _buffered_charge: float = 0.0

var _visual: Node3D
var _body_pivot: Node3D
var _base_snap: float = 0.45


func _ready() -> void:
	if tuning == null:
		tuning = load("res://assets/data/skater_tuning.tres") as SkaterTuning
	floor_max_angle = deg_to_rad(55.0)
	floor_snap_length = _base_snap
	floor_constant_speed = false
	floor_stop_on_slope = false
	floor_block_on_wall = false
	slide_on_ceiling = false
	max_slides = 6
	_build_body()
	_spawn = global_transform


## Sets the point the skater respawns at, facing [param facing].
func set_spawn(xform: Transform3D, facing: Vector3) -> void:
	_spawn = xform
	_spawn.basis = Basis.looking_at(facing.normalized(), Vector3.UP)


## Puts the skater back at its spawn point, stopped.
func respawn() -> void:
	global_transform = Transform3D(Basis.IDENTITY, _spawn.origin)
	reset_physics_interpolation()
	velocity = Vector3.ZERO
	heading = -_spawn.basis.z
	ground_normal = Vector3.UP
	state = State.AIR
	jump_charge = 0.0
	_charging = false
	_hop_buffer = 0.0
	auto_brake = false
	crash_reason = ""
	_visual.rotation = Vector3.ZERO
	respawned.emit()


## Current speed in m/s.
func get_speed() -> float:
	return velocity.length()


func _physics_process(dt: float) -> void:
	var inp: Dictionary = _read_input()
	if state == State.CRASHED:
		_crash_step(dt)
		return
	var pre_vel: Vector3 = velocity
	_snap_block = maxf(_snap_block - dt, 0.0)
	floor_snap_length = 0.0 if _snap_block > 0.0 else _base_snap

	_update_jump(inp, dt)
	if state == State.GROUNDED:
		_ground_step(dt, inp)
	else:
		_air_step(dt, inp)
	var before_move: Vector3 = velocity
	move_and_slide()
	_restore_slope_velocity(before_move)
	_after_move(pre_vel, dt)
	if state != State.CRASHED:
		_update_visual(dt, inp)
	if global_position.y < kill_height and state != State.CRASHED:
		_crash("Fell off the mountain")


func _read_input() -> Dictionary:
	if auto_brake:
		return {"steer": 0.0, "forward": 0.0, "brake": 1.0, "jump": false}
	if input_override.is_valid():
		return input_override.call()
	return {
		"steer": Input.get_axis("steer_left", "steer_right"),
		"forward": Input.get_action_strength("forward"),
		"brake": Input.get_action_strength("brake"),
		"jump": Input.is_action_pressed("jump"),
	}


func _update_jump(inp: Dictionary, dt: float) -> void:
	var held: bool = inp["jump"]
	var can_pop: bool = state == State.GROUNDED or _since_ground < tuning.coyote_time
	if held:
		_charging = true
		jump_charge = minf(jump_charge + dt / tuning.charge_time, 1.0)
	elif _charging:
		_charging = false
		if can_pop:
			var n: Vector3 = ground_normal if state == State.GROUNDED else _last_ground_normal
			_pop(n, jump_charge)
		else:
			# Released mid-air: remember it and pop the moment we land.
			_hop_buffer = tuning.hop_buffer_time
			_buffered_charge = jump_charge
		jump_charge = 0.0
	_hop_buffer = maxf(_hop_buffer - dt, 0.0)


func _pop(n: Vector3, charge: float) -> void:
	# Pop along a blend of the surface normal and straight up so jumps on
	# steep slopes still feel like they go up.
	var pop_dir: Vector3 = (n + Vector3.UP).normalized()
	velocity += pop_dir * SkateMath.pop_speed(tuning, charge)
	state = State.AIR
	air_time = 0.0
	_since_ground = 1.0
	_snap_block = 0.2
	_hop_buffer = 0.0


func _ground_step(dt: float, inp: Dictionary) -> void:
	var t: SkaterTuning = tuning
	var n: Vector3 = ground_normal
	var h: Vector3 = SkateMath.project_on_plane(heading, n)
	if h.length() < 0.01:
		h = SkateMath.project_on_plane(-global_basis.z, n)
	heading = h.normalized()

	var speed: float = velocity.length()
	var fwd_in: float = inp["forward"]
	tucking = fwd_in > 0.1 and speed > t.push_max_speed
	var rate: float = SkateMath.turn_rate(t, speed, tucking)
	heading = heading.rotated(n, -float(inp["steer"]) * rate * dt).normalized()

	# Gravity pulls along the slope; the surface cancels the rest.
	velocity += SkateMath.project_on_plane(Vector3.DOWN * t.gravity, n) * dt
	velocity = SkateMath.project_on_plane(velocity, n)

	var right: Vector3 = heading.cross(n).normalized()
	var v_f: float = velocity.dot(heading)
	var v_l: float = velocity.dot(right)
	var gripped: Vector2 = SkateMath.apply_grip(t, v_f, v_l, dt)
	v_f = gripped.x
	v_l = gripped.y

	if fwd_in > 0.1 and v_f < t.push_max_speed:
		v_f += t.push_accel * fwd_in * dt
	var brake_in: float = inp["brake"]
	if brake_in > 0.05:
		v_f = move_toward(v_f, 0.0, t.brake_decel * brake_in * dt)
	v_f = SkateMath.apply_resistance(t, v_f, t.drag_tuck if tucking else t.drag, dt)

	velocity = heading * v_f + right * v_l


func _air_step(dt: float, inp: Dictionary) -> void:
	var t: SkaterTuning = tuning
	tucking = false
	velocity += Vector3.DOWN * t.gravity * dt
	var sp: float = velocity.length()
	if sp > 0.01:
		velocity -= velocity / sp * minf(t.air_drag * sp * sp * dt, sp)
	var flat: Vector3 = Vector3(heading.x, 0.0, heading.z)
	if flat.length() < 0.01:
		flat = Vector3(velocity.x, 0.0, velocity.z)
	if flat.length() > 0.01:
		heading = flat.normalized().rotated(Vector3.UP, -float(inp["steer"]) * t.air_spin_rate * dt)


## move_and_slide() strips the downhill (vertical) part of velocity while on
## the floor, which would bleed speed every frame. Put it back by carrying the
## pre-move velocity along the new floor, unless we hit a wall this step.
func _restore_slope_velocity(before_move: Vector3) -> void:
	if not is_on_floor() or state != State.GROUNDED:
		return
	for i: int in get_slide_collision_count():
		if get_slide_collision(i).get_normal().angle_to(Vector3.UP) > floor_max_angle + 0.02:
			velocity = get_real_velocity()
			return
	var along: Vector3 = SkateMath.project_on_plane(before_move, get_floor_normal())
	if along.length() > 0.001:
		velocity = along.normalized() * before_move.length()


func _after_move(pre_vel: Vector3, dt: float) -> void:
	# Walls and obstacles: bail if hit hard enough.
	for i: int in get_slide_collision_count():
		var c: KinematicCollision3D = get_slide_collision(i)
		var cn: Vector3 = c.get_normal()
		if cn.angle_to(Vector3.UP) > floor_max_angle + 0.02:
			var impact: float = -pre_vel.dot(cn)
			if impact > tuning.crash_wall_speed:
				_crash("Hit an obstacle")
				return

	if is_on_floor():
		var n: Vector3 = get_floor_normal()
		if state == State.AIR and air_time > 0.12:
			var verdict: Dictionary = SkateMath.judge_landing(tuning, heading, pre_vel, n)
			if not verdict["ok"]:
				_crash(verdict["reason"])
				return
			# Clean landing: keep the speed along the ground, line up with it.
			var tang: Vector3 = SkateMath.project_on_plane(pre_vel, n)
			var keep: float = 1.0 - 0.25 * float(verdict["angle_deg"]) / tuning.crash_land_angle_deg
			velocity = tang * keep
			if tang.length() > 1.0:
				heading = tang.normalized()
			landed.emit(air_time)
		ground_normal = n
		_last_ground_normal = n
		state = State.GROUNDED
		air_time = 0.0
		_since_ground = 0.0
		if _hop_buffer > 0.0:
			_pop(n, _buffered_charge)
	else:
		if state == State.GROUNDED:
			state = State.AIR
		air_time += dt
		_since_ground += dt


func _crash(reason: String) -> void:
	state = State.CRASHED
	crash_reason = reason
	_crash_timer = tuning.respawn_delay
	_charging = false
	jump_charge = 0.0
	velocity *= 0.5
	crashed.emit(reason)


func _crash_step(dt: float) -> void:
	velocity += Vector3.DOWN * tuning.gravity * dt
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	flat = flat.move_toward(Vector3.ZERO, tuning.crash_friction * dt)
	velocity = Vector3(flat.x, velocity.y, flat.z)
	floor_snap_length = 0.0
	move_and_slide()
	# Tumble the body.
	_visual.rotate_object_local(Vector3.RIGHT, 9.0 * dt)
	_visual.rotate_object_local(Vector3.FORWARD, 4.0 * dt)
	_crash_timer -= dt
	if _crash_timer <= 0.0:
		respawn()


func _update_visual(dt: float, inp: Dictionary) -> void:
	var up: Vector3 = ground_normal if state == State.GROUNDED else Vector3.UP
	var fwd: Vector3 = SkateMath.project_on_plane(heading, up)
	if fwd.length() < 0.01:
		return
	var target := Basis.looking_at(fwd.normalized(), up)
	_steer_smoothed = lerpf(_steer_smoothed, float(inp["steer"]), 1.0 - exp(-8.0 * dt))
	var speed_k: float = clampf(velocity.length() / 15.0, 0.0, 1.0)
	var lean: float = -_steer_smoothed * speed_k * 0.45
	target = target * Basis(Vector3.FORWARD, -lean)
	var cur: Quaternion = _visual.global_basis.get_rotation_quaternion()
	var q: Quaternion = cur.slerp(target.get_rotation_quaternion(), 1.0 - exp(-14.0 * dt))
	_visual.global_basis = Basis(q)
	# Crouch while charging a jump, fold forward while tucking.
	var crouch: float = maxf(jump_charge * 0.35, 0.3 if tucking else 0.0)
	_body_pivot.scale.y = lerpf(_body_pivot.scale.y, 1.0 - crouch, 1.0 - exp(-12.0 * dt))
	var pitch: float = -0.5 if tucking else 0.0
	_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, pitch, 1.0 - exp(-10.0 * dt))


func _build_body() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.7
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, 0.85, 0)
	add_child(col)

	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_body_pivot = Node3D.new()
	_body_pivot.position = Vector3(0, 0.25, 0)
	_visual.add_child(_body_pivot)

	var suit := _mat(Color(0.95, 0.45, 0.1))
	var dark := _mat(Color(0.12, 0.12, 0.15))
	var skin := _mat(Color(0.9, 0.75, 0.6))

	var torso := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.28
	cap.height = 1.2
	torso.mesh = cap
	torso.material_override = suit
	torso.position = Vector3(0, 0.75, 0)
	_body_pivot.add_child(torso)

	var head := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.17
	sph.height = 0.34
	head.mesh = sph
	head.material_override = skin
	head.position = Vector3(0, 1.5, -0.05)
	_body_pivot.add_child(head)

	var helmet := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.2
	hs.height = 0.24
	hs.is_hemisphere = true
	helmet.mesh = hs
	helmet.material_override = dark
	helmet.position = Vector3(0, 1.56, -0.04)
	_body_pivot.add_child(helmet)

	for side: float in [-0.14, 0.14]:
		var leg := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.14, 0.3, 0.14)
		leg.mesh = lm
		leg.material_override = dark
		leg.position = Vector3(side, 0.12, 0)
		_visual.add_child(leg)
		var skate := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.12, 0.1, 0.42)
		skate.mesh = sm
		skate.material_override = dark
		skate.position = Vector3(side, 0.05, 0)
		_visual.add_child(skate)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	return m
