extends SceneTree
## Unit tests for SkateMath. Run headless:
##   godot --headless --script res://tests/unit/skater/test_skate_math.gd
## Covers the realism pass rules in design/game-brief.md "Core Mechanics":
## carving, real gravity and drag, strides, braking and landings.

const DT: float = 1.0 / 120.0

var _fails: int = 0


func _init() -> void:
	var t := SkaterTuning.new()
	test_lean_moves_at_lean_rate(t)
	test_tuck_limits_lean(t)
	test_carve_radius_follows_physics(t)
	test_slow_turns_are_capped(t)
	test_carving_never_gains_speed(t)
	test_harder_carves_cost_more(t)
	test_side_friction_never_reverses(t)
	test_strides_fade_with_speed(t)
	test_strides_only_push_in_push_phase(t)
	test_stride_takeoff_is_realistic(t)
	test_braking_distances(t)
	test_tuck_raises_top_speed(t)
	test_landing_downslope_keeps_speed(t)
	test_landing_straightens_small_misalignment(t)
	test_resistance_never_reverses(t)
	test_pop_speed_range(t)
	test_landing_verdicts(t)
	print("SkateMath tests: %s" % ("PASS" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)


func check(cond: bool, name: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: ", name)


func test_lean_moves_at_lean_rate(t: SkaterTuning) -> void:
	var step: float = deg_to_rad(t.lean_rate_deg) * 0.05
	var lean: float = SkateMath.step_lean(t, 0.0, 1.0, false, 0.05)
	check(is_equal_approx(lean, step), "lean rolls in at lean rate")
	for i: int in 200:
		lean = SkateMath.step_lean(t, lean, 1.0, false, DT)
	check(is_equal_approx(lean, deg_to_rad(t.lean_max_deg)), "full steer reaches max lean")
	for i: int in 400:
		lean = SkateMath.step_lean(t, lean, -0.5, false, DT)
	check(is_equal_approx(lean, -0.5 * deg_to_rad(t.lean_max_deg)), "half steer the other way")


func test_tuck_limits_lean(t: SkaterTuning) -> void:
	var lean: float = 0.0
	for i: int in 400:
		lean = SkateMath.step_lean(t, lean, 1.0, true, DT)
	check(is_equal_approx(lean, deg_to_rad(t.lean_max_tuck_deg)), "tuck caps the lean")


func test_carve_radius_follows_physics(t: SkaterTuning) -> void:
	# Balanced carve: radius = v² / (g tan lean).
	var v: float = 20.0
	var lean: float = deg_to_rad(30.0)
	var w: float = SkateMath.carve_turn_rate(t, v, lean)
	var radius: float = v / w
	check(absf(radius - v * v / (t.gravity * tan(lean))) < 0.01, "carve radius = v²/(g tan lean)")
	check(SkateMath.carve_turn_rate(t, v, -lean) < 0.0, "negative lean turns the other way")
	check(SkateMath.carve_turn_rate(t, v, 0.0) == 0.0, "no lean, no turn")
	# Twice the speed, four times the radius: fast turns are wide.
	var w2: float = SkateMath.carve_turn_rate(t, 2.0 * v, lean)
	check(absf((2.0 * v / w2) / radius - 4.0) < 0.01, "radius grows with speed squared")


func test_slow_turns_are_capped(t: SkaterTuning) -> void:
	var lean: float = deg_to_rad(t.lean_max_deg)
	var v: float = 3.0
	var w: float = SkateMath.carve_turn_rate(t, v, lean)
	check(absf(w - v / t.min_turn_radius) < 0.001, "frame limits the tightest turn")
	check(is_equal_approx(SkateMath.carve_turn_rate(t, 0.0, lean), t.pivot_turn_rate), "can step around when stopped")


## Simulates a grounded carve on the flat the way Skater does it: rotate the
## skates, let the wheels' side friction pull the velocity round, pay the scrub.
func _carve(t: SkaterTuning, speed: float, lean: float, seconds: float) -> float:
	var vel := Vector3(0, 0, -speed)
	var heading := Vector3.FORWARD
	for i: int in int(seconds / DT):
		var sp: float = vel.length()
		var w: float = SkateMath.carve_turn_rate(t, sp, lean)
		heading = heading.rotated(Vector3.UP, -w * DT)
		var right: Vector3 = heading.cross(Vector3.UP)
		var vf: float = vel.dot(heading)
		var vl: float = SkateMath.apply_side_friction(t, vel.dot(right), DT)
		vf = SkateMath.apply_carve_scrub(t, vf, sp, w, DT)
		vel = heading * vf + right * vl
	return vel.length()


func test_carving_never_gains_speed(t: SkaterTuning) -> void:
	var end: float = _carve(t, 15.0, deg_to_rad(t.lean_max_deg), 2.0)
	check(end <= 15.0, "carving does not create speed")
	check(end > 13.0, "a clean carve keeps most of its speed")


func test_harder_carves_cost_more(t: SkaterTuning) -> void:
	var gentle: float = _carve(t, 15.0, deg_to_rad(10.0), 2.0)
	var hard: float = _carve(t, 15.0, deg_to_rad(t.lean_max_deg), 2.0)
	check(hard < gentle, "sharper carve scrubs more speed")


func test_side_friction_never_reverses(t: SkaterTuning) -> void:
	var cap: float = t.side_grip * t.gravity * DT
	check(SkateMath.apply_side_friction(t, cap * 0.5, DT) == 0.0, "small slide stops dead")
	check(is_equal_approx(SkateMath.apply_side_friction(t, -5.0, DT), -5.0 + cap), "big slide bleeds at grip limit")


func test_strides_fade_with_speed(t: SkaterTuning) -> void:
	var mid: float = t.stride_push_share * 0.5
	var at_rest: float = SkateMath.stride_accel(t, 0.0, mid)
	check(is_equal_approx(at_rest, t.stride_peak_accel), "full push from a standstill")
	check(SkateMath.stride_accel(t, t.stride_max_speed * 0.5, mid) < at_rest, "pushes weaken as speed rises")
	check(SkateMath.stride_accel(t, t.stride_max_speed, mid) == 0.0, "no push at stride max speed")
	check(SkateMath.stride_accel(t, t.stride_max_speed * 2.0, mid) == 0.0, "no push above it")


func test_strides_only_push_in_push_phase(t: SkaterTuning) -> void:
	check(SkateMath.stride_accel(t, 0.0, 0.0) < 0.01, "push starts soft")
	check(SkateMath.stride_accel(t, 0.0, (t.stride_push_share + 1.0) * 0.5) == 0.0, "glide phase does not push")


func test_stride_takeoff_is_realistic(t: SkaterTuning) -> void:
	# Real skaters reach ~20 km/h in a few seconds of striding on the flat.
	var v: float = 0.0
	var time: float = 0.0
	while v < 20.0 / 3.6 and time < 10.0:
		var phase: float = fmod(time, t.stride_period) / t.stride_period
		v += SkateMath.stride_accel(t, v, phase) * DT
		v = SkateMath.apply_resistance(t, v, t.drag, DT)
		time += DT
	check(time > 2.0 and time < 6.0, "0-20 km/h striding takes 2-6 s (took %.2f)" % time)


func test_braking_distances(t: SkaterTuning) -> void:
	check(SkateMath.brake_decel(t, 20.0, true) > SkateMath.brake_decel(t, 3.0, false), "powerslide out-brakes the T-stop")
	check(is_equal_approx(SkateMath.brake_decel(t, 3.0, false), t.t_stop_decel), "T-stop when slow")
	# Powerslide from 90 km/h on the flat: real skaters need roughly 40-70 m.
	var v: float = 25.0
	var dist: float = 0.0
	while v > 0.0:
		v = maxf(v - SkateMath.brake_decel(t, v, true) * DT, 0.0)
		v = SkateMath.apply_resistance(t, v, t.drag, DT)
		dist += v * DT
	check(dist > 40.0 and dist < 70.0, "90 km/h stop takes 40-70 m (took %.1f)" % dist)


func test_tuck_raises_top_speed(t: SkaterTuning) -> void:
	var slope: float = deg_to_rad(12.0)
	var push: float = t.gravity * (sin(slope) - t.rolling_resistance * cos(slope))
	var upright: float = sqrt(push / t.drag)
	var tucked: float = sqrt(push / t.drag_tuck)
	check(tucked > upright * 1.25, "tuck raises top speed by over 25%")
	check(upright * 3.6 > 50.0 and upright * 3.6 < 90.0, "upright top speed on 12° is 50-90 km/h (%.0f)" % (upright * 3.6))


func test_landing_downslope_keeps_speed(t: SkaterTuning) -> void:
	var incoming := Vector3(0, -6, -15)
	var flat: Vector3 = SkateMath.landing_velocity(t, incoming, Vector3.UP)
	var slope_n: Vector3 = Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(-20.0))  # falls away toward -Z
	var down: Vector3 = SkateMath.landing_velocity(t, incoming, slope_n)
	check(down.length() > flat.length(), "downslope landing keeps more speed than flat")
	check(absf(flat.dot(Vector3.UP)) < 0.001, "landing velocity runs along the ground")
	check(flat.length() < 15.0, "flat landing bleeds some speed")
	check(is_equal_approx(SkateMath.landing_velocity(t, Vector3(0, 0, -10), Vector3.UP).length(), 10.0), "no impact, no loss")


func test_landing_straightens_small_misalignment(t: SkaterTuning) -> void:
	var vel := Vector3(0, 0, -15)
	var small: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(t.landing_align_deg * 0.5))
	check(SkateMath.landing_heading(t, small, vel, Vector3.UP).is_equal_approx(Vector3.FORWARD), "small misalignment straightens")
	var big: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(t.landing_align_deg + 15.0))
	check(SkateMath.landing_heading(t, big, vel, Vector3.UP).is_equal_approx(big), "big misalignment stays crooked")


func test_resistance_never_reverses(t: SkaterTuning) -> void:
	check(SkateMath.apply_resistance(t, 0.01, t.drag, 1.0) == 0.0, "resistance stops at zero")
	check(SkateMath.apply_resistance(t, -5.0, t.drag, 0.01) > -5.0, "resistance slows reverse rolling")


func test_pop_speed_range(t: SkaterTuning) -> void:
	check(is_equal_approx(SkateMath.pop_speed(t, 0.0), t.pop_min), "tap pop")
	check(is_equal_approx(SkateMath.pop_speed(t, 5.0), t.pop_max), "charge clamps")


func test_landing_verdicts(t: SkaterTuning) -> void:
	var fwd := Vector3.FORWARD
	var clean: Dictionary = SkateMath.judge_landing(t, fwd, Vector3(0, -5, -15), Vector3.UP)
	check(clean["ok"], "straight landing is clean")
	var side: Dictionary = SkateMath.judge_landing(t, Vector3.RIGHT, Vector3(0, -5, -15), Vector3.UP)
	check(not side["ok"] and side["reason"] == "Landed sideways", "sideways landing bails")
	var hard: Dictionary = SkateMath.judge_landing(t, fwd, Vector3(0, -(t.crash_land_impact + 1.0), -10), Vector3.UP)
	check(not hard["ok"] and hard["reason"] == "Landed too hard", "hard landing bails")
