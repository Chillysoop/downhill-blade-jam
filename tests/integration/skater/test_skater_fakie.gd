extends SceneTree
## Integration test: riding and landing backwards (fakie). Run headless:
##   godot --headless --script res://tests/integration/skater/test_skater_fakie.gd
## Conner (2026-11-20): "skating backwards / landing backwards should work".

var _fails: int = 0
var _input: Dictionary = {"steer": 0.0, "forward": 0.0, "brake": 0.0, "jump": false}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await test_lands_a_drop_backwards()
	await test_forward_turns_you_round()
	print("SkaterFakie tests: %s" % ("PASS" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)


func check(cond: bool, name: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: ", name)


## A flat floor and a skater on it; returns [world, skater].
func _setup() -> Array:
	var world := Node3D.new()
	root.add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0, -0.5, 0)
	world.add_child(ground)
	var sk := Skater.new()
	world.add_child(sk)
	sk.waiting_for_start = false
	_input = {"steer": 0.0, "forward": 0.0, "brake": 0.0, "jump": false}
	sk.input_override = func() -> Dictionary: return _input
	return [world, sk]


func test_lands_a_drop_backwards() -> void:
	var w: Array = await _setup()
	var sk: Skater = w[1]
	# Facing +Z but flying toward -Z at 8 m/s, 1.5 m up: a 180 coming down.
	sk.global_position = Vector3(0, 1.5, 0)
	sk.heading = Vector3.BACK
	sk.velocity = Vector3(0, 0, -8)
	sk.state = Skater.State.AIR
	var bailed: bool = false
	sk.crashed.connect(func(_r: String) -> void: bailed = true)
	for i: int in 90:
		await physics_frame
	check(not bailed, "a backwards landing does not bail")
	check(sk.state == Skater.State.GROUNDED, "rolling after the landing")
	check(sk.fakie, "rolling away fakie")
	check(sk.get_speed() > 5.0, "keeps rolling (%.1f m/s)" % sk.get_speed())
	w[0].queue_free()
	await process_frame


func test_forward_turns_you_round() -> void:
	var w: Array = await _setup()
	var sk: Skater = w[1]
	sk.global_position = Vector3(0, 0.05, 0)
	for i: int in 20:
		await physics_frame
	sk.heading = Vector3.BACK
	sk.velocity = Vector3(0, 0, -6)
	for i: int in 10:
		await physics_frame
	check(sk.fakie, "rolling backwards is fakie")
	_input["forward"] = 1.0
	var frames: int = 0
	while (sk.fakie or sk.turning_around) and frames < 120:
		await physics_frame
		frames += 1
	var secs: float = frames / float(Engine.physics_ticks_per_second)
	check(secs < 0.5, "turned round in under half a second (%.2f s)" % secs)
	check(sk.heading.dot(Vector3.FORWARD) > 0.95, "now facing the way you roll")
	check(sk.get_speed() > 5.0, "kept the speed through the turn (%.1f m/s)" % sk.get_speed())
	w[0].queue_free()
	await process_frame
