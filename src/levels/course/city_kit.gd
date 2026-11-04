class_name CityKit
extends Node3D
## City pieces of the shared level kit, used by street courses such as
## Hillcrest Drop (design/levels/hillcrest-drop.md): merged buildings and
## parked cars ("solids"), pedestrians ("crowd"), moving cars and cable cars
## ("traffic") and road paint ("paint"). Schema: docs/course-data-schema.md.
## Hitting a person or a moving vehicle is a bail, reported through
## [signal hazard_hit] so the run rules stay in main.gd.

## Emitted when the skater runs into a hazard hard enough to bail.
signal hazard_hit(reason: String)

## The kit this belongs to (terrain, materials).
var kit: CourseKit
## Course clock in seconds; traffic positions are a pure function of it, so a
## restart replays the same traffic.
var clock: float = 0.0

var _movers: Array[Dictionary] = []
var _building_mat: ShaderMaterial
var _plain_mat: StandardMaterial3D
var _paint_mat: StandardMaterial3D

const PED_SHIRTS: Array[String] = ["#d9534f", "#f0ad4e", "#5bc0de", "#5cb85c", "#9b59b6", "#ecf0f1", "#34495e", "#e67e22", "#16a085", "#f7dc6f"]
const PED_SKIN: Array[String] = ["#f1c27d", "#e0ac69", "#c68642", "#8d5524", "#ffdbac"]


## Builds one city feature from its data entry.
func place(f: Dictionary) -> void:
	match String(f["type"]):
		"solids":
			solids(f)
		"crowd":
			crowd(f)
		"traffic":
			traffic(f)
		"paint":
			paint(f)


## Moves the traffic to where it is at course time [param t].
func advance(t: float) -> void:
	clock = t
	for m: Dictionary in _movers:
		if m.get("pace", false):
			_place_pacer(m)
			continue
		var length: float = m["length"]
		var s: float = fposmod(float(m["offset"]) + float(m["speed"]) * t, length)
		var a: Vector2 = m["a"]
		var b: Vector2 = m["b"]
		var dir: Vector2 = (b - a) / length
		var p: Vector2 = a + dir * s
		var half: float = float(m["half_len"])
		var yf: float = kit.terrain.height_at(p.x + dir.x * half, p.y + dir.y * half)
		var yb: float = kit.terrain.height_at(p.x - dir.x * half, p.y - dir.y * half)
		var fwd := Vector3(dir.x, (yf - yb) / (2.0 * half), dir.y).normalized()
		var right: Vector3 = fwd.cross(Vector3.UP).normalized()
		var up: Vector3 = right.cross(fwd).normalized()
		var body: AnimatableBody3D = m["body"]
		body.global_transform = Transform3D(Basis(right, up, -fwd), Vector3(p.x, (yf + yb) * 0.5, p.y))


## Many boxes merged into one mesh and one static body: buildings (stepped
## down the hill, windows drawn by the building shader) or plain props such as
## parked cars. Item keys: "p" [x, z], "s" [across, height, along], "yaw"
## (degrees, 0 = along −Z), "c" colour, optional "top" (absolute roof height),
## "lift". Feature "style": "building" sinks each box to the lowest ground
## under it and stands it [code]height[/code] above the highest; "prop" sits
## it on the ground at its centre and tilts it with the slope.
func solids(f: Dictionary) -> void:
	var building: bool = String(f.get("style", "building")) == "building"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := StaticBody3D.new()
	body.name = String(f.get("id", "Solids"))
	add_child(body)
	var collide: bool = bool(f.get("collide", true))
	for it: Dictionary in f["items"]:
		var p: Vector2 = CourseKit._v2(it["p"])
		var size: Vector3 = CourseKit._v3(it["s"])
		var yaw: float = deg_to_rad(float(it.get("yaw", 0.0)))
		var fwd2 := Vector2(sin(yaw), -cos(yaw))
		var right2 := Vector2(-fwd2.y, fwd2.x)
		var col: Color = Color.html(String(it.get("c", "#cccccc")))
		var lift: float = float(it.get("lift", 0.0))
		var xform: Transform3D
		var box_size: Vector3 = size
		if building:
			var lo: float = INF
			var hi: float = -INF
			for sx: float in [-0.5, 0.0, 0.5]:
				for sz: float in [-0.5, 0.0, 0.5]:
					var q: Vector2 = p + right2 * size.x * sx + fwd2 * size.z * sz
					var g: float = kit.terrain.height_at(q.x, q.y)
					lo = minf(lo, g)
					hi = maxf(hi, g)
			var bottom: float = lo - 2.0 + lift
			var top: float = float(it["top"]) if it.has("top") else hi + size.y
			box_size = Vector3(size.x, maxf(top - bottom, 0.5), size.z)
			var fwd := Vector3(fwd2.x, 0.0, fwd2.y)
			var basis := Basis(fwd.cross(Vector3.UP).normalized(), Vector3.UP, -fwd)
			xform = Transform3D(basis, Vector3(p.x, bottom + box_size.y * 0.5, p.y))
		else:
			var hf: float = kit.terrain.height_at(p.x + fwd2.x * size.z * 0.5, p.y + fwd2.y * size.z * 0.5)
			var hb: float = kit.terrain.height_at(p.x - fwd2.x * size.z * 0.5, p.y - fwd2.y * size.z * 0.5)
			var fwd := Vector3(fwd2.x, (hf - hb) / maxf(size.z, 0.1), fwd2.y).normalized()
			var right: Vector3 = fwd.cross(Vector3.UP).normalized()
			var up: Vector3 = right.cross(fwd).normalized()
			var base := Vector3(p.x, (hf + hb) * 0.5, p.y)
			xform = Transform3D(Basis(right, up, -fwd), base + up * (lift + size.y * 0.5))
		_append_box(st, xform, box_size, col)
		if collide:
			var shape := BoxShape3D.new()
			shape.size = box_size
			var cs := CollisionShape3D.new()
			cs.shape = shape
			cs.transform = xform
			body.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _get_building_mat() if building else _get_plain_mat()
	body.add_child(mi)


## People standing and walking along the line [param f].a → .b. Standing
## people are solid; everyone is a hazard above "min_speed" (default 3 m/s).
## Keys: "count", "spread" (metres either side of the line), "seed",
## "walkers" (how many pace back and forth), "walk_speed".
func crowd(f: Dictionary) -> void:
	var a: Vector2 = CourseKit._v2(f["a"])
	var b: Vector2 = CourseKit._v2(f["b"])
	var count: int = int(f.get("count", 6))
	var walkers: int = int(f.get("walkers", 0))
	var spread: float = float(f.get("spread", 1.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f.get("seed", 1))
	var min_speed: float = float(f.get("min_speed", 3.0))
	var dir: Vector2 = (b - a).normalized()
	var side := Vector2(-dir.y, dir.x)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := StaticBody3D.new()
	body.name = String(f.get("id", "Crowd"))
	add_child(body)
	var area := _hazard_area(body, "Hit a pedestrian", min_speed)
	for i: int in count:
		var p: Vector2 = a.lerp(b, rng.randf()) + side * rng.randf_range(-spread, spread)
		var y: float = kit.terrain.height_at(p.x, p.y)
		var yaw: float = rng.randf() * TAU
		var xform := Transform3D(Basis(Vector3.UP, yaw), Vector3(p.x, y, p.y))
		_append_person(st, xform, rng)
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.3
		cap.height = 1.75
		cs.shape = cap
		cs.position = Vector3(p.x, y + 0.875, p.y)
		body.add_child(cs)
		var hs := CollisionShape3D.new()
		var hcap := CapsuleShape3D.new()
		hcap.radius = 0.45
		hcap.height = 1.8
		hs.shape = hcap
		hs.position = cs.position
		area.add_child(hs)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _get_plain_mat()
	body.add_child(mi)
	for i: int in walkers:
		var w := AnimatableBody3D.new()
		w.name = "Walker%d" % i
		add_child(w)
		var wst := SurfaceTool.new()
		wst.begin(Mesh.PRIMITIVE_TRIANGLES)
		_append_person(wst, Transform3D.IDENTITY, rng)
		var wmi := MeshInstance3D.new()
		wmi.mesh = wst.commit()
		wmi.material_override = _get_plain_mat()
		w.add_child(wmi)
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.3
		cap.height = 1.75
		cs.shape = cap
		cs.position = Vector3(0, 0.875, 0)
		w.add_child(cs)
		var warea := _hazard_area(w, "Hit a pedestrian", min_speed)
		var hs := CollisionShape3D.new()
		var hcap := CapsuleShape3D.new()
		hcap.radius = 0.45
		hcap.height = 1.8
		hs.shape = hcap
		hs.position = cs.position
		warea.add_child(hs)
		var off: Vector2 = side * rng.randf_range(-spread, spread)
		# Walkers pace a→b→a: a loop twice the line's length.
		var length: float = a.distance_to(b)
		_movers.append({"body": w, "a": a + off, "b": b + off, "length": length,
			"speed": float(f.get("walk_speed", 1.3)) * rng.randf_range(0.8, 1.2),
			"offset": rng.randf() * length * 2.0, "half_len": 0.3, "pace": true})
	_fix_pacers()


## Vehicles driving [param f].a → .b at "speed" m/s, "count" of them evenly
## spaced, wrapping back to a. "style": "car" or "cable_car". Solid, and any
## touch above "min_speed" (default 0) is a bail.
func traffic(f: Dictionary) -> void:
	var a: Vector2 = CourseKit._v2(f["a"])
	var b: Vector2 = CourseKit._v2(f["b"])
	var count: int = int(f.get("count", 2))
	var length: float = a.distance_to(b)
	var cable: bool = String(f.get("style", "car")) == "cable_car"
	var size: Vector3 = Vector3(2.6, 3.3, 9.0) if cable else Vector3(1.9, 1.5, 4.6)
	var colors: Array = f.get("colors", ["#c0392b", "#2c3e50", "#ecf0f1", "#2980b9", "#f1c40f"])
	var reason: String = "Hit by the cable car" if cable else "Hit by a car"
	for i: int in count:
		var body := AnimatableBody3D.new()
		body.name = "%s%d" % [String(f.get("id", "Traffic")), i]
		body.sync_to_physics = false
		add_child(body)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var col: Color = Color.html(String(colors[i % colors.size()]))
		if cable:
			_append_box(st, Transform3D(Basis.IDENTITY, Vector3(0, 0.9, 0)), Vector3(2.6, 1.4, 9.0), Color.html("#b03a2e"))
			_append_box(st, Transform3D(Basis.IDENTITY, Vector3(0, 2.2, 0)), Vector3(2.5, 1.2, 8.6), Color.html("#f5e6c8"))
			_append_box(st, Transform3D(Basis.IDENTITY, Vector3(0, 3.0, 0)), Vector3(2.7, 0.35, 9.2), Color.html("#7b241c"))
		else:
			_append_box(st, Transform3D(Basis.IDENTITY, Vector3(0, 0.55, 0)), Vector3(1.9, 0.8, 4.6), col)
			_append_box(st, Transform3D(Basis.IDENTITY, Vector3(0, 1.2, 0.2)), Vector3(1.7, 0.6, 2.4), col.darkened(0.35))
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = _get_plain_mat()
		body.add_child(mi)
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		cs.position = Vector3(0, size.y * 0.5, 0)
		body.add_child(cs)
		var area := _hazard_area(body, reason, float(f.get("min_speed", 0.0)))
		var hs := CollisionShape3D.new()
		var hshape := BoxShape3D.new()
		hshape.size = size + Vector3(0.5, 0.2, 0.5)
		hs.shape = hshape
		hs.position = cs.position
		area.add_child(hs)
		_movers.append({"body": body, "a": a, "b": b, "length": length, "speed": float(f.get("speed", 8.0)),
			"offset": float(f.get("phase", 0.0)) + length * float(i) / float(count), "half_len": size.z * 0.5})
	advance(clock)


## Flat painted strips on the ground (lane lines, crosswalks, curb paint).
## "segs": [[x1, z1, x2, z2], ...], "width", "c" colour, "lift" (default 0.03).
func paint(f: Dictionary) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var col: Color = Color.html(String(f.get("c", "#f2f2f2")))
	var width: float = float(f.get("width", 0.15))
	var lift: float = float(f.get("lift", 0.03))
	for s: Array in f["segs"]:
		var a := Vector2(float(s[0]), float(s[1]))
		var b := Vector2(float(s[2]), float(s[3]))
		var dir: Vector2 = (b - a).normalized()
		var side := Vector2(-dir.y, dir.x) * width * 0.5
		var pa := Vector3(a.x, kit.terrain.height_at(a.x, a.y) + lift, a.y)
		var pb := Vector3(b.x, kit.terrain.height_at(b.x, b.y) + lift, b.y)
		var o := Vector3(side.x, 0.0, side.y)
		st.set_color(col)
		st.set_normal(Vector3.UP)
		for v: Vector3 in [pa - o, pb - o, pa + o, pa + o, pb - o, pb + o]:
			st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	if _paint_mat == null:
		_paint_mat = StandardMaterial3D.new()
		_paint_mat.vertex_color_use_as_albedo = true
		_paint_mat.roughness = 0.7
		_paint_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = _paint_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


# Walkers bounce between their ends instead of wrapping.
func _fix_pacers() -> void:
	for m: Dictionary in _movers:
		if m.get("pace", false):
			_place_pacer(m)


func _place_pacer(m: Dictionary) -> void:
	var length: float = m["length"]
	var s: float = fposmod(float(m["offset"]) + float(m["speed"]) * clock, length * 2.0)
	var back: bool = s > length
	var d: float = length * 2.0 - s if back else s
	var a: Vector2 = m["a"]
	var b: Vector2 = m["b"]
	var p: Vector2 = a.lerp(b, d / maxf(length, 0.01))
	var dir: Vector2 = (a - b if back else b - a).normalized()
	var body: AnimatableBody3D = m["body"]
	var y: float = kit.terrain.height_at(p.x, p.y)
	body.global_transform = Transform3D(Basis.looking_at(Vector3(dir.x, 0, dir.y), Vector3.UP), Vector3(p.x, y, p.y))


func _hazard_area(parent: Node3D, reason: String, min_speed: float) -> Area3D:
	var area := Area3D.new()
	area.monitorable = false
	parent.add_child(area)
	area.body_entered.connect(func(b: Node3D) -> void:
		var sk := b as Skater
		if sk != null and clock > 0.25 and sk.state != Skater.State.CRASHED and not sk.waiting_for_start and sk.get_speed() > min_speed:
			hazard_hit.emit(reason))
	if parent is StaticBody3D:
		# Merged crowds: the area's shapes are placed in world space.
		area.top_level = true
		area.global_transform = Transform3D.IDENTITY
	return area


func _append_person(st: SurfaceTool, xform: Transform3D, rng: RandomNumberGenerator) -> void:
	var shirt: Color = Color.html(PED_SHIRTS[rng.randi() % PED_SHIRTS.size()])
	var skin: Color = Color.html(PED_SKIN[rng.randi() % PED_SKIN.size()])
	var tall: float = rng.randf_range(0.9, 1.08)
	_append_box(st, xform * Transform3D(Basis.IDENTITY, Vector3(0, 0.42 * tall, 0)), Vector3(0.38, 0.84 * tall, 0.24), Color(0.15, 0.17, 0.22))
	_append_box(st, xform * Transform3D(Basis.IDENTITY, Vector3(0, 1.12 * tall, 0)), Vector3(0.48, 0.6 * tall, 0.28), shirt)
	_append_box(st, xform * Transform3D(Basis.IDENTITY, Vector3(0, 1.58 * tall, 0)), Vector3(0.24, 0.28, 0.26), skin)


## Adds a box (centre and orientation from [param xform]) to a SurfaceTool mesh.
func _append_box(st: SurfaceTool, xform: Transform3D, size: Vector3, col: Color) -> void:
	var h: Vector3 = size * 0.5
	var faces: Array = [
		[Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)],
		[Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)],
		[Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0)],
		[Vector3(0, -1, 0), Vector3(0, 0, -1), Vector3(1, 0, 0)],
		[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
		[Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)],
	]
	st.set_color(col)
	for fc: Array in faces:
		var n: Vector3 = fc[0]
		var u: Vector3 = fc[1]
		var v: Vector3 = fc[2]
		var c: Vector3 = n * h
		var hu: Vector3 = u * h
		var hv: Vector3 = v * h
		var p0: Vector3 = xform * (c - hu - hv)
		var p1: Vector3 = xform * (c + hu - hv)
		var p2: Vector3 = xform * (c + hu + hv)
		var p3: Vector3 = xform * (c - hu + hv)
		var wn: Vector3 = (xform.basis * n).normalized()
		st.set_normal(wn)
		# Wind so the face points along n (counter-clockwise seen from outside
		# in Godot's clockwise-front convention).
		for q: Vector3 in [p0, p2, p1, p0, p3, p2]:
			st.add_vertex(q)


func _get_building_mat() -> ShaderMaterial:
	if _building_mat == null:
		_building_mat = ShaderMaterial.new()
		_building_mat.shader = load("res://src/levels/course/building.gdshader")
	return _building_mat


func _get_plain_mat() -> StandardMaterial3D:
	if _plain_mat == null:
		_plain_mat = StandardMaterial3D.new()
		_plain_mat.vertex_color_use_as_albedo = true
		_plain_mat.roughness = 0.8
	return _plain_mat
