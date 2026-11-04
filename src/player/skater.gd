class_name Skater
extends CharacterBody3D
## The player: an inline skater driven by momentum and gravity.
##
## Controls (see InputSetup): steer (lean onto the edges and carve), forward
## (stride when slow, tuck when fast), brake (a T-stop when slow; when fast
## the crosswise skate goes in front and bites harder), jump (hold to charge, release to pop). Movement rules live in
## SkateMath; every number lives in [member tuning]. Implements
## design/game-brief.md "Core Mechanics" with real inline skating physics.

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
## True after a respawn until the player presses something: the skater holds
## still at the start so a run only begins when the player begins it.
var waiting_for_start: bool = false
## While waiting at the start, also wait for every control to be let go first
## (set after a menu choice so the Enter/Space/A press is not read as riding).
var hold_until_released: bool = false

var state: State = State.AIR
## Facing direction, kept tangent to the ground while grounded.
var heading: Vector3 = Vector3.FORWARD
var ground_normal: Vector3 = Vector3.UP
var tucking: bool = false
## How far into a tuck the body is, 0 (upright) to 1 (full tuck). Drag and
## the lean available follow this, so standing up takes time.
var tuck_amount: float = 0.0
## Share of the wheels' grip the current carve uses; 1 or more is sliding.
var grip_usage: float = 0.0
## Sideways slide speed of the skates (m/s); above slip_threshold they wash.
var slip_speed: float = 0.0
## True while holding forward at low speed: pushing stroke after stroke.
var striding: bool = false
## True while braking hard at speed: the front skate crosswise ahead of the
## other one (the T-stop reversed), with the weight back.
var sliding: bool = false
## True while braking: the T-stop, trailing skate dragged crosswise behind.
var t_stopping: bool = false
## Body lean onto the edges in radians, positive = leaning right.
var lean: float = 0.0
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
var _stride_phase: float = 0.0
var _stride_leg: int = 0
var _turn_rate: float = 0.0
var _stomp: float = 0.0
var _slide_vis: float = 0.0
var _wobble_t: float = 0.0

var _visual: Node3D
var _body_pivot: Node3D
var _feet: Array[Node3D] = []
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
	var audio := SkateAudio.new()
	audio.name = "SkateAudio"
	audio.skater = self
	add_child(audio)
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
	lean = 0.0
	striding = false
	sliding = false
	t_stopping = false
	tuck_amount = 0.0
	grip_usage = 0.0
	slip_speed = 0.0
	_stride_phase = 0.0
	_stomp = 0.0
	auto_brake = false
	waiting_for_start = true
	crash_reason = ""
	_visual.rotation = Vector3.ZERO
	respawned.emit()


## Current speed in m/s.
func get_speed() -> float:
	return velocity.length()


func _physics_process(dt: float) -> void:
	var inp: Dictionary = _read_input()
	if waiting_for_start:
		var any_input: bool = absf(float(inp["steer"])) > 0.1 or float(inp["forward"]) > 0.1 \
			or float(inp["brake"]) > 0.1 or bool(inp["jump"])
		if hold_until_released:
			# Keys still down from a menu press must not drop the skater in.
			if not any_input:
				hold_until_released = false
			velocity = Vector3.ZERO
			return
		if not any_input:
			velocity = Vector3.ZERO
			return
		waiting_for_start = false
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
	var brake_in: float = inp["brake"]
	var braking: bool = brake_in > 0.05
	tucking = fwd_in > 0.1 and speed > t.tuck_speed and not braking
	tuck_amount = SkateMath.step_tuck(t, tuck_amount, tucking, dt)
	striding = fwd_in > 0.1 and not tucking and not braking and tuck_amount < 0.3
	# Hard T-stop above hard_brake_speed; keep sliding down to half of it so it
	# doesn't flicker between brakes.
	if not braking:
		sliding = false
	elif speed > t.hard_brake_speed:
		sliding = true
	elif speed < t.hard_brake_speed * 0.5:
		sliding = false

	# Lean onto the edges; the lean and the speed decide the carve.
	t_stopping = braking and speed > 0.3
	var steer: float = float(inp["steer"]) * (t.hard_brake_steer_mult if sliding else 1.0)
	lean = SkateMath.step_lean(t, lean, steer, tuck_amount, dt)
	_turn_rate = SkateMath.carve_turn_rate(t, speed, lean)
	heading = heading.rotated(n, -_turn_rate * dt).normalized()

	# Gravity pulls along the slope; the surface cancels the rest.
	velocity += SkateMath.project_on_plane(Vector3.DOWN * t.gravity, n) * dt
	velocity = SkateMath.project_on_plane(velocity, n)

	# Wheels roll along the skates and resist sliding sideways.
	var right: Vector3 = heading.cross(n).normalized()
	var v_f: float = velocity.dot(heading)
	var v_l: float = SkateMath.apply_side_friction(t, velocity.dot(right), speed, dt)
	slip_speed = absf(v_l)
	grip_usage = SkateMath.grip_usage(t, speed, _turn_rate, v_l)
	v_f = SkateMath.apply_carve_scrub(t, v_f, speed, _turn_rate, dt)

	if striding:
		v_f += SkateMath.stride_accel(t, maxf(v_f, 0.0), _stride_phase) * fwd_in * dt
		_stride_phase += dt / t.stride_period
		if _stride_phase >= 1.0:
			_stride_phase -= 1.0
			_stride_leg = 1 - _stride_leg
	else:
		_stride_phase = 0.0
	if braking:
		var decel: float = t.auto_brake_decel if auto_brake else SkateMath.brake_decel(t, speed, sliding)
		v_f = move_toward(v_f, 0.0, decel * brake_in * dt)
	v_f = SkateMath.apply_resistance(t, v_f, SkateMath.drag_for(t, tuck_amount), dt)

	velocity = heading * v_f + right * v_l


func _air_step(dt: float, inp: Dictionary) -> void:
	var t: SkaterTuning = tuning
	tucking = false
	tuck_amount = SkateMath.step_tuck(t, tuck_amount, false, dt)
	striding = false
	sliding = false
	t_stopping = false
	grip_usage = 0.0
	slip_speed = 0.0
	_turn_rate = 0.0
	lean = move_toward(lean, 0.0, deg_to_rad(t.lean_rate_deg) * dt)
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
	# A seam or box corner can report a floor normal far steeper than the
	# ground either side of it; steering the speed along it flings the skater.
	if SkateMath.is_seam_normal(tuning, ground_normal, get_floor_normal()):
		velocity = before_move
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
			# Clean landing: the knees soak up the impact and the rolling speed
			# carries on. Feet straighten out small misalignments on touchdown;
			# skates that land more crooked keep pointing where they point, and
			# wheel grip scrubs off the sideways part.
			velocity = SkateMath.landing_velocity(tuning, pre_vel, n)
			heading = SkateMath.landing_heading(tuning, heading, velocity, n)
			var impact: float = float(verdict["impact"])
			_stomp = clampf((impact - tuning.landing_soft_impact)
				/ maxf(tuning.crash_land_impact - tuning.landing_soft_impact, 0.01), 0.0, 1.0)
			landed.emit(air_time)
		if state == State.GROUNDED and SkateMath.is_seam_normal(tuning, ground_normal, n):
			n = ground_normal
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


func _update_visual(dt: float, _inp: Dictionary) -> void:
	var up: Vector3 = ground_normal if state == State.GROUNDED else Vector3.UP
	var fwd: Vector3 = SkateMath.project_on_plane(heading, up)
	if fwd.length() < 0.01:
		return
	var target := Basis.looking_at(fwd.normalized(), up)
	# Lean into the carve by the angle the turn really needs: atan(lateral g).
	var a_lat: float = velocity.length() * _turn_rate
	var body_lean: float = atan(a_lat / tuning.gravity) if state == State.GROUNDED else lean
	_steer_smoothed = lerpf(_steer_smoothed, body_lean, 1.0 - exp(-12.0 * dt))
	target = target * Basis(Vector3.FORWARD, _steer_smoothed)
	# Braking never turns the body (Conner, 2026-11-04): it keeps facing down
	# the hill and only one skate turns crosswise, behind when slow, in front
	# when fast. Sink lower when it bites
	# harder at speed.
	_slide_vis = lerpf(_slide_vis, 1.0 if sliding else 0.0, 1.0 - exp(-10.0 * dt))
	var cur: Quaternion = _visual.global_basis.get_rotation_quaternion()
	var q: Quaternion = cur.slerp(target.get_rotation_quaternion(), 1.0 - exp(-14.0 * dt))
	_visual.global_basis = Basis(q)
	# Crouch while charging a jump, fold forward while tucking, sink on a
	# stomped landing.
	_stomp = move_toward(_stomp, 0.0, 2.5 * dt)
	var crouch: float = maxf(maxf(jump_charge * 0.35, 0.3 * tuck_amount), _stomp * 0.4)
	crouch = maxf(crouch, 0.15 * _slide_vis)
	_body_pivot.scale.y = lerpf(_body_pivot.scale.y, 1.0 - crouch, 1.0 - exp(-12.0 * dt))
	var pitch: float = -0.5 * tuck_amount if tuck_amount > 0.05 else (-0.25 if striding else (0.2 if t_stopping and sliding else (-0.15 if t_stopping else 0.0)))
	_body_pivot.rotation.x = lerpf(_body_pivot.rotation.x, pitch, 1.0 - exp(-10.0 * dt))
	# Grip running out: the stance gets twitchy so you can see it coming.
	var edge: float = SkateAudio.edge_level(grip_usage)
	_wobble_t += dt
	_body_pivot.rotation.z = (sin(_wobble_t * 38.0) * 0.05 + sin(_wobble_t * 23.0) * 0.03) * edge
	_animate_stride(dt)


## Strides: the pushing skate sweeps out to the side and back, then returns
## while the other one glides, and the body shifts over the gliding skate.
func _animate_stride(dt: float) -> void:
	var share: float = tuning.stride_push_share
	var push: float = 0.0
	if striding:
		var p: float = _stride_phase
		push = sin(PI * p / share) if p < share else 0.0
	var k: float = 1.0 - exp(-18.0 * dt)
	for i: int in _feet.size():
		var foot: Node3D = _feet[i]
		var side: float = -1.0 if i == 0 else 1.0
		var amount: float = push if i == _stride_leg else 0.0
		var target := Vector3(side * (0.14 + 0.32 * amount), 0.06 * amount, 0.28 * amount)
		var yaw: float = -side * 0.5 * amount
		if t_stopping and sliding:
			# Hard brake at speed: the opposite of the T-stop. The right skate
			# goes out in front turned crosswise and the left one rolls behind
			# it, with the weight sitting back.
			target = Vector3(0.05, 0.0, 0.1) if i == 0 else Vector3(0.02, 0.0, -0.34)
			yaw = 0.0 if i == 0 else PI / 2.0
		elif t_stopping:
			# T-stop: left skate rolls forward, right skate trails behind it
			# turned crosswise, dragging its wheels.
			target = Vector3(-0.05, 0.0, -0.1) if i == 0 else Vector3(-0.02, 0.0, 0.34)
			yaw = 0.0 if i == 0 else PI / 2.0
		foot.position = foot.position.lerp(target, k)
		foot.rotation.y = lerpf(foot.rotation.y, yaw, k)
	var glide_side: float = 1.0 if _stride_leg == 0 else -1.0
	var sway: float = glide_side * 0.1 * push
	if t_stopping:
		sway = -0.06
	_body_pivot.position.x = lerpf(_body_pivot.position.x, sway, k)


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
		var foot := Node3D.new()
		foot.position = Vector3(side, 0, 0)
		_visual.add_child(foot)
		_feet.append(foot)
		var leg := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.14, 0.3, 0.14)
		leg.mesh = lm
		leg.material_override = dark
		leg.position = Vector3(0, 0.12, 0)
		foot.add_child(leg)
		var skate := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.12, 0.1, 0.42)
		skate.mesh = sm
		skate.material_override = dark
		skate.position = Vector3(0, 0.05, 0)
		foot.add_child(skate)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	return m
