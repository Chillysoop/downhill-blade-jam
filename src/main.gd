extends Node3D
## Wires up a run: the course, skater, camera, HUD, lighting, the run timer,
## checkpoints/splits, restart, and the finish/pause/map menus
## (design/quick-specs/run-menus-2026-11-04.md). The course comes from map
## select (RunSession), else "--course=<path|test_slope>" after "--", else the
## first entry of assets/data/courses.json.

const MENU_CONFIG: String = "res://assets/data/run_menu.json"

var level: Node3D
var course: CourseBuilder
var skater: Skater
var camera: ChaseCamera
var hud: Hud
var menu: RunMenu
var catalog: CourseCatalog
var records := RunRecords.new()
## Catalog id of the loaded course (also the key for saved bests).
var course_id: String = ""
var course_name: String = ""

var run_time: float = 0.0
var best_time: float = 0.0
var running: bool = false
var finished: bool = false
var _spawn_xform: Transform3D
var _restarting: bool = true
var _splits: Array[float] = []
var _split_names: Array[String] = []
var _best_splits: Array[float] = []
var _finish_menu_delay: float = 1.2
var _finish_menu_timer: float = -1.0
var _finish_prev_best: float = 0.0
var _finish_prev_splits: Array[float] = []


func _ready() -> void:
	get_tree().paused = false
	_build_environment()
	var dev_args: Dictionary = DevHarness.parse_args(OS.get_cmdline_user_args())
	catalog = CourseCatalog.load_file()
	records.load_file()
	var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string(MENU_CONFIG))
	if cfg is Dictionary:
		_finish_menu_delay = float(cfg.get("finish_menu_delay_s", _finish_menu_delay))
	var entry: Dictionary = {}
	if not RunSession.course_id.is_empty():
		entry = catalog.find(RunSession.course_id)
	elif dev_args.has("course"):
		entry = catalog.find_by_path(String(dev_args["course"]))
		if entry.is_empty():
			var p: String = String(dev_args["course"])
			entry = {"id": p.get_file().get_basename(), "name": p.get_file().get_basename(), "path": p}
	else:
		entry = catalog.find("")
	course_id = entry["id"]
	var path: String = entry["path"]
	if path == "test_slope":
		level = TestSlope.new()
		add_child(level)
		course_name = entry["name"]
	else:
		course = CourseBuilder.new()
		course.name = "Course"
		add_child(course)
		course.load_course(path)
		level = course
		course_name = entry.get("name", course.course_name)
	best_time = records.best_time(course_id)
	_best_splits = records.best_splits(course_id)

	skater = Skater.new()
	add_child(skater)
	var spawn_point: Vector3 = level.get("spawn_point")
	var spawn_facing: Vector3 = level.get("spawn_facing")
	skater.global_position = spawn_point
	_spawn_xform = Transform3D(Basis.IDENTITY, spawn_point)
	skater.set_spawn(_spawn_xform, spawn_facing)
	skater.kill_height = float(level.get("lowest_y")) - 25.0
	skater.crashed.connect(_on_crashed)
	skater.respawned.connect(_on_respawned)
	if course:
		course.track(skater)
		course.checkpoint_reached.connect(_on_checkpoint)
		var drag := SurfaceDrag.new()
		drag.skater = skater
		drag.course = course
		add_child(drag)
		drag.slow_ground_changed.connect(func(n: String) -> void: hud.show_slow_ground(n))

	camera = ChaseCamera.new()
	camera.target = skater
	add_child(camera)
	camera.make_current()

	hud = Hud.new()
	add_child(hud)

	menu = RunMenu.new()
	add_child(menu)
	menu.open_maps = func() -> void: menu.show_maps(catalog, records, course_id)
	menu.restart_requested.connect(_on_menu_restart)
	menu.resume_requested.connect(_resume)
	menu.pause_requested.connect(_pause)
	menu.map_chosen.connect(_on_map_chosen)
	menu.quit_requested.connect(func() -> void: get_tree().quit())

	var finish: Area3D = level.get("finish")
	finish.body_entered.connect(_on_finish)
	skater.respawn()

	if not dev_args.is_empty():
		var dev := DevHarness.new()
		dev.skater = skater
		dev.course = course
		dev.args = dev_args
		add_child(dev)


func _physics_process(dt: float) -> void:
	if Input.is_action_just_pressed("restart"):
		restart_run()
	if _finish_menu_timer >= 0.0:
		_finish_menu_timer -= dt
		if _finish_menu_timer < 0.0 and finished:
			_show_finish_menu()
	if course and skater.state != Skater.State.CRASHED and course.is_out_of_bounds(skater.global_position):
		hud.flash("OUT OF BOUNDS", Color(1, 0.35, 0.3))
		skater.respawn()
	if not running and not finished and skater.get_speed() > 0.5:
		running = true
	if running:
		run_time += dt
	hud.show_run(run_time, skater.get_speed(), best_time)


func _on_crashed(reason: String) -> void:
	hud.flash("BAIL!  " + reason, Color(1, 0.35, 0.3))


## Back to the top with the clock reset (the restart button).
func restart_run() -> void:
	_restarting = true
	_finish_menu_timer = -1.0
	get_tree().paused = false
	if menu:
		menu.hide_menu()
	skater.set_spawn(_spawn_xform, level.get("spawn_facing"))
	if course:
		course.reset_progress()
	skater.respawn()


func _on_respawned() -> void:
	# A crash sends you to the last checkpoint with the clock still running
	# (game brief: checkpoint mode); a restart goes back to the top.
	if _restarting or finished:
		_restarting = false
		run_time = 0.0
		running = false
		finished = false
		_splits.clear()
		_split_names.clear()
		if course:
			skater.set_spawn(_spawn_xform, level.get("spawn_facing"))
			course.reset_progress()
	if camera:
		camera.snap()


func _on_checkpoint(index: int, gate_name: String, respawn: Transform3D) -> void:
	skater.set_spawn(Transform3D(Basis.IDENTITY, respawn.origin), -respawn.basis.z)
	if not running:
		return
	_splits.append(run_time)
	_split_names.append(gate_name)
	var text: String = "%s  %s" % [gate_name.to_upper(), Hud.format_time(run_time)]
	var color := Color(1, 1, 1)
	if index <= _best_splits.size():
		var delta: float = run_time - _best_splits[index - 1]
		text += "  (%s)" % Hud.format_delta(delta)
		color = Color(1, 0.5, 0.4) if delta >= 0.0 else Color(0.45, 1, 0.55)
	print("SPLIT ", index, " ", Hud.format_time(run_time))
	hud.flash(text, color, 2.0)


func _on_finish(body: Node3D) -> void:
	if body != skater or finished:
		return
	finished = true
	running = false
	skater.auto_brake = true
	_finish_prev_best = best_time
	_finish_prev_splits = _best_splits.duplicate()
	var pb: bool = records.submit(course_id, run_time, _splits)
	if pb:
		best_time = run_time
		_best_splits = _splits.duplicate()
		records.save_file()
	print("FINISH ", Hud.format_time(run_time))
	hud.flash(("NEW BEST  " if pb else "FINISH  ") + Hud.format_time(run_time), Color(0.4, 1, 0.5), _finish_menu_delay)
	_finish_menu_timer = _finish_menu_delay


func _show_finish_menu() -> void:
	menu.show_finish(course_name, run_time, _finish_prev_best, _splits, _finish_prev_splits, _split_names)


## Opens the pause menu mid-run (not at the finish, which has its own screen).
func _pause() -> void:
	if finished:
		return
	get_tree().paused = true
	menu.show_pause()


func _resume() -> void:
	menu.hide_menu()
	get_tree().paused = false
	skater.hold_until_released = true


func _on_menu_restart() -> void:
	restart_run()
	skater.hold_until_released = true


func _on_map_chosen(id: String) -> void:
	if id == course_id:
		_on_menu_restart()
		return
	RunSession.course_id = id
	get_tree().paused = false
	get_tree().reload_current_scene()


## Opens a menu panel by name ("finish", "pause", "maps"); for the dev harness.
func open_menu(which: String) -> void:
	match which:
		"pause":
			_pause()
		"maps":
			_pause()
			menu.open_maps.call()
		"finish":
			_show_finish_menu()


func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.35, 0.55, 0.85)
	sky_mat.sky_horizon_color = Color(0.75, 0.82, 0.9)
	sky_mat.ground_horizon_color = Color(0.75, 0.82, 0.9)
	sky_mat.ground_bottom_color = Color(0.4, 0.42, 0.45)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.78, 0.84, 0.92)
	env.fog_density = 0.002
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	add_child(sun)
