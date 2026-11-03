class_name DevHarness
extends Node
## Developer harness driven by command-line user args (after "--"):
##   --autopilot=<lane_x>   hold forward and steer toward a lane across the slope
##   --hops=<interval>      tap jump every <interval> seconds during autopilot
##   --telemetry            print time, position, speed and state twice a second
##   --shots=<t1,t2,...>    save screenshots at those times (seconds)
##   --shot-dir=<path>      where screenshots go (default user://shots)
##   --quit-after=<s>       quit after <s> seconds
## Used for automated simulation runs and screenshot evidence.

var skater: Skater
var args: Dictionary = {}
var _t: float = 0.0
var _next_tel: float = 0.0
var _shots: Array[float] = []
var _shot_dir: String = "user://shots"
var _jump_held: float = 0.0
var _next_hop: float = 0.0


## Parses the user args into a Dictionary of key -> value strings.
static func parse_args(raw: PackedStringArray) -> Dictionary:
	var out: Dictionary = {}
	for a: String in raw:
		if not a.begins_with("--"):
			continue
		var kv: PackedStringArray = a.substr(2).split("=", true, 1)
		out[kv[0]] = kv[1] if kv.size() > 1 else "1"
	return out


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if args.has("autopilot"):
		var lane: float = float(args["autopilot"])
		var hop_every: float = float(args.get("hops", "0"))
		_next_hop = hop_every
		skater.input_override = func() -> Dictionary:
			var right: Vector3 = skater.heading.cross(Vector3.UP).normalized()
			var lateral_err: float = lane - skater.global_position.x
			var flat_h: Vector3 = (skater.heading * Vector3(1, 0, 1)).normalized()
			var heading_err: float = flat_h.signed_angle_to(Vector3.FORWARD, Vector3.UP)
			var steer: float = clampf(lateral_err * 0.08 * signf(right.x) - heading_err * 1.5, -1.0, 1.0)
			var jump: bool = _jump_held > 0.0
			return {"steer": steer, "forward": 1.0, "brake": 0.0, "jump": jump}
	if args.has("shots"):
		for s: String in String(args["shots"]).split(","):
			_shots.append(float(s))
	_shot_dir = args.get("shot-dir", _shot_dir)
	skater.crashed.connect(func(r: String) -> void: print("[t=%.2f] CRASH: %s" % [_t, r]))
	skater.landed.connect(func(at: float) -> void:
		if args.has("telemetry"):
			print("[t=%.2f] landed after %.2fs air" % [_t, at]))


func _physics_process(dt: float) -> void:
	_t += dt
	_jump_held = maxf(_jump_held - dt, 0.0)
	var hop_every: float = float(args.get("hops", "0"))
	if hop_every > 0.0 and _t >= _next_hop:
		_jump_held = 0.08
		_next_hop += hop_every
	if args.has("telemetry") and _t >= _next_tel:
		_next_tel += 0.5
		var p: Vector3 = skater.global_position
		print("t=%5.2f pos=(%6.1f,%6.1f,%7.1f) speed=%5.1f km/h state=%s" % [
			_t, p.x, p.y, p.z, skater.get_speed() * 3.6, Skater.State.keys()[skater.state]])
	if not _shots.is_empty() and _t >= _shots[0]:
		_shots.pop_front()
		_save_shot()
	if args.has("quit-after") and _t >= float(args["quit-after"]):
		get_tree().quit()


func _save_shot() -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_shot_dir)
	var path: String = "%s/shot_%05.2f.png" % [_shot_dir, _t]
	img.save_png(path)
	print("saved ", path)
