extends SceneTree
## Unit tests for CourseMath and the off-piste drag rule. Run headless:
##   godot --headless --script res://tests/unit/course/test_course_math.gd

var _fails: int = 0


func _init() -> void:
	test_curve_hits_knots_and_clamps()
	test_curve_is_monotone_between_monotone_knots()
	test_piecewise_interpolates_and_clamps()
	test_channel_profile_shape()
	test_bump_profile_shape()
	test_ellipse_outside_signs()
	test_rough_drag_floor()
	print("CourseMath tests: %s" % ("PASS" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)


func check(cond: bool, name: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: ", name)


func test_curve_hits_knots_and_clamps() -> void:
	var knots: Array = [[0, 0.0], [-100, -16.0], [-400, -91.0]]
	check(is_equal_approx(CourseMath.curve(knots, 0.0), 0.0), "curve at first knot")
	check(is_equal_approx(CourseMath.curve(knots, -100.0), -16.0), "curve at middle knot")
	check(is_equal_approx(CourseMath.curve(knots, -400.0), -91.0), "curve at last knot")
	check(is_equal_approx(CourseMath.curve(knots, 50.0), 0.0), "curve clamps uphill")
	check(is_equal_approx(CourseMath.curve(knots, -900.0), -91.0), "curve clamps downhill")


func test_curve_is_monotone_between_monotone_knots() -> void:
	var knots: Array = [[0, 0.0], [-100, -16.0], [-400, -91.0], [-650, -148.0]]
	var prev: float = CourseMath.curve(knots, 0.0)
	var ok: bool = true
	for i: int in range(1, 66):
		var v: float = CourseMath.curve(knots, -10.0 * i)
		if v > prev + 0.0001:
			ok = false
		prev = v
	check(ok, "base profile never climbs going downhill")


func test_piecewise_interpolates_and_clamps() -> void:
	var pts: Array = [[0, 0.0], [4, 3.0], [40, 12.0]]
	check(is_equal_approx(CourseMath.piecewise(pts, -5.0), 0.0), "piecewise clamps low")
	check(is_equal_approx(CourseMath.piecewise(pts, 2.0), 1.5), "piecewise midpoint")
	check(is_equal_approx(CourseMath.piecewise(pts, 99.0), 12.0), "piecewise clamps high")


func test_channel_profile_shape() -> void:
	check(is_equal_approx(CourseMath.channel_profile(0.0, 30.0, 4.0, 0.35), 4.0), "channel full depth on the floor")
	check(is_equal_approx(CourseMath.channel_profile(15.0, 30.0, 4.0, 0.35), 0.0), "channel zero at the rim")
	var mid: float = CourseMath.channel_profile(10.0, 30.0, 4.0, 0.35)
	check(mid > 0.0 and mid < 4.0, "channel bank between floor and rim")


func test_bump_profile_shape() -> void:
	check(is_equal_approx(CourseMath.bump_profile(-1.0, 3.0, 2.0), 3.0), "bump full height inside")
	check(is_equal_approx(CourseMath.bump_profile(2.0, 3.0, 2.0), 0.0), "bump zero past the edge")
	check(is_equal_approx(CourseMath.bump_profile(1.0, 3.0, 2.0), 1.5), "bump half way down the flank")


func test_ellipse_outside_signs() -> void:
	var c := Vector2(0, 0)
	check(CourseMath.ellipse_outside(Vector2(0, 0), c, 10.0, 20.0, 0.0) < 0.0, "centre is inside")
	var side: float = CourseMath.ellipse_outside(Vector2(12, 0), c, 10.0, 20.0, 0.0)
	check(absf(side - 2.0) < 0.3, "side distance ~2 m (got %.2f)" % side)
	var end: float = CourseMath.ellipse_outside(Vector2(0, 25), c, 10.0, 20.0, 0.0)
	check(absf(end - 5.0) < 0.5, "end distance ~5 m (got %.2f)" % end)


func test_rough_drag_floor() -> void:
	var rule: Dictionary = {"drag_v2": 0.018, "rolling": 1.0, "min_speed": 4.0}
	check(SurfaceDrag.extra_decel(rule, 3.0) == 0.0, "no rough drag below the push floor")
	check(SurfaceDrag.extra_decel(rule, 20.0) > SurfaceDrag.extra_decel(rule, 10.0), "rough drag grows with speed")
	check(SurfaceDrag.extra_decel({}, 20.0) == 0.0, "concrete has no extra drag")
