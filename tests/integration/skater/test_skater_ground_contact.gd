extends SceneTree
## Integration test: the skater keeps ground contact while rolling or carving
## uphill on a slope. Run headless:
##   godot --headless --script res://tests/integration/skater/test_skater_ground_contact.gd
## Regression for 2026-11-19: moving up a slope, move_and_slide skipped the
## floor snap (velocity pointed up), so the skater flickered into the air every
## other frame and lost steering, pushes and grip.

const SLOPE_DEG: float = 3.0

var _fails: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _case("rolling straight uphill", Vector3(0, 0, -1), 0.0, 4.0, 0.0)
	await _case("carving uphill", Vector3(1, 0, -0.3).normalized(), 1.0, 4.0, 0.0)
	await _case("pivoting slowly across the slope", Vector3(1, 0, 0), -1.0, 2.0, 1.0)
	print("SkaterGroundContact tests: %s" % ("PASS" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)


## Puts a skater on a slope (rising toward -Z) moving along [param dir] at
## [param speed] m/s with [param steer] and [param fwd] held, and counts physics frames spent airborne.
func _case(name: String, dir: Vector3, steer: float, speed: float, fwd: float) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	shape.shape = box
	ground.add_child(shape)
	ground.rotation = Vector3(deg_to_rad(SLOPE_DEG), 0, 0)
	ground.position = Vector3(0, -0.5, 0)
	world.add_child(ground)

	var sk := Skater.new()
	world.add_child(sk)
	sk.global_position = Vector3(0, 0.05, 0)
	sk.waiting_for_start = false
	sk.input_override = func() -> Dictionary:
		return {"steer": steer, "forward": fwd, "brake": 0.0, "jump": false}
	# Settle onto the ground.
	for i: int in 30:
		await physics_frame
	var n: Vector3 = sk.ground_normal
	var d: Vector3 = (dir - n * dir.dot(n)).normalized()
	sk.heading = d
	sk.velocity = d * speed
	var air: int = 0
	for i: int in 60:
		await physics_frame
		if sk.state != Skater.State.GROUNDED:
			air += 1
	check(air == 0, "%s keeps the wheels down (%d of 60 frames airborne)" % [name, air])
	world.queue_free()
	await process_frame


func check(cond: bool, name: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: ", name)
