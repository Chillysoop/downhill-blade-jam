extends SceneTree
## Unit tests for SkateMath. Run headless:
##   godot --headless --script res://tests/unit/skater/test_skate_math.gd

var _fails: int = 0


func _init() -> void:
	var t := SkaterTuning.new()
	test_turn_rate_slows_with_speed(t)
	test_tuck_reduces_turning(t)
	test_grip_keeps_most_speed(t)
	test_resistance_never_reverses(t)
	test_pop_speed_range(t)
	test_landing_verdicts(t)
	print("SkateMath tests: %s" % ("PASS" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)


func check(cond: bool, name: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: ", name)


func test_turn_rate_slows_with_speed(t: SkaterTuning) -> void:
	check(is_equal_approx(SkateMath.turn_rate(t, 0.0, false), t.turn_rate_slow), "turn rate at rest")
	check(is_equal_approx(SkateMath.turn_rate(t, t.turn_rate_speed_ref * 2.0, false), t.turn_rate_fast), "turn rate clamps at speed")


func test_tuck_reduces_turning(t: SkaterTuning) -> void:
	check(SkateMath.turn_rate(t, 10.0, true) < SkateMath.turn_rate(t, 10.0, false), "tuck turns slower")


func test_grip_keeps_most_speed(t: SkaterTuning) -> void:
	var v: Vector2 = Vector2(10.0, 5.0)
	for i: int in 240:
		v = SkateMath.apply_grip(t, v.x, v.y, 1.0 / 120.0)
	check(absf(v.y) < 0.01, "lateral speed cancelled")
	check(v.x > 10.0 and v.x <= 10.0 + 5.0 * t.carve_efficiency + 0.001, "carve keeps share of lateral speed")


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
