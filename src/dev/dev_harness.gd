class_name DevHarness
extends Node
## Developer harness driven by command-line user args (after "--"):
##   --autopilot=<lane_x>   hold forward and steer toward a lane across the slope
##   --hops=<interval>      tap jump every <interval> seconds during autopilot
##   --telemetry            print time, position, speed and state twice a second
##   --shots=<t1,t2,...>    save screenshots at those times (seconds)
##   --shot-dir=<path>      where screenshots go (default user://shots)
##   --hops-after=<s>       only start hopping after <s> seconds
##   --brake-at=<s>         during autopilot, let go of forward and brake from <s> seconds
##   --steer=<v>            during autopilot, hold this steer (-1..1) instead of lane keeping
##   --quit-after=<s>       quit after <s> seconds
##   --course=<path|test_slope>  load another course (read by main.gd)
##   --route=<name>         autopilot follows a named course route (tucks, steers)
##   --start-at=<x,z>       start the skater at that ground spot instead
##   --overview=<x,y,z,tx,ty,tz>  fixed camera at x,y,z looking at tx,ty,tz
##   --menu=<finish|pause|maps>  open that menu panel at --menu-at seconds
##   --menu-at=<s>          when to open --menu (default 2)
##   --pick-map=<id>        at --menu-at, pick that map as map select would
## Used for automated simulation runs and screenshot evidence.

var skater: Skater
## The course, when the run is on one (for routes and start spots).
var course: CourseBuilder
var args: Dictionary = {}
var _route := PackedVector2Array()
var _route_i: int = 0
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
			if args.has("steer"):
				steer = float(args["steer"])
			var jump: bool = _jump_held > 0.0
			var braking: bool = args.has("brake-at") and _t >= float(args["brake-at"])
			return {"steer": steer, "forward": 0.0 if braking else 1.0,
				"brake": 1.0 if braking else 0.0, "jump": jump}
	if args.has("route") and course != null:
		_route = CourseMath.sample_spline(course.routes.get(String(args["route"]), []), 4.0)
		skater.input_override = _route_input
	if args.has("start-at") and course != null:
		var xz: PackedStringArray = String(args["start-at"]).split(",")
		var p := Vector2(float(xz[0]), float(xz[1]))
		var pos := Vector3(p.x, course.terrain.height_at(p.x, p.y) + 0.4, p.y)
		var ahead := Vector3(course.terrain.axis_at(p.y - 20.0), pos.y, p.y - 20.0)
		skater.set_spawn(Transform3D(Basis.IDENTITY, pos), (ahead - pos) * Vector3(1, 0, 1))
		skater.respawn()
		for i: int in _route.size():
			if _route[i].y < p.y:
				_route_i = i
				break
	if args.has("overview"):
		var v: PackedStringArray = String(args["overview"]).split(",")
		var cam := Camera3D.new()
		cam.far = 6000.0
		cam.fov = 60.0
		add_child(cam)
		cam.global_position = Vector3(float(v[0]), float(v[1]), float(v[2]))
		cam.look_at(Vector3(float(v[3]), float(v[4]), float(v[5])), Vector3.UP)
		cam.make_current()
	if args.has("shots"):
		for s: String in String(args["shots"]).split(","):
			_shots.append(float(s))
	_shot_dir = args.get("shot-dir", _shot_dir)
	skater.crashed.connect(func(r: String) -> void: print("[t=%.2f] CRASH: %s" % [_t, r]))
	skater.landed.connect(func(at: float) -> void:
		if args.has("telemetry"):
			print("[t=%.2f] landed after %.2fs air" % [_t, at]))


func _route_input() -> Dictionary:
	var p := Vector2(skater.global_position.x, skater.global_position.z)
	# Advance along the route; aim at a point ~18 m ahead.
	while _route_i < _route.size() - 1 and p.distance_to(_route[_route_i]) < 18.0:
		_route_i += 1
	while _route_i < _route.size() - 1 and _route[_route_i].y > p.y + 2.0:
		_route_i += 1
	var target: Vector2 = _route[mini(_route_i, _route.size() - 1)]
	var to: Vector2 = (target - p).normalized()
	var h := Vector2(skater.heading.x, skater.heading.z).normalized()
	var err: float = h.angle_to(to)
	var steer: float = 0.0 if absf(err) < 0.04 else clampf(err * 1.2, -1.0, 1.0)
	var jump: bool = _jump_held > 0.0
	var fwd: float = 1.0 if absf(err) < 0.25 else 0.0
	return {"steer": steer, "forward": fwd, "brake": 0.0, "jump": jump}


func _physics_process(dt: float) -> void:
	_t += dt
	_jump_held = maxf(_jump_held - dt, 0.0)
	var hop_every: float = float(args.get("hops", "0"))
	if hop_every > 0.0 and _t >= _next_hop and _t >= float(args.get("hops-after", "0")):
		_jump_held = 0.08
		_next_hop += hop_every
	if args.has("telemetry") and _t >= _next_tel:
		_next_tel += 0.5
		var p: Vector3 = skater.global_position
		var mode: String = "slide" if skater.sliding else ("tuck" if skater.tucking else ("stride" if skater.striding else ""))
		print("t=%5.2f pos=(%6.1f,%6.1f,%7.1f) speed=%5.1f km/h state=%s lean=%3.0f %s" % [
			_t, p.x, p.y, p.z, skater.get_speed() * 3.6, Skater.State.keys()[skater.state],
			rad_to_deg(skater.lean), mode])
	if args.has("menu") and _t >= float(args.get("menu-at", "2")):
		var which: String = String(args["menu"])
		args.erase("menu")
		get_parent().call("open_menu", which)
	if args.has("pick-map") and _t >= float(args.get("menu-at", "2")):
		var id: String = String(args["pick-map"])
		args.erase("pick-map")
		if RunSession.course_id != id:
			get_parent().call("_on_map_chosen", id)
			return
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
