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
	test_carves_are_sharp(t)
	test_tucked_carves_still_turn(t)
	test_lean_is_quick(t)
	test_slow_sideways_landing_steps_around(t)
	test_tuck_takes_time_to_exit(t)
	test_tuck_blends_drag_and_lean(t)
	test_grip_drops_with_speed(t)
	test_full_lean_at_speed_washes_wide(t)
	test_gentle_carve_holds_grip(t)
	test_grip_usage(t)
	test_edge_level()
	test_seam_normals(t)
	test_stride_or_tuck(t)
	test_flatter_normal_is_never_a_seam(t)
	test_snap_follows_only_what_gravity_can(t)
	test_air_spin_carries_takeoff_turn(t)
	test_air_correction_is_small(t)
	test_ground_load(t)
	test_pumping_gains_only_with_timing(t)
	print("SkateMath tests: %s" % ("PASS" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)


func check(cond: bool, name: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: ", name)


func test_lean_moves_at_lean_rate(t: SkaterTuning) -> void:
	var step: float = deg_to_rad(t.lean_rate_deg) * 0.05
	var lean: float = SkateMath.step_lean(t, 0.0, 1.0, 0.0, 0.05)
	check(is_equal_approx(lean, step), "lean rolls in at lean rate")
	for i: int in 200:
		lean = SkateMath.step_lean(t, lean, 1.0, 0.0, DT)
	check(is_equal_approx(lean, deg_to_rad(t.lean_max_deg)), "full steer reaches max lean")
	for i: int in 400:
		lean = SkateMath.step_lean(t, lean, -0.5, 0.0, DT)
	check(is_equal_approx(lean, -0.5 * deg_to_rad(t.lean_max_deg)), "half steer the other way")


func test_tuck_limits_lean(t: SkaterTuning) -> void:
	var lean: float = 0.0
	for i: int in 400:
		lean = SkateMath.step_lean(t, lean, 1.0, 1.0, DT)
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
	check(absf(w - maxf(v / t.min_turn_radius, t.pivot_turn_rate)) < 0.001, "footwork limits the tightest slow turn")
	check(is_equal_approx(SkateMath.carve_turn_rate(t, 0.0, lean), t.pivot_turn_rate), "can step around when stopped")


## Simulates a grounded carve on the flat the way Skater does it: rotate the
## skates, let the wheels' side friction pull the velocity round, pay the scrub.
func _carve(t: SkaterTuning, speed: float, lean: float, seconds: float) -> float:
	return _carve_state(t, speed, lean, seconds)["speed"]


## Same simulation, returning speed, how far the skates turned, how far the
## travel direction turned, and the sideways slip at the end.
func _carve_state(t: SkaterTuning, speed: float, lean: float, seconds: float) -> Dictionary:
	var vel := Vector3(0, 0, -speed)
	var heading := Vector3.FORWARD
	for i: int in int(seconds / DT):
		var sp: float = vel.length()
		var w: float = SkateMath.carve_turn_rate(t, sp, lean)
		heading = heading.rotated(Vector3.UP, -w * DT)
		var right: Vector3 = heading.cross(Vector3.UP)
		var vf: float = vel.dot(heading)
		var vl: float = SkateMath.apply_side_friction(t, vel.dot(right), sp, DT)
		vf = SkateMath.apply_carve_scrub(t, vf, sp, w, DT)
		vel = heading * vf + right * vl
	return {
		"speed": vel.length(),
		"heading_turn": Vector3.FORWARD.angle_to(heading),
		"travel_turn": Vector3.FORWARD.angle_to(vel.normalized()),
		"slip": absf(vel.dot(heading.cross(Vector3.UP))),
	}


func test_carving_never_gains_speed(t: SkaterTuning) -> void:
	var end: float = _carve(t, 15.0, deg_to_rad(t.lean_max_deg), 2.0)
	check(end <= 15.0, "carving does not create speed")
	check(end > 13.0, "a clean carve keeps most of its speed")


func test_harder_carves_cost_more(t: SkaterTuning) -> void:
	var gentle: float = _carve(t, 15.0, deg_to_rad(10.0), 2.0)
	var hard: float = _carve(t, 15.0, deg_to_rad(t.lean_max_deg), 2.0)
	check(hard < gentle, "sharper carve scrubs more speed")


func test_side_friction_never_reverses(t: SkaterTuning) -> void:
	var cap: float = SkateMath.side_grip_at(t, 0.0) * t.gravity * DT
	check(SkateMath.apply_side_friction(t, cap * 0.5, 0.0, DT) == 0.0, "small slide stops dead")
	check(is_equal_approx(SkateMath.apply_side_friction(t, -5.0, 0.0, DT), -5.0 + cap), "big slide bleeds at grip limit")


func test_strides_fade_with_speed(t: SkaterTuning) -> void:
	var mid: float = t.stride_push_share * 0.5
	var at_rest: float = SkateMath.stride_accel(t, 0.0, mid)
	check(is_equal_approx(at_rest, t.stride_peak_accel), "full push from a standstill")
	check(SkateMath.stride_accel(t, 8.0, mid) < at_rest, "pushes weaken as speed rises (legs have only so much power)")
	check(SkateMath.stride_accel(t, 16.0, mid) < SkateMath.stride_accel(t, 8.0, mid), "and keep weakening")
	check(SkateMath.stride_accel(t, 16.0, mid) >= 0.0, "a push never slows you")


func test_strides_only_push_in_push_phase(t: SkaterTuning) -> void:
	check(SkateMath.stride_accel(t, 0.0, 0.0) < 0.01, "push starts soft")
	check(SkateMath.stride_accel(t, 0.0, (t.stride_push_share + 1.0) * 0.5) == 0.0, "glide phase does not push")


## Seconds of striding on the flat from a standstill to [param kmh].
func _stride_time(t: SkaterTuning, kmh: float) -> float:
	var v: float = 0.0
	var time: float = 0.0
	while v < kmh / 3.6 and time < 30.0:
		var phase: float = fmod(time, t.stride_period) / t.stride_period
		v += SkateMath.stride_accel(t, v, phase) * DT
		v = SkateMath.apply_resistance(t, v, t.drag, DT)
		time += DT
	return time


func test_stride_takeoff_is_realistic(t: SkaterTuning) -> void:
	# A strong skater sprinting off the line: jogging pace in about a second,
	# 20 km/h in about two, 30 km/h in about four (research in
	# design/quick-specs/snappy-skating-2026-11-19.md).
	var t15: float = _stride_time(t, 15.0)
	var t20: float = _stride_time(t, 20.0)
	var t30: float = _stride_time(t, 30.0)
	check(t15 > 0.7 and t15 < 1.5, "0-15 km/h takes 0.7-1.5 s (took %.2f)" % t15)
	check(t20 > 1.2 and t20 < 2.5, "0-20 km/h takes 1.2-2.5 s (took %.2f)" % t20)
	check(t30 > 2.5 and t30 < 5.0, "0-30 km/h takes 2.5-5 s (took %.2f)" % t30)
	# Holding W on the flat settles where push power meets drag.
	var top: float = _stride_time(t, 60.0)
	check(top >= 30.0, "striding on the flat tops out below 60 km/h")
	check(_stride_time(t, 38.0) < 30.0, "a strong skater holds about 40 km/h on the flat")


func test_braking_distances(t: SkaterTuning) -> void:
	check(SkateMath.brake_decel(t, 20.0, true) > SkateMath.brake_decel(t, 3.0, false), "hard T-stop at speed out-brakes the slow one")
	check(is_equal_approx(SkateMath.brake_decel(t, 3.0, false), t.t_stop_decel), "T-stop when slow")
	# Hard T-stop from 90 km/h on the flat: real skaters need roughly 40-70 m.
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


func test_slow_sideways_landing_steps_around(t: SkaterTuning) -> void:
	# At jogging pace a skater lands a hop turned well off line and just steps
	# the skates around (a tight slow carve carries ~60-100° into a hop).
	# 3.5 m/s (12.6 km/h): the bot's tight-carve hop on the test slope that bailed.
	var v := Vector3(0, -3, -3.5)
	var turned: Dictionary = SkateMath.judge_landing(t, Vector3.RIGHT, v, Vector3.UP)
	check(turned["ok"], "a slow hop landed sideways is a step-around, not a bail")
	var fast: Dictionary = SkateMath.judge_landing(t, Vector3.RIGHT, Vector3(0, -3, -6.0), Vector3.UP)
	check(not fast["ok"], "sideways at speed still bails")


func test_tuck_takes_time_to_exit(t: SkaterTuning) -> void:
	var amount: float = 1.0
	var time: float = 0.0
	while amount > 0.0 and time < 5.0:
		amount = SkateMath.step_tuck(t, amount, false, DT)
		time += DT
	check(absf(time - t.tuck_out_time) < 2.0 * DT, "standing up from a full tuck takes tuck_out_time")
	check(SkateMath.step_tuck(t, 0.0, true, t.tuck_in_time) == 1.0, "dropping into a tuck takes tuck_in_time")
	check(SkateMath.step_tuck(t, 0.5, true, 10.0) == 1.0 and SkateMath.step_tuck(t, 0.5, false, 10.0) == 0.0, "tuck stays in 0..1")


func test_tuck_blends_drag_and_lean(t: SkaterTuning) -> void:
	check(is_equal_approx(SkateMath.drag_for(t, 0.0), t.drag), "upright drag")
	check(is_equal_approx(SkateMath.drag_for(t, 1.0), t.drag_tuck), "tucked drag")
	var half: float = SkateMath.drag_for(t, 0.5)
	check(half < t.drag and half > t.drag_tuck, "half tuck is in between")
	check(SkateMath.lean_limit(t, 0.5) < deg_to_rad(t.lean_max_deg), "half out of a tuck you can't lean all the way yet")


func test_grip_drops_with_speed(t: SkaterTuning) -> void:
	check(is_equal_approx(SkateMath.side_grip_at(t, 0.0), t.side_grip), "full grip when slow")
	check(SkateMath.side_grip_at(t, 30.0) < SkateMath.side_grip_at(t, 10.0), "less grip at speed")
	check(SkateMath.side_grip_at(t, 1000.0) > 0.0, "grip never vanishes")


func test_full_lean_at_speed_washes_wide(t: SkaterTuning) -> void:
	var r: Dictionary = _carve_state(t, 25.0, deg_to_rad(t.lean_max_deg), 1.5)
	check(r["slip"] > 0.5, "full lean at 90 km/h slides sideways (%.2f m/s)" % r["slip"])
	check(r["travel_turn"] < r["heading_turn"] - 0.02, "travel turns less than the skates: washing wide")
	var clean: float = _carve(t, 25.0, deg_to_rad(25.0), 1.5)
	check(r["speed"] < clean, "washing out costs more speed than a clean carve")


func test_gentle_carve_holds_grip(t: SkaterTuning) -> void:
	var r: Dictionary = _carve_state(t, 25.0, deg_to_rad(25.0), 1.5)
	check(r["slip"] < 0.05, "a gentle carve does not slide (%.3f m/s)" % r["slip"])
	var slow: Dictionary = _carve_state(t, 6.0, deg_to_rad(t.lean_max_deg), 1.5)
	check(slow["slip"] < 0.2, "full lean holds at low speed (%.3f m/s)" % slow["slip"])


func test_grip_usage(t: SkaterTuning) -> void:
	var w_full: float = SkateMath.carve_turn_rate(t, 25.0, deg_to_rad(t.lean_max_deg))
	check(SkateMath.grip_usage(t, 25.0, w_full, 0.0) > 1.0, "full lean at speed asks for more than the wheels have")
	var w_soft: float = SkateMath.carve_turn_rate(t, 25.0, deg_to_rad(15.0))
	check(SkateMath.grip_usage(t, 25.0, w_soft, 0.0) < 0.5, "soft carve uses little grip")
	check(SkateMath.grip_usage(t, 25.0, 0.0, 3.0) >= 1.0, "sliding sideways means grip is gone")


func test_edge_level() -> void:
	check(SkateAudio.edge_level(0.5) == 0.0, "no warning with plenty of grip")
	check(SkateAudio.edge_level(0.925) > 0.0 and SkateAudio.edge_level(0.925) < 1.0, "warning builds near the limit")
	check(SkateAudio.edge_level(1.3) == 1.0, "full warning past the limit")


func test_seam_normals(t: SkaterTuning) -> void:
	var flat := Vector3.UP
	var break_20: Vector3 = Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(-20.0))
	var corner_50: Vector3 = Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(-50.0))
	check(not SkateMath.is_seam_normal(t, flat, break_20), "a 20 degree slope break is real ground")
	check(SkateMath.is_seam_normal(t, flat, corner_50), "a 50 degree jump is a seam")


func test_stride_or_tuck(t: SkaterTuning) -> void:
	# Holding forward strides while a push still beats the drag a tuck saves,
	# so you keep skating on the flat and tuck once gravity carries you.
	check(SkateMath.prefer_stride(t, 4.0, false), "stride when slow")
	check(SkateMath.prefer_stride(t, 8.0, false), "still striding at ~29 km/h")
	check(SkateMath.prefer_stride(t, 12.0, false), "still pushing at 43 km/h, as sprinters do")
	check(not SkateMath.prefer_stride(t, 20.0, false), "tuck at 72 km/h")
	check(not SkateMath.prefer_stride(t, 25.0, false), "tuck at 90 km/h")
	# Hysteresis: near the switch speed, keep doing what you were doing.
	var v: float = 0.0
	while SkateMath.prefer_stride(t, v, false) and v < 30.0:
		v += 0.01
	check(SkateMath.prefer_stride(t, v - 0.05, false), "just below the switch you stride")
	check(not SkateMath.prefer_stride(t, v - 0.05, true), "already tucked just below it, you stay tucked")
	check(SkateMath.stride_avg_accel(t, 0.0) > 2.5 and SkateMath.stride_avg_accel(t, 0.0) < 4.5, "average push from standing is 2.5-4.5 m/s² (a sprint start)")


func test_flatter_normal_is_never_a_seam(t: SkaterTuning) -> void:
	var steep: Vector3 = Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(-45.0))
	check(not SkateMath.is_seam_normal(t, steep, Vector3.UP), "rolling from a stale steep normal onto flat ground is real")
	check(SkateMath.is_seam_normal(t, Vector3.UP, steep), "a sudden 45 degree normal under flat ground is a seam")


func test_snap_follows_only_what_gravity_can(t: SkaterTuning) -> void:
	var snap: float = SkateMath.snap_length(t, 1.0 / 60.0)
	check(snap > 0.0 and snap < 0.1, "snap is a few centimetres, not a stair step (%.3f m)" % snap)
	check(snap < 0.17, "a 17 cm stair drop is never glued down")


func test_air_spin_carries_takeoff_turn(t: SkaterTuning) -> void:
	check(is_equal_approx(SkateMath.air_takeoff_spin(t, 1.2, 0.0, 0.0), 1.2), "rolling off a carve keeps its turn")
	var wound: float = SkateMath.air_takeoff_spin(t, 0.0, 1.0, 1.0)
	check(is_equal_approx(wound, t.air_windup_max), "full steer on a full pop winds up the most")
	check(SkateMath.air_takeoff_spin(t, 0.0, 1.0, 0.0) < wound, "a tap winds up less")
	check(SkateMath.air_takeoff_spin(t, 0.0, -1.0, 1.0) < 0.0, "wind-up follows the steer side")


func test_air_correction_is_small(t: SkaterTuning) -> void:
	var takeoff: float = 0.0
	var spin: float = takeoff
	for i: int in 240:
		spin = SkateMath.step_air_spin(t, spin, takeoff, 1.0, DT)
	check(is_equal_approx(spin, t.air_correction_rate), "full steer in the air only nudges the spin")
	check(t.air_correction_rate < 2.0, "in-air correction stays well under a fast spin")
	spin = SkateMath.step_air_spin(t, 0.0, 3.0, 0.0, DT)
	check(spin > 0.0 and spin < 3.0, "spin eases toward the takeoff spin, not jumping to it")


func test_ground_load(t: SkaterTuning) -> void:
	var fwd := Vector3.FORWARD
	check(is_equal_approx(SkateMath.ground_load(t, Vector3.UP, Vector3.UP, fwd, 10.0, DT), t.gravity), "flat ground loads 1 g")
	# Into a dip the normal swings back against travel: more load.
	var tilted_fwd: Vector3 = Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(-1.0))
	var dip: float = SkateMath.ground_load(t, tilted_fwd, Vector3.UP, fwd, 10.0, DT)
	check(dip > t.gravity, "a dip presses you into the ground")
	var crest: float = SkateMath.ground_load(t, Vector3.UP, tilted_fwd, fwd, 10.0, DT)
	check(crest < t.gravity, "a crest unweights you")
	check(SkateMath.ground_load(t, Vector3.UP, Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(-20.0)), fwd, 30.0, DT) >= 0.0, "load never goes negative")


func test_pumping_gains_only_with_timing(t: SkaterTuning) -> void:
	var v: float = 10.0
	# On the flat or a steady slope (no curve load), crouching or standing
	# changes nothing: gravity's share only moves your hips up and down.
	v = SkateMath.pump_speed(t, v, 1.0, 0.0)
	check(is_equal_approx(v, 10.0), "crouching on the flat costs nothing")
	v = SkateMath.pump_speed(t, v, -1.0, 0.0)
	check(is_equal_approx(v, 10.0), "standing up on the flat gains nothing")
	# Stand up in the dip (pressed down), crouch over the crest (unweighted): gain.
	var good: float = SkateMath.pump_speed(t, SkateMath.pump_speed(t, 10.0, -1.0, 0.6 * t.gravity), 1.0, -0.5 * t.gravity)
	check(good > 10.1, "well-timed pump gains speed (%.3f)" % good)
	# Backwards timing loses it.
	var bad: float = SkateMath.pump_speed(t, SkateMath.pump_speed(t, 10.0, 1.0, 0.6 * t.gravity), -1.0, -0.5 * t.gravity)
	check(bad < 10.0, "badly timed pump costs speed")
	check(SkateMath.pump_speed(t, 0.1, 1.0, 3.0 * t.gravity) >= 0.0, "pumping never makes speed negative")


func test_carves_are_sharp(t: SkaterTuning) -> void:
	# At 30 km/h a full carve turns in a ~6 m radius and the wheels hold it.
	var v: float = 30.0 / 3.6
	var w: float = SkateMath.carve_turn_rate(t, v, deg_to_rad(t.lean_max_deg))
	var radius: float = v / w
	check(radius < 6.5, "full carve at 30 km/h is under 6.5 m radius (%.1f)" % radius)
	check(SkateMath.grip_usage(t, v, w, 0.0) <= 1.0, "and the wheels hold it")
	# Slow footwork: you can turn on the spot.
	check(SkateMath.carve_turn_rate(t, 0.5, deg_to_rad(t.lean_max_deg)) >= 2.5, "pivot at walking pace is quick")
	check(SkateMath.carve_turn_rate(t, 3.0, deg_to_rad(t.lean_max_deg)) * 1.0 >= 3.0 / 1.25, "tightest slow circle is about a metre")


func test_tucked_carves_still_turn(t: SkaterTuning) -> void:
	# Downhill skaters carve from a tuck: at 50 km/h a full tucked carve is a
	# ~30 m radius, not a highway bend.
	var v: float = 50.0 / 3.6
	var w: float = SkateMath.carve_turn_rate(t, v, SkateMath.lean_limit(t, 1.0))
	check(v / w < 32.0, "tucked carve at 50 km/h is under 32 m radius (%.1f)" % (v / w))


func test_lean_is_quick(t: SkaterTuning) -> void:
	var lean: float = 0.0
	var time: float = 0.0
	while lean < deg_to_rad(t.lean_max_deg) - 0.001 and time < 1.0:
		lean = SkateMath.step_lean(t, lean, 1.0, 0.0, DT)
		time += DT
	check(time <= 0.16, "edge to full lean in under 0.16 s (%.2f)" % time)
