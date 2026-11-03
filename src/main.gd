extends Node3D
## Wires up the movement prototype: test slope, skater, camera, HUD,
## lighting, the run timer and restart.

var level: TestSlope
var skater: Skater
var camera: ChaseCamera
var hud: Hud

var run_time: float = 0.0
var best_time: float = 0.0
var running: bool = false
var finished: bool = false


func _ready() -> void:
	_build_environment()
	level = TestSlope.new()
	add_child(level)

	skater = Skater.new()
	add_child(skater)
	skater.global_position = level.spawn_point
	skater.set_spawn(Transform3D(Basis.IDENTITY, level.spawn_point), level.spawn_facing)
	skater.kill_height = level.lowest_y - 25.0
	skater.crashed.connect(_on_crashed)
	skater.respawned.connect(_on_respawned)

	camera = ChaseCamera.new()
	camera.target = skater
	add_child(camera)
	camera.make_current()

	hud = Hud.new()
	add_child(hud)

	level.finish.body_entered.connect(_on_finish)
	skater.respawn()

	var dev_args: Dictionary = DevHarness.parse_args(OS.get_cmdline_user_args())
	if not dev_args.is_empty():
		var dev := DevHarness.new()
		dev.skater = skater
		dev.args = dev_args
		add_child(dev)


func _physics_process(dt: float) -> void:
	if Input.is_action_just_pressed("restart"):
		skater.respawn()
	if not running and not finished and skater.get_speed() > 0.5:
		running = true
	if running:
		run_time += dt
	hud.show_run(run_time, skater.get_speed(), best_time)


func _on_crashed(reason: String) -> void:
	hud.flash("BAIL!  " + reason, Color(1, 0.35, 0.3))


func _on_respawned() -> void:
	run_time = 0.0
	running = false
	finished = false
	if camera:
		camera.snap()


func _on_finish(body: Node3D) -> void:
	if body != skater or finished:
		return
	finished = true
	running = false
	skater.auto_brake = true
	var pb: bool = best_time <= 0.0 or run_time < best_time
	if pb:
		best_time = run_time
	print("FINISH ", Hud.format_time(run_time))
	hud.flash(("NEW BEST  " if pb else "FINISH  ") + Hud.format_time(run_time), Color(0.4, 1, 0.5), 4.0)


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
