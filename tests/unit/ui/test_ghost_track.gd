extends SceneTree
## Unit tests for GhostTrack (best-run ghost recording). Run headless:
##   godot --headless --script res://tests/unit/ui/test_ghost_track.gd

const HZ: float = 10.0
const POSE: int = 2

var _fails: int = 0


func _init() -> void:
	test_record_spaces_samples_by_rate()
	test_slow_frame_fills_missing_samples()
	test_sample_interpolates_between_samples()
	test_sample_clamps_and_reports_done()
	test_teleport_snaps_instead_of_blending()
	test_dict_round_trip_keeps_samples()
	test_from_dict_rejects_bad_data()
	print("GhostTrack tests: %s" % ("PASS" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)


func check(cond: bool, name: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: ", name)


func _pose(a: float, b: float) -> PackedFloat32Array:
	return PackedFloat32Array([a, b])


func _track_line() -> GhostTrack:
	# 0..1 s along +x at 1 m per sample-tick: x = 10 * t.
	var g := GhostTrack.new(HZ, POSE, 8.0)
	for i: int in 11:
		var t: float = i / HZ
		g.record(t, Vector3(10.0 * t, 0, 0), Quaternion.IDENTITY, _pose(t, 1.0))
	return g


func test_record_spaces_samples_by_rate() -> void:
	var g := GhostTrack.new(HZ, POSE)
	for i: int in 40:
		g.record(i / 40.0, Vector3.ZERO, Quaternion.IDENTITY, _pose(0, 0))
	check(g.size() == 10, "40 frames over 0.975 s at 10 Hz give 10 samples (got %d)" % g.size())


func test_slow_frame_fills_missing_samples() -> void:
	var g := GhostTrack.new(HZ, POSE)
	g.record(0.0, Vector3.ZERO, Quaternion.IDENTITY, _pose(0, 0))
	g.record(0.35, Vector3.ONE, Quaternion.IDENTITY, _pose(0, 0))
	check(g.size() == 4, "a 0.35 s gap adds samples 1..3")


func test_sample_interpolates_between_samples() -> void:
	var s: Dictionary = _track_line().sample_at(0.25)
	check(is_equal_approx((s["pos"] as Vector3).x, 2.5), "position halfway between samples")
	check(is_equal_approx((s["pose"] as PackedFloat32Array)[0], 0.25), "pose floats interpolate")
	check(not s["done"], "not done mid-run")


func test_sample_clamps_and_reports_done() -> void:
	var g := _track_line()
	check(is_equal_approx(g.duration(), 1.0), "duration is last sample time")
	check(is_equal_approx((g.sample_at(-1.0)["pos"] as Vector3).x, 0.0), "clamps before start")
	var end: Dictionary = g.sample_at(5.0)
	check(is_equal_approx((end["pos"] as Vector3).x, 10.0), "clamps after end")
	check(end["done"], "done after end")


func test_teleport_snaps_instead_of_blending() -> void:
	var g := GhostTrack.new(HZ, POSE, 8.0)
	g.record(0.0, Vector3.ZERO, Quaternion.IDENTITY, _pose(0, 0))
	g.record(0.1, Vector3(50, 0, 0), Quaternion.IDENTITY, _pose(0, 0))
	check(is_equal_approx((g.sample_at(0.04)["pos"] as Vector3).x, 0.0), "before midpoint holds the old spot")
	check(is_equal_approx((g.sample_at(0.06)["pos"] as Vector3).x, 50.0), "after midpoint jumps to the new spot")


func test_dict_round_trip_keeps_samples() -> void:
	var g := _track_line()
	g.finish_time = 1.03
	var back: GhostTrack = GhostTrack.from_dict(g.to_dict(), POSE)
	check(back != null, "round trip loads")
	check(back.size() == g.size() and is_equal_approx(back.sample_hz, HZ), "round trip keeps size and rate")
	check(is_equal_approx((back.sample_at(0.55)["pos"] as Vector3).x, 5.5), "round trip keeps data")
	check(is_equal_approx(back.finish_time, 1.03), "round trip keeps finish time")


func test_from_dict_rejects_bad_data() -> void:
	var d: Dictionary = _track_line().to_dict()
	check(GhostTrack.from_dict(null, POSE) == null, "null rejected")
	check(GhostTrack.from_dict(d, POSE + 1) == null, "other pose layout rejected")
	var wrong := d.duplicate()
	wrong["version"] = 99
	check(GhostTrack.from_dict(wrong, POSE) == null, "other version rejected")
	var short := d.duplicate()
	short["data"] = PackedFloat32Array([1, 2, 3])
	check(GhostTrack.from_dict(short, POSE) == null, "ragged data rejected")
