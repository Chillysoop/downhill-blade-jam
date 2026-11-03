class_name SkateMath
extends RefCounted
## Pure functions for the skater's movement rules, kept free of nodes so they
## can be unit tested.


## Removes the part of [param v] that points along [param n] (n must be unit length).
static func project_on_plane(v: Vector3, n: Vector3) -> Vector3:
	return v - n * v.dot(n)


## Turn rate in rad/s for the current speed, slowing turns as speed grows.
static func turn_rate(t: SkaterTuning, speed: float, tucking: bool) -> float:
	var k: float = clampf(speed / t.turn_rate_speed_ref, 0.0, 1.0)
	var rate: float = lerpf(t.turn_rate_slow, t.turn_rate_fast, k)
	return rate * (t.tuck_steer_mult if tucking else 1.0)


## Applies wheel grip: sideways speed decays, and a share of what was lost is
## kept as forward speed. Returns Vector2(forward, lateral).
static func apply_grip(t: SkaterTuning, v_forward: float, v_lateral: float, dt: float) -> Vector2:
	var new_lat: float = v_lateral * exp(-t.grip * dt)
	var removed: float = absf(v_lateral) - absf(new_lat)
	var dir: float = 1.0 if v_forward >= 0.0 else -1.0
	return Vector2(v_forward + dir * removed * t.carve_efficiency, new_lat)


## Applies rolling resistance and quadratic drag to a forward speed.
static func apply_resistance(t: SkaterTuning, v_forward: float, drag_coeff: float, dt: float) -> float:
	var v: float = move_toward(v_forward, 0.0, t.rolling_resistance * t.gravity * dt)
	var loss: float = drag_coeff * v * v * dt
	return move_toward(v, 0.0, loss)


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
