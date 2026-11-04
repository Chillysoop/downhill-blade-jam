class_name SkateMath
extends RefCounted
## Pure functions for the skater's movement rules, kept free of nodes so they
## can be unit tested. Implements design/game-brief.md "Core Mechanics",
## grounded in real inline skating physics.


## Removes the part of [param v] that points along [param n] (n must be unit length).
static func project_on_plane(v: Vector3, n: Vector3) -> Vector3:
	return v - n * v.dot(n)


## Moves the tuck amount (0 = upright, 1 = full tuck) toward [param want].
## Standing up takes tuck_out_time, folding down takes tuck_in_time.
static func step_tuck(t: SkaterTuning, amount: float, want: bool, dt: float) -> float:
	var secs: float = t.tuck_in_time if want else t.tuck_out_time
	return clampf(move_toward(amount, 1.0 if want else 0.0, dt / maxf(secs, 0.001)), 0.0, 1.0)


## Air drag for a body [param tuck_amount] of the way into a tuck.
static func drag_for(t: SkaterTuning, tuck_amount: float) -> float:
	return lerpf(t.drag, t.drag_tuck, clampf(tuck_amount, 0.0, 1.0))


## Steepest lean (radians) available [param tuck_amount] of the way into a
## tuck: a tuck only allows a shallow lean.
static func lean_limit(t: SkaterTuning, tuck_amount: float) -> float:
	return deg_to_rad(lerpf(t.lean_max_deg, t.lean_max_tuck_deg, clampf(tuck_amount, 0.0, 1.0)))


## Moves the body's lean angle (radians, positive = leaning right) toward the
## lean that [param steer] (-1..1) asks for, at the tuning's lean rate.
static func step_lean(t: SkaterTuning, lean: float, steer: float, tuck_amount: float, dt: float) -> float:
	var limit: float = lean_limit(t, tuck_amount)
	var target: float = clampf(steer, -1.0, 1.0) * limit
	return clampf(move_toward(lean, target, deg_to_rad(t.lean_rate_deg) * dt), -limit, limit)


## Sideways grip coefficient at [param speed]: full grip when slow, fading
## by grip_fade between grip_fade_start and grip_fade_end.
static func side_grip_at(t: SkaterTuning, speed: float) -> float:
	var k: float = clampf((absf(speed) - t.grip_fade_start) / maxf(t.grip_fade_end - t.grip_fade_start, 0.001), 0.0, 1.0)
	return t.side_grip * (1.0 - t.grip_fade * k)


## How much of the wheels' grip a carve is using: 1 or more means the skates
## are (or are about to start) sliding. Sliding sideways faster than
## slip_threshold always counts as grip gone.
static func grip_usage(t: SkaterTuning, speed: float, turn_rate: float, v_lateral: float) -> float:
	var usage: float = absf(speed * turn_rate) / (side_grip_at(t, speed) * t.gravity)
	if absf(v_lateral) > t.slip_threshold:
		usage = maxf(usage, 1.0)
	return usage


## Turn rate (rad/s, positive = turning right) of a balanced carve at
## [param lean] radians. Lateral acceleration is g * tan(lean), so the radius
## is v² / (g tan lean): the faster you go the wider the arc. At low speed the
## frame's tightest circle caps the turn, and when nearly stopped you can
## still step the skates around.
static func carve_turn_rate(t: SkaterTuning, speed: float, lean: float) -> float:
	if lean == 0.0:
		return 0.0
	var a_lat: float = t.gravity * tan(absf(lean))
	var physics_rate: float = a_lat / maxf(speed, 0.001)
	var cap: float = maxf(speed / t.min_turn_radius, t.pivot_turn_rate)
	return signf(lean) * minf(physics_rate, cap)


## Wheel side friction: sideways sliding (m/s, relative to the skates) is
## stopped by up to grip * g of friction (grip from side_grip_at). Speed lost
## here is gone, it is never turned into forward speed. A carve that asks for
## more than this makes the skates slide: they wash wide.
static func apply_side_friction(t: SkaterTuning, v_lateral: float, speed: float, dt: float) -> float:
	return move_toward(v_lateral, 0.0, side_grip_at(t, speed) * t.gravity * dt)


## Speed lost to wheel scrub while turning at [param turn_rate] rad/s at
## [param speed] m/s. Proportional to the turn's lateral g.
static func apply_carve_scrub(t: SkaterTuning, v_forward: float, speed: float, turn_rate: float, dt: float) -> float:
	var a_lat: float = absf(speed * turn_rate)
	return move_toward(v_forward, 0.0, t.carve_scrub * a_lat * dt)


## Forward acceleration (m/s²) from striding at [param speed], at
## [param phase] (0..1) through one push stroke. Each stroke pushes in a
## smooth pulse then glides, and pushes weaken toward stride_max_speed because
## the foot can't push faster than the ground moves under it.
static func stride_accel(t: SkaterTuning, speed: float, phase: float) -> float:
	if phase < 0.0 or phase >= t.stride_push_share:
		return 0.0
	var falloff: float = clampf(1.0 - absf(speed) / t.stride_max_speed, 0.0, 1.0)
	return t.stride_peak_accel * sin(PI * phase / t.stride_push_share) * falloff


## Braking deceleration (m/s²) of the T-stop: light when slow, harder when
## [param sliding] (which Skater sets above hard_brake_speed).
static func brake_decel(t: SkaterTuning, _speed: float, sliding: bool) -> float:
	return t.hard_brake_decel if sliding else t.t_stop_decel


## Applies rolling resistance and quadratic drag to a forward speed.
static func apply_resistance(t: SkaterTuning, v_forward: float, drag_coeff: float, dt: float) -> float:
	var v: float = move_toward(v_forward, 0.0, t.rolling_resistance * t.gravity * dt)
	var loss: float = drag_coeff * v * v * dt
	return move_toward(v, 0.0, loss)


## Velocity just after touching down on a surface with normal [param n]: the
## knees absorb the into-ground part, and the wheels biting on impact take a
## share of it out of the rolling speed too.
static func landing_velocity(t: SkaterTuning, velocity: Vector3, n: Vector3) -> Vector3:
	var impact: float = maxf(-velocity.dot(n), 0.0)
	var tang: Vector3 = project_on_plane(velocity, n)
	var sp: float = tang.length()
	if sp < 0.001:
		return Vector3.ZERO
	return tang / sp * maxf(sp - t.landing_friction * impact, 0.0)


## Skate direction just after touching down: within landing_align_deg of the
## travel direction the feet straighten out onto it; further off, the skates
## stay where they point and the wheels scrub off the sideways speed.
static func landing_heading(t: SkaterTuning, heading: Vector3, velocity: Vector3, n: Vector3) -> Vector3:
	var h: Vector3 = project_on_plane(heading, n)
	var v: Vector3 = project_on_plane(velocity, n)
	if v.length() < 1.0 or h.length() < 0.01:
		return heading
	if rad_to_deg(h.angle_to(v)) <= t.landing_align_deg:
		return v.normalized()
	return h.normalized()


## True when a floor normal [param new_n] differs from the ground the
## skater was rolling on ([param old_n]) by more than max_normal_jump_deg in
## one step: a collision seam or box corner, not real ground.
static func is_seam_normal(t: SkaterTuning, old_n: Vector3, new_n: Vector3) -> bool:
	return rad_to_deg(old_n.angle_to(new_n)) > t.max_normal_jump_deg


## Pop speed for a jump charged for [param charge] (0..1).
static func pop_speed(t: SkaterTuning, charge: float) -> float:
	return lerpf(t.pop_min, t.pop_max, clampf(charge, 0.0, 1.0))


## Judges a landing. Returns a Dictionary with:
## "ok" (bool), "reason" (String), "angle_deg" (float), "impact" (float).
static func judge_landing(t: SkaterTuning, heading: Vector3, velocity: Vector3, normal: Vector3) -> Dictionary:
	var impact: float = -velocity.dot(normal)
	var tangential: Vector3 = project_on_plane(velocity, normal)
	var angle_deg: float = 0.0
	if tangential.length() > 2.0:
		var h: Vector3 = project_on_plane(heading, normal)
		if h.length() > 0.01:
			angle_deg = rad_to_deg(h.normalized().angle_to(tangential.normalized()))
	if impact > t.crash_land_impact:
		return {"ok": false, "reason": "Landed too hard", "angle_deg": angle_deg, "impact": impact}
	if angle_deg > t.crash_land_angle_deg:
		return {"ok": false, "reason": "Landed sideways", "angle_deg": angle_deg, "impact": impact}
	return {"ok": true, "reason": "", "angle_deg": angle_deg, "impact": impact}
