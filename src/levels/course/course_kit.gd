class_name CourseKit
extends Node3D
## The shared level kit: every placed course feature (ramps, kickers, stairs,
## decks, rails, rocks, trees, markers, landmarks) built from simple primitives
## that sit on a CourseTerrain. Each course lists its features as data; this
## node turns each entry into geometry. See docs/course-data-schema.md and
## design/levels/copperline-mountain.md §0.2 (Shared Level Kit).

## The ground the features sit on.
var terrain: CourseTerrain
var _materials: Dictionary = {}
var _city: CityKit
## Colours by material kind. Shared colour language (§2.12): yellow = skip
## takeoff, red = hazard, green/white = checkpoint.
var colors: Dictionary = {
	"concrete": Color(0.74, 0.72, 0.69), "ledge": Color(0.78, 0.77, 0.74),
	"skip": Color(0.98, 0.82, 0.18), "hazard": Color(0.85, 0.22, 0.18),
	"boulder": Color(0.42, 0.36, 0.35), "rock": Color(0.36, 0.36, 0.39),
	"rail": Color(0.62, 0.66, 0.72), "wood": Color(0.45, 0.32, 0.22),
	"rust": Color(0.72, 0.36, 0.16), "blue": Color(0.18, 0.42, 0.9),
	"teal": Color(0.1, 0.7, 0.68), "green": Color(0.2, 0.82, 0.35),
	"white": Color(0.95, 0.95, 0.95), "slate": Color(0.32, 0.36, 0.42),
	"wall": Color(0.82, 0.78, 0.7), "trunk": Color(0.42, 0.3, 0.2),
	"leaves": Color(0.2, 0.42, 0.26), "metal": Color(0.5, 0.52, 0.56),
	"yellow": Color(0.98, 0.82, 0.18),
}


## Builds one feature from its data entry. Unknown types are reported, not fatal.
func place(f: Dictionary) -> void:
	match String(f["type"]):
		"ramp":
			ramp(_v2(f["a"]), _v2(f["b"]), float(f.get("lift_a", 0.0)), float(f.get("lift_b", 0.0)),
				float(f["width"]), float(f.get("thickness", -1.0)), f.get("kind", "concrete"), f.get("plane", null))
		"kicker":
			var p: Vector2 = _v2(f["at"])
			var d: Vector2 = _heading(f, p)
			var plane: Variant = f.get("plane", null)
			ramp(p, p + d * float(f["length"]), -0.15, float(f["height"]), float(f["width"]), -1.0,
				f.get("kind", "concrete"), plane)
		"stairs":
			stairs(f)
		"deck":
			deck(f)
		"box":
			var p: Vector2 = _v2(f["at"])
			box(p, _heading(f, p), _v3(f["size"]), float(f.get("lift", 0.0)), f.get("kind", "concrete"),
				bool(f.get("collide", true)))
		"cylinder":
			cylinder(_v2(f["at"]), float(f["radius"]), float(f["height"]), float(f.get("lift", 0.0)),
				f.get("kind", "rock"), bool(f.get("collide", true)), float(f.get("top_radius", -1.0)))
		"rail":
			rail(_v2(f["a"]), _v2(f["b"]), float(f.get("lift", 0.6)), f.get("kind", "rail"))
		"boulders":
			boulders(f)
		"trees":
			trees(f)
		"markers":
			markers(f)
		"chairlift":
			chairlift(f)
		"solids", "crowd", "traffic", "paint":
			city().place(f)
		_:
			push_warning("CourseKit: unknown feature type '%s'" % f["type"])


## The city pieces (buildings, crowds, traffic, road paint), made on first use.
func city() -> CityKit:
	if _city == null:
		_city = CityKit.new()
		_city.name = "City"
		_city.kit = self
		add_child(_city)
	return _city


## Ground point at world (x, z) plus [param lift] metres.
func ground(p: Vector2, lift: float = 0.0) -> Vector3:
	return Vector3(p.x, terrain.height_at(p.x, p.y) + lift, p.y)


## A solid slab whose top runs from [param a] (lifted [param lift_a] above the
## ground) to [param b] (lifted [param lift_b]). Kickers, landing banks, decks
## and drop-ins are all ramps. [param plane] (optional [x, z] origin) measures
## lifts from a flat plane through that point's ground instead of each end.
func ramp(a: Vector2, b: Vector2, lift_a: float, lift_b: float, width: float, thickness: float, kind: String, plane: Variant = null) -> StaticBody3D:
	var ya: float = terrain.height_at(a.x, a.y)
	var yb: float = terrain.height_at(b.x, b.y)
	if plane is String and plane == "abs":
		# Lifts are absolute heights (city stairs and decks built from data).
		ya = 0.0
		yb = 0.0
	elif plane != null:
		ya = _plane_y(_v2(plane), a)
		yb = _plane_y(_v2(plane), b)
	var ta := Vector3(a.x, ya + lift_a, a.y)
	var tb := Vector3(b.x, yb + lift_b, b.y)
	var fwd: Vector3 = (tb - ta).normalized()
	var right: Vector3 = fwd.cross(Vector3.UP).normalized()
	var up: Vector3 = right.cross(fwd).normalized()
	var thick: float = thickness
	if thick <= 0.0:
		thick = maxf(absf(lift_a), absf(lift_b)) + 3.0
	var length: float = ta.distance_to(tb)
	var basis := Basis(right, up, -fwd)
	var center: Vector3 = (ta + tb) * 0.5 - up * thick * 0.5
	return _static_box(center, basis, Vector3(width, thick, length), kind, true)


## Flight of [param count] step-ups (rise, tread) leading up onto an island or
## deck; each step top is measured from a plane through the first step's
## ground that follows the base slope, so the last step meets a deck at
## count * rise.
func stairs(f: Dictionary) -> void:
	var p: Vector2 = _v2(f["at"])
	var d: Vector2 = _heading(f, p)
	var count: int = int(f["count"])
	var rise: float = float(f["rise"])
	var tread: float = float(f["tread"])
	var width: float = float(f["width"])
	var extra: float = float(f.get("overlap", 6.0))
	var end: Vector2 = p + d * (count * tread + extra)
	for i: int in count:
		var a: Vector2 = p + d * (i * tread)
		var lift: float = rise * (i + 1)
		var kind: String = "ledge" if i % 2 == 0 else "concrete"
		ramp(a, end, lift, lift, width, lift + 6.0, kind, [p.x, p.y])


## Elevated deck (trestle, bridge) on pillars, from [param f].a to .b, lifted
## above a plane through the start's ground. Off the side is a long fall.
func deck(f: Dictionary) -> void:
	var a: Vector2 = _v2(f["a"])
	var b: Vector2 = _v2(f["b"])
	var lift_a: float = float(f["lift_a"])
	var drop: float = float(f.get("drop", 0.0))
	var ya: float = terrain.height_at(a.x, a.y) + lift_a
	var yb: float = ya - drop
	var lift_b: float = yb - terrain.height_at(b.x, b.y)
	var width: float = float(f["width"])
	ramp(a, b, lift_a, lift_b, width, 0.8, f.get("kind", "wood"))
	var spacing: float = float(f.get("pillar_spacing", 14.0))
	var n: int = int(a.distance_to(b) / spacing)
	for i: int in range(1, n):
		var t: float = float(i) / n
		var q: Vector2 = a.lerp(b, t)
		var top: float = lerpf(ya, yb, t) - 0.8
		var gy: float = terrain.height_at(q.x, q.y)
		var h: float = top - gy
		if h > 0.5:
			for side: float in [-1.0, 1.0]:
				var dir: Vector2 = (b - a).normalized()
				var off: Vector2 = Vector2(-dir.y, dir.x) * side * (width * 0.5 - 0.3)
				_static_box(Vector3(q.x + off.x, gy + h * 0.5, q.y + off.y), Basis.IDENTITY,
					Vector3(0.5, h, 0.5), "wood", true)
	for edge: Dictionary in f.get("rails", []):
		var side: float = float(edge["side"])
		var dir: Vector2 = (b - a).normalized()
		var off: Vector2 = Vector2(-dir.y, dir.x) * side * (width * 0.5 - 0.2)
		_rail_between(Vector3(a.x + off.x, ya + 0.6, a.y + off.y), Vector3(b.x + off.x, yb + 0.6, b.y + off.y), "rail")


## A box resting on the ground at [param p], facing [param d], size
## (across, height, along), raised by [param lift].
func box(p: Vector2, d: Vector2, size: Vector3, lift: float, kind: String, collide: bool) -> void:
	var y: float = terrain.height_at(p.x, p.y)
	var fwd := Vector3(d.x, 0.0, d.y).normalized()
	var basis := Basis(fwd.cross(Vector3.UP).normalized(), Vector3.UP, -fwd)
	_static_box(Vector3(p.x, y + lift + size.y * 0.5, p.y), basis, size, kind, collide)


## Upright cylinder (or cone, with top_radius) standing on the ground.
func cylinder(p: Vector2, radius: float, height: float, lift: float, kind: String, collide: bool, top_radius: float = -1.0) -> void:
	var y: float = terrain.height_at(p.x, p.y) + lift
	var node: Node3D
	if collide:
		var body := StaticBody3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		var col := CollisionShape3D.new()
		col.shape = shape
		body.add_child(col)
		node = body
	else:
		node = Node3D.new()
	add_child(node)
	node.position = Vector3(p.x, y + height * 0.5, p.y)
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	mesh.radial_segments = 10
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(kind)
	node.add_child(mi)


## Grind rail on posts from [param a] to [param b] at [param lift] (geometry
## only until grinding exists; brief build order step 2).
func rail(a: Vector2, b: Vector2, lift: float, kind: String) -> void:
	_rail_between(ground(a, lift), ground(b, lift), kind)
	var n: int = maxi(1, int(a.distance_to(b) / 5.0))
	for i: int in n + 1:
		var q: Vector2 = a.lerp(b, float(i) / n)
		var g: Vector3 = ground(q)
		_static_box(g + Vector3(0, lift * 0.5, 0), Basis.IDENTITY, Vector3(0.12, lift, 0.12), "metal", true)


func _rail_between(ta: Vector3, tb: Vector3, kind: String) -> void:
	var fwd: Vector3 = (tb - ta).normalized()
	var right: Vector3 = fwd.cross(Vector3.UP).normalized()
	var up: Vector3 = right.cross(fwd)
	_static_box((ta + tb) * 0.5, Basis(right, up, -fwd), Vector3(0.14, 0.14, ta.distance_to(tb)), kind, true)


## A field of crash boulders scattered in a circle (seeded, so the same every run).
func boulders(f: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f.get("seed", 7))
	var c: Vector2 = _v2(f["at"])
	var radius: float = float(f["radius"])
	var smin: float = float(f.get("size_min", 1.5))
	var smax: float = float(f.get("size_max", 3.0))
	for i: int in int(f["count"]):
		var a: float = rng.randf() * TAU
		var r: float = sqrt(rng.randf()) * radius
		var p: Vector2 = c + Vector2(cos(a), sin(a)) * r
		var s: float = rng.randf_range(smin, smax)
		var basis := Basis.from_euler(Vector3(rng.randf() * 0.6, rng.randf() * TAU, rng.randf() * 0.6))
		_static_box(ground(p, s * 0.25), basis, Vector3(s, s * 0.8, s * 1.1), f.get("kind", "boulder"), true)


## Trees scattered in a circle, or along the fan margin when "margin" is set.
func trees(f: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f.get("seed", 3))
	var spots: Array[Vector2] = []
	if f.has("margin"):
		var m: Dictionary = f["margin"]
		var z: float = float(m["z_from"])
		var z_to: float = float(m["z_to"])
		while z > z_to:
			for side: float in [-1.0, 1.0]:
				var u: float = side * rng.randf_range(float(m["u_from"]), float(m["u_to"]))
				var x: float = terrain.axis_at(z) + u * terrain.width_at(z) * 0.5
				spots.append(Vector2(x, z + rng.randf_range(-4.0, 4.0)))
			z -= float(m["spacing"])
	else:
		var c: Vector2 = _v2(f["at"])
		var radius: float = float(f["radius"])
		for i: int in int(f["count"]):
			var a: float = rng.randf() * TAU
			var r: float = sqrt(rng.randf()) * radius
			spots.append(c + Vector2(cos(a), sin(a)) * r)
	for p: Vector2 in spots:
		_tree(p, rng.randf_range(0.8, 1.4))


## Strand marker poles along a line (visual only, no collision): blue round
## poles, rust square posts, teal pennants. §2.12 strand identity.
func markers(f: Dictionary) -> void:
	var pts: PackedVector2Array = CourseMath.sample_spline(f["points"], 4.0)
	var spacing: float = float(f.get("spacing", 40.0))
	var offset: float = float(f.get("offset", 10.0))
	var kind: String = f["kind"]
	var shape: String = f.get("shape", "round")
	var acc: float = spacing
	for i: int in range(1, pts.size()):
		acc += pts[i].distance_to(pts[i - 1])
		if acc < spacing:
			continue
		acc = 0.0
		var dir: Vector2 = (pts[i] - pts[i - 1]).normalized()
		var normal := Vector2(-dir.y, dir.x)
		for side: float in [-1.0, 1.0]:
			var p: Vector2 = pts[i] + normal * offset * side
			var g: Vector3 = ground(p)
			match shape:
				"square":
					_visual_box(g + Vector3(0, 1.0, 0), Vector3(0.35, 2.0, 0.35), kind)
				"pennant":
					_visual_box(g + Vector3(0, 0.4, 0), Vector3(0.9, 0.8, 0.9), "rock")
					_visual_box(g + Vector3(0, 1.6, 0), Vector3(0.08, 1.6, 0.08), "white")
					_visual_box(g + Vector3(0.35 * side, 2.1, 0), Vector3(0.7, 0.45, 0.04), kind)
				_:
					_visual_box(g + Vector3(0, 1.1, 0), Vector3(0.18, 2.2, 0.18), kind)
					_visual_box(g + Vector3(0, 2.3, 0), Vector3(0.4, 0.3, 0.4), kind)


## Chairlift towers along a line with cables between them; the Blue Crown's
## leading line ("follow the chairs").
func chairlift(f: Dictionary) -> void:
	var pts: PackedVector2Array = CourseMath.sample_spline(f["points"], 4.0)
	var spacing: float = float(f.get("spacing", 70.0))
	var offset: float = float(f.get("offset", 14.0))
	var h: float = float(f.get("height", 10.0))
	var tops: Array[Vector3] = []
	var acc: float = spacing * 0.5
	for i: int in range(1, pts.size()):
		acc += pts[i].distance_to(pts[i - 1])
		if acc < spacing:
			continue
		acc = 0.0
		var dir: Vector2 = (pts[i] - pts[i - 1]).normalized()
		var p: Vector2 = pts[i] + Vector2(-dir.y, dir.x) * offset
		var g: Vector3 = ground(p)
		_static_box(g + Vector3(0, h * 0.5, 0), Basis.IDENTITY, Vector3(0.6, h, 0.6), "metal", true)
		var bar_basis := Basis(Vector3.UP, atan2(dir.x, dir.y))
		_static_box(g + Vector3(0, h, 0), bar_basis, Vector3(4.0, 0.3, 0.3), "metal", false)
		tops.append(g + Vector3(0, h - 0.2, 0))
	for side: float in [-1.8, 1.8]:
		for i: int in range(1, tops.size()):
			var a: Vector3 = tops[i - 1]
			var b: Vector3 = tops[i]
			var flat: Vector3 = (b - a) * Vector3(1, 0, 1)
			var off: Vector3 = flat.normalized().cross(Vector3.UP) * side
			var fwd: Vector3 = (b - a).normalized()
			var right: Vector3 = fwd.cross(Vector3.UP).normalized()
			_static_box((a + b) * 0.5 + off, Basis(right, right.cross(fwd), -fwd),
				Vector3(0.06, 0.06, a.distance_to(b)), "metal", false)
			# A chair hanging midway.
			if i % 2 == 0:
				_visual_box((a + b) * 0.5 + off + Vector3(0, -2.2, 0), Vector3(1.6, 0.4, 0.8), "blue")


func _tree(p: Vector2, scale: float) -> void:
	var g: Vector3 = ground(p, -0.3)
	var body := StaticBody3D.new()
	add_child(body)
	body.position = g + Vector3(0, 3.0 * scale, 0)
	var shape := CylinderShape3D.new()
	shape.radius = 0.45 * scale
	shape.height = 6.0 * scale
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	var trunk := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.3 * scale
	cm.bottom_radius = 0.45 * scale
	cm.height = 6.0 * scale
	cm.radial_segments = 6
	trunk.mesh = cm
	trunk.material_override = _mat("trunk")
	body.add_child(trunk)
	var crown := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 2.2 * scale
	cone.height = 6.5 * scale
	cone.radial_segments = 7
	crown.mesh = cone
	crown.material_override = _mat("leaves")
	crown.position = Vector3(0, 3.0 * scale, 0)
	body.add_child(crown)


func _plane_y(origin: Vector2, p: Vector2) -> float:
	# Plane through origin's ground that follows the course's base slope.
	var y0: float = terrain.height_at(origin.x, origin.y)
	return y0 + terrain.base_at(p.y) - terrain.base_at(origin.y)


func _heading(f: Dictionary, p: Vector2) -> Vector2:
	if f.has("toward"):
		return (_v2(f["toward"]) - p).normalized()
	if f.has("heading"):
		var a: float = deg_to_rad(float(f["heading"]))
		return Vector2(sin(a), -cos(a))
	# Default: straight down the fan's centre line.
	var ahead: float = terrain.axis_at(p.y - 10.0) - terrain.axis_at(p.y)
	return Vector2(ahead, -10.0).normalized()


func _visual_box(center: Vector3, size: Vector3, kind: String) -> void:
	_static_box(center, Basis.IDENTITY, size, kind, false)


func _static_box(center: Vector3, basis: Basis, size: Vector3, kind: String, collide: bool) -> StaticBody3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(kind)
	if not collide:
		add_child(mi)
		mi.transform = Transform3D(basis, center)
		return null
	var body := StaticBody3D.new()
	add_child(body)
	body.transform = Transform3D(basis, center)
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	body.add_child(mi)
	return body


func _mat(kind: String) -> StandardMaterial3D:
	if _materials.has(kind):
		return _materials[kind]
	var m := StandardMaterial3D.new()
	# "#rrggbb" kinds give a course its own palette (city paint, buildings).
	m.albedo_color = Color.html(kind) if kind.begins_with("#") else colors.get(kind, Color.MAGENTA)
	m.roughness = 0.85
	if kind in ["concrete", "ledge", "skip", "wall"]:
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.25, 0.25, 0.25)
		m.albedo_texture = CourseBuilder.joint_texture()
	_materials[kind] = m
	return m


static func _v2(a: Variant) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


static func _v3(a: Variant) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
