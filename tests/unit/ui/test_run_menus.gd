extends SceneTree
## Unit tests for the run-menu logic: personal-best records, the course list
## and time-delta formatting. Run headless:
##   godot --headless --script res://tests/unit/ui/test_run_menus.gd

var _fails: int = 0


func _init() -> void:
	test_first_finish_is_new_best()
	test_slower_run_is_not_saved()
	test_faster_run_replaces_best_and_splits()
	test_records_are_per_course()
	test_catalog_skips_bad_entries_and_defaults_name()
	test_catalog_find_falls_back_to_first()
	test_catalog_find_by_path()
	test_format_delta_signs()
	print("RunMenus tests: %s" % ("PASS" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)


func check(cond: bool, name: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: ", name)


func _splits(values: Array) -> Array[float]:
	var out: Array[float] = []
	for v: Variant in values:
		out.append(float(v))
	return out


func test_first_finish_is_new_best() -> void:
	var r := RunRecords.new()
	check(r.best_time("a") == 0.0, "no best before any run")
	check(r.submit("a", 70.0, _splits([20.0, 45.0])), "first finish is a new best")
	check(is_equal_approx(r.best_time("a"), 70.0), "first finish stored")
	check(r.best_splits("a") == _splits([20.0, 45.0]), "first splits stored")


func test_slower_run_is_not_saved() -> void:
	var r := RunRecords.new()
	r.submit("a", 70.0, _splits([20.0]))
	check(not r.submit("a", 71.0, _splits([19.0])), "slower run is not a best")
	check(is_equal_approx(r.best_time("a"), 70.0), "best unchanged by slower run")
	check(r.best_splits("a") == _splits([20.0]), "splits unchanged by slower run")
	check(not r.submit("a", 69.999, _splits([])), "run that reads the same is not a best")


func test_faster_run_replaces_best_and_splits() -> void:
	var r := RunRecords.new()
	r.submit("a", 70.0, _splits([20.0]))
	check(r.submit("a", 65.5, _splits([18.0])), "faster run is a best")
	check(is_equal_approx(r.best_time("a"), 65.5), "faster best stored")
	check(r.best_splits("a") == _splits([18.0]), "faster splits stored")


func test_records_are_per_course() -> void:
	var r := RunRecords.new()
	r.submit("a", 70.0, _splits([]))
	check(r.best_time("b") == 0.0, "other course has no best")
	check(r.is_new_best("b", 99.0), "any finish is a best on a new course")


func test_catalog_skips_bad_entries_and_defaults_name() -> void:
	var cat := CourseCatalog.from_dict({"courses": [
		{"id": "m1", "path": "res://m1.json"},
		{"id": "", "path": "res://x.json"},
		{"id": "nopath"},
		"junk",
	]})
	check(cat.courses.size() == 1, "only valid entries kept")
	check(cat.courses[0]["name"] == "m1", "missing name falls back to id")


func test_catalog_find_falls_back_to_first() -> void:
	var cat := CourseCatalog.from_dict({"courses": [
		{"id": "m1", "name": "One", "path": "p1"}, {"id": "m2", "name": "Two", "path": "p2"}]})
	check(cat.find("m2")["name"] == "Two", "find by id")
	check(cat.find("")["id"] == "m1", "unknown id gives the first course")
	check(CourseCatalog.from_dict({}).find("m1").is_empty(), "empty catalog gives empty entry")


func test_catalog_find_by_path() -> void:
	var cat := CourseCatalog.from_dict({"courses": [{"id": "ts", "path": "test_slope"}]})
	check(cat.find_by_path("test_slope")["id"] == "ts", "find by path")
	check(cat.find_by_path("nope").is_empty(), "unknown path gives empty entry")


func test_format_delta_signs() -> void:
	check(Hud.format_delta(-1.25) == "-1.25", "faster delta has minus")
	check(Hud.format_delta(2.5) == "+2.50", "slower delta has plus")
	check(Hud.format_delta(0.0) == "+0.00", "tie shows plus zero")
	check(Hud.format_delta(-0.001) == "+0.00", "rounds-to-zero gain shows plus zero")
	check(Hud.format_delta(-75.0) == "-1:15.00", "delta over a minute uses M:SS.cc")
