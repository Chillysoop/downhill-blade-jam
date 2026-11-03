class_name LevelBuilder
extends Node3D
## Greybox building kit. Builds slope segments laid end to end downhill
## (towards -Z) and places features on them using (segment, across, along)
## coordinates, so layouts read like a course map.

const SLAB_THICKNESS: float = 2.0

var _segments: Array[Dictionary] = []
var _materials: Dictionary = {}
## Lowest surface point built so far; used to place the kill height.
var lowest_y: float = 0.0


## Adds a slope segment [param length] metres long at [param pitch_deg]
## downhill, [param width] metres wide. Returns its index.
func add_segment(length: float, pitch_deg: float, width: float, holes: Array = []) -> int:
	var start: Vector3 = Vector3.ZERO
	if not _segments.is_empty():
		var last: Dictionary = _segments[-1]
		start = last["end"]
	var b := Basis(Vector3.RIGHT, -deg_to_rad(pitch_deg))
	var dir: Vector3 = -b.z
	var seg: Dictionary = {
		"start": start, "end": start + dir * length, "basis": b,
		"length": length, "width": width,
	}
	_segments.append(seg)
	var idx: int = _segments.size() - 1
	# holes: Array of [x_min, x_max, s_min, s_max] rectangles left open (pits).
	if holes.is_empty():
		_slab(idx, -width / 2.0, width / 2.0, 0.0, length, "slope")
	else:
		for piece: Array in _split_around_holes(width, length, holes):
			_slab(idx, piece[0], piece[1], piece[2], piece[3], "slope")
	# Side berms so the course edge reads clearly.
	for side: float in [-1.0, 1.0]:
		box(idx, side * (width / 2.0 + 0.5), length / 2.0, Vector3(1.0, 1.2, length), "berm")
	lowest_y = minf(lowest_y, seg["end"].y)
	return idx


## World position of the surface of segment [param idx] at [param x] across
## (right is +) and [param s] metres along it.
func surface_point(idx: int, x: float, s: float) -> Vector3:
	var seg: Dictionary = _segments[idx]
	var b: Basis = seg["basis"]
	return seg["start"] + (-b.z) * s + Vector3.RIGHT * x


## Downhill direction of segment [param idx].
func segment_dir(idx: int) -> Vector3:
	var b: Basis = _segments[idx]["basis"]
	return -b.z


## A box resting on the surface: [param size] is (across, height, along).
## [param lift] raises it above the surface (negative sinks it).
func box(idx: int, x: float, s: float, size: Vector3, kind: String, lift: float = 0.0) -> void:
	var b: Basis = _segments[idx]["basis"]
	var center: Vector3 = surface_point(idx, x, s) + b.y * (size.y / 2.0 + lift)
	_static_box(center, b, size, kind)


## A launch ramp: starts flush with the surface at [param s] and rises at
## [param angle_deg] over [param length] metres.
func kicker(idx: int, x: float, s: float, width: float, length: float, angle_deg: float) -> void:
	var b: Basis = _segments[idx]["basis"] * Basis(Vector3.RIGHT, deg_to_rad(angle_deg))
	var h: float = 0.6
	var near_top: Vector3 = surface_point(idx, x, s)
	var center: Vector3 = near_top - b * Vector3(0.0, h / 2.0, length / 2.0)
	_static_box(center, b, Vector3(width, h, length), "kicker")


## A rounded bump across the slope, [param height] metres tall.
func roller(idx: int, x: float, s: float, width: float, height: float, radius: float) -> void:
	var b: Basis = _segments[idx]["basis"]
	var center: Vector3 = surface_point(idx, x, s) + b.y * (height - radius)
	var body := StaticBody3D.new()
	add_child(body)
	body.global_transform = Transform3D(b * Basis(Vector3.FORWARD, PI / 2.0), center)
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = width
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = width
	mesh.radial_segments = 48
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat("roller")
	body.add_child(mi)


## A tree-like obstacle (upright cylinder) at the given spot.
func tree(idx: int, x: float, s: float) -> void:
	var p: Vector3 = surface_point(idx, x, s)
	var body := StaticBody3D.new()
	add_child(body)
	body.global_position = p + Vector3(0, 3.0, 0)
	var shape := CylinderShape3D.new()
	shape.radius = 0.5
	shape.height = 6.0
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	var trunk := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.35
	cm.bottom_radius = 0.5
	cm.height = 6.0
	trunk.mesh = cm
	trunk.material_override = _mat("trunk")
	body.add_child(trunk)
	var crown := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 2.0
	cone.height = 5.0
	crown.mesh = cone
	crown.material_override = _mat("leaves")
	crown.position = Vector3(0, 2.5, 0)
	body.add_child(crown)


## A stair of ledges climbing [param step_h] each, [param depth] metres deep,
## then a raised deck [param deck_len] long. Returns the deck's top height
## above the slope.
func step_up(idx: int, x: float, s: float, width: float, steps: int, step_h: float, depth: float, deck_len: float) -> float:
	for i: int in steps:
		var h: float = step_h * (i + 1)
		var along: float = s + depth * i
		var length: float = depth * (steps - i) + deck_len
		box(idx, x, along + length / 2.0, Vector3(width, h, length), "ledge" if i % 2 == 0 else "ledge_alt")
	return step_h * steps


## Adds the finish gate across segment [param idx] at [param s]; returns the trigger Area3D.
func finish_gate(idx: int, s: float) -> Area3D:
	var seg: Dictionary = _segments[idx]
	var w: float = seg["width"]
	var p: Vector3 = surface_point(idx, 0.0, s)
	for side: float in [-1.0, 1.0]:
		box(idx, side * (w / 2.0 - 0.5), s, Vector3(0.6, 6.0, 0.6), "finish")
	box(idx, 0.0, s, Vector3(w, 0.8, 0.6), "finish", 5.2)
	var area := Area3D.new()
	add_child(area)
	area.global_position = p + Vector3(0, 3, 0)
	var shape := BoxShape3D.new()
	shape.size = Vector3(w, 6, 1.5)
	var col := CollisionShape3D.new()
	col.shape = shape
	area.add_child(col)
	return area


func _slab(idx: int, x0: float, x1: float, s0: float, s1: float, kind: String) -> void:
	var b: Basis = _segments[idx]["basis"]
	var size := Vector3(x1 - x0, SLAB_THICKNESS, s1 - s0)
	var top_center: Vector3 = surface_point(idx, (x0 + x1) / 2.0, (s0 + s1) / 2.0)
	_static_box(top_center - b.y * SLAB_THICKNESS / 2.0, b, size, kind)


## Splits a width x length rectangle into slab pieces that avoid the holes.
## Each hole spans the given x range for an s range; slabs fill the rest.
func _split_around_holes(width: float, length: float, holes: Array) -> Array:
	var pieces: Array = []
	var cuts: Array = [0.0, length]
	for hole: Array in holes:
		cuts.append(hole[2])
		cuts.append(hole[3])
	cuts.sort()
	for i: int in cuts.size() - 1:
		var s0: float = cuts[i]
		var s1: float = cuts[i + 1]
		if s1 - s0 < 0.01:
			continue
		var mid: float = (s0 + s1) / 2.0
		var xs: Array = [-width / 2.0, width / 2.0]
		var blocked: Array = []
		for hole: Array in holes:
			if mid > hole[2] and mid < hole[3]:
				blocked.append([hole[0], hole[1]])
				xs.append(hole[0])
				xs.append(hole[1])
		xs.sort()
		for j: int in xs.size() - 1:
			var xa: float = xs[j]
			var xb: float = xs[j + 1]
			if xb - xa < 0.01:
				continue
			var xm: float = (xa + xb) / 2.0
			var open: bool = false
			for r: Array in blocked:
				if xm > r[0] and xm < r[1]:
					open = true
			if not open:
				pieces.append([xa, xb, s0, s1])
	return pieces


func _static_box(center: Vector3, b: Basis, size: Vector3, kind: String) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.global_transform = Transform3D(b, center)
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(kind)
	body.add_child(mi)


func _mat(kind: String) -> StandardMaterial3D:
	if _materials.has(kind):
		return _materials[kind]
	var colors: Dictionary = {
		"slope": Color(0.62, 0.64, 0.68), "berm": Color(0.45, 0.48, 0.55),
		"kicker": Color(1.0, 0.62, 0.15), "roller": Color(0.55, 0.75, 0.95),
		"ledge": Color(0.5, 0.85, 0.55), "ledge_alt": Color(0.4, 0.72, 0.46),
		"wall": Color(0.38, 0.4, 0.48), "trunk": Color(0.42, 0.3, 0.2),
		"leaves": Color(0.22, 0.5, 0.3), "finish": Color(0.2, 0.9, 0.4),
	}
	var m := StandardMaterial3D.new()
	m.albedo_color = colors.get(kind, Color.MAGENTA)
	m.roughness = 0.9
	if kind == "slope":
		# A world-space grid makes speed readable on the greybox.
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.2, 0.2, 0.2)
		m.albedo_texture = _grid_texture()
	_materials[kind] = m
	return m


func _grid_texture() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	img.fill(Color(0.85, 0.86, 0.9))
	for i: int in 64:
		for k: int in 3:
			img.set_pixel(i, k, Color(0.45, 0.48, 0.56))
			img.set_pixel(k, i, Color(0.45, 0.48, 0.56))
	var tex := ImageTexture.create_from_image(img)
	return tex
