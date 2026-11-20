extends SceneTree
## Unit tests for HUD readouts: the mph speed and the carve meter's numbers.
## Run headless:
##   godot --headless --script res://tests/unit/ui/test_hud_readouts.gd

var _fails: int = 0


func _init() -> void:
	test_speed_reads_in_mph()
	test_meter_needle_follows_lean()
	test_meter_shows_where_grip_runs_out()
	print("HudReadouts tests: %s" % ("PASS" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)


func check(cond: bool, name: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: ", name)


func test_speed_reads_in_mph() -> void:
	check(Hud.format_speed(10.0) == "22 mph", "10 m/s reads 22 mph (%s)" % Hud.format_speed(10.0))
	check(Hud.format_speed(0.0) == "0 mph", "standing reads 0 mph")
	check(Hud.format_speed(26.8224) == "60 mph", "26.82 m/s reads 60 mph")


func test_meter_needle_follows_lean() -> void:
	var t := SkaterTuning.new()
	var full: float = deg_to_rad(t.lean_max_deg)
	check(is_equal_approx(CarveMeter.needle(t, full, 0.0), 1.0), "full right lean puts the needle at the right end")
	check(is_equal_approx(CarveMeter.needle(t, -full * 0.5, 0.0), -0.5), "half left lean, half way left")


func test_meter_shows_where_grip_runs_out() -> void:
	var t := SkaterTuning.new()
	# Slow, the wheels hold any lean: no wash zone on the dial.
	check(CarveMeter.grip_edge(t, 5.0, 0.0) >= 1.0, "slow: grip holds a full lean")
	# Fast, grip runs out before full lean: the zone starts inside the dial.
	var edge: float = CarveMeter.grip_edge(t, 25.0, 0.0)
	check(edge > 0.0 and edge < 1.0, "at 90 km/h the wash zone starts before full lean (%.2f)" % edge)
	check(CarveMeter.radius_text(6.04) == "6 m", "radius reads in whole metres")
	check(CarveMeter.radius_text(0.8) == "0.8 m", "tight radii read to a tenth")
