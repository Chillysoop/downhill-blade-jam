class_name CourseBuilder
extends Node3D
## Builds a whole course from a data file: terrain (mesh + collision chunks),
## placed features via CourseKit, checkpoint gates and the finish.
## Used by main.gd for every course except the legacy test slope.
## Data schema: docs/course-data-schema.md. First course:
## design/levels/copperline-mountain.md.

## Emitted when the skater crosses checkpoint gate [param index] (1-based,
## in order). [param respawn] is where a crash now sends the skater.
signal checkpoint_reached(index: int, name: String, respawn: Transform3D)

## Course display name.
var course_name: String = ""
## Where the skater starts.
var spawn_point: Vector3
## Downhill direction at the start.
var spawn_facing: Vector3
## The finish trigger.
var finish: Area3D
## Lowest ground height; the kill height is set below it.
var lowest_y: float = 0.0
## The ground grids.
var terrain := CourseTerrain.new()
## Named routes ([x, z] waypoints) for the dev autopilot.
var routes: Dictionary = {}
## Surface drag settings from data.
var surface_rules: Dictionary = {}

var _data: Dictionary
var _gates: Array[Dictionary] = []
var _next_gate: int = 0
var _oob_u: float = 1.25
var _skater: Node3D

static var _joint_tex: ImageTexture


## Loads and builds the course at [param path] (a JSON file).
func load_course(path: String) -> void:
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("CourseBuilder: could not parse %s" % path)
		return
	_data = parsed
	course_name = _data.get("name", "Course")
	var t0: int = Time.get_ticks_msec()
	terrain.build(_data["terrain"])
	var t1: int = Time.get_ticks_msec()
	_build_terrain_nodes()
	var kit := CourseKit.new()
	kit.name = "Features"
	kit.terrain = terrain
	add_child(kit)
	for f: Dictionary in _data.get("features", []):
		kit.place(f)
	var t2: int = Time.get_ticks_msec()
	_build_gates(kit)
	routes = _data.get("routes", {})
	surface_rules = _data.get("surfaces", {})
	_oob_u = float(_data.get("out_of_bounds_u", 1.25))
	var sp: Array = _data["spawn"]
	spawn_point = kit.ground(Vector2(float(sp[0]), float(sp[1])), 0.4)
	var ahead: Vector3 = kit.ground(Vector2(terrain.axis_at(float(sp[1]) - 20.0), float(sp[1]) - 20.0))
	spawn_facing = ((ahead - spawn_point) * Vector3(1, 0, 1)).normalized()
	print("Course '%s' built: terrain %d ms, meshes+features %d ms (%dx%d samples)" % [
		course_name, t1 - t0, t2 - t1, terrain.nx, terrain.nz])


## Starts watching [param skater] for gate crossings.
func track(skater: Node3D) -> void:
	_skater = skater


## Resets checkpoint progress (a restart from the top).
func reset_progress() -> void:
	_next_gate = 0


## Surface type under world position [param p] (CourseTerrain.Surface).
func surface_at(p: Vector3) -> int:
	return terrain.surface_at(p.x, p.z)


## True when [param p] is beyond the valley walls or off the grid.
func is_out_of_bounds(p: Vector3) -> bool:
	var g: Dictionary = _data["terrain"]["grid"]
	if p.x < float(g["x_min"]) + 4.0 or p.x > float(g["x_max"]) - 4.0:
		return true
	if p.z > float(g["z_max"]) - 4.0 or p.z < float(g["z_min"]) + 4.0:
		return true
	return absf(terrain.fan_u(p.x, p.z)) > _oob_u


func _physics_process(_dt: float) -> void:
	if _skater == null or _next_gate >= _gates.size():
		return
	var gate: Dictionary = _gates[_next_gate]
	if _skater.global_position.z <= float(gate["z"]):
		_next_gate += 1
		var x: float = _skater.global_position.x
		var best: float = INF
		var pad_x: float = x
		for px: Variant in gate["pads"]:
			if absf(float(px) - x) < best:
				best = absf(float(px) - x)
				pad_x = float(px)
		var pz: float = float(gate["z"]) - float(gate.get("pad_offset", 15.0))
		var pos := Vector3(pad_x, terrain.height_at(pad_x, pz) + 0.4, pz)
		var ahead_z: float = pz - 20.0
		var ahead := Vector3(terrain.axis_at(ahead_z), 0.0, ahead_z)
		var facing: Vector3 = ((ahead - pos) * Vector3(1, 0, 1)).normalized()
		checkpoint_reached.emit(_next_gate, gate.get("name", "Split"), Transform3D(Basis.looking_at(facing, Vector3.UP), pos))


func _build_gates(kit: CourseKit) -> void:
	for g: Dictionary in _data.get("gates", []):
		var z: float = float(g["z"])
		var axis: float = terrain.axis_at(z)
		var half: float = terrain.width_at(z) * 0.5
		var spacing: float = float(g.get("tower_spacing", 60.0))
		var x: float = axis - half + spacing * 0.5
		while x < axis + half:
			var gp: Vector3 = kit.ground(Vector2(x, z))
			kit._static_box(gp + Vector3(0, 3.0, 0), Basis.IDENTITY, Vector3(0.5, 6.0, 0.5), "white", false)
			kit._static_box(gp + Vector3(0, 6.3, 0), Basis.IDENTITY, Vector3(0.6, 0.6, 0.6), "green", false)
			kit._static_box(gp + Vector3(0.9, 5.2, 0), Basis.IDENTITY, Vector3(1.6, 1.0, 0.05), "green", false)
			x += spacing
		if String(g.get("kind", "split")) == "finish":
			finish = Area3D.new()
			add_child(finish)
			finish.position = Vector3(axis, terrain.height_at(axis, z), z)
			var shape := BoxShape3D.new()
			shape.size = Vector3(4000.0, 1200.0, 2.0)
			var col := CollisionShape3D.new()
			col.shape = shape
			finish.add_child(col)
			# Painted finish line across the toe and an arch over the main lane.
			kit._static_box(kit.ground(Vector2(axis, z), 0.03), Basis.IDENTITY, Vector3(half * 2.0, 0.06, 1.2), "white", false)
			var ax: float = float(g.get("arch_x", axis))
			for side: float in [-1.0, 1.0]:
				kit._static_box(kit.ground(Vector2(ax + side * 9.0, z), 4.0), Basis.IDENTITY, Vector3(0.9, 8.0, 0.9), "green", false)
			kit._static_box(kit.ground(Vector2(ax, z), 8.3), Basis.IDENTITY, Vector3(19.0, 1.2, 1.0), "green", false)
		else:
			_gates.append(g)


func _build_terrain_nodes() -> void:
	var chunk: int = int(_data["terrain"]["grid"].get("chunk_cells", 32))
	var palette: Dictionary = {
		CourseTerrain.Surface.CONCRETE: Color(0.74, 0.72, 0.68),
		CourseTerrain.Surface.GRASS: Color(0.38, 0.55, 0.30),
		CourseTerrain.Surface.GRAVEL: Color(0.56, 0.52, 0.48),
		CourseTerrain.Surface.ROCK: Color(0.34, 0.33, 0.36),
	}
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3(0.125, 0.125, 0.125)
	mat.albedo_texture = joint_texture()
	var nx: int = terrain.nx
	var nz: int = terrain.nz
	lowest_y = INF
	for h: float in terrain.heights:
		lowest_y = minf(lowest_y, h)
	var shade := FastNoiseLite.new()
	shade.seed = 99
	shade.frequency = 0.08
	for cz: int in range(0, nz - 1, chunk):
		for cx: int in range(0, nx - 1, chunk):
			var ex: int = mini(cx + chunk, nx - 1)
			var ez: int = mini(cz + chunk, nz - 1)
			var verts := PackedVector3Array()
			var normals := PackedVector3Array()
			var cols := PackedColorArray()
			var idx := PackedInt32Array()
			var w: int = ex - cx + 1
			for iz: int in range(cz, ez + 1):
				for ix: int in range(cx, ex + 1):
					var i: int = iz * nx + ix
					var x: float = terrain.col_x(ix)
					var z: float = terrain.row_z(iz)
					verts.append(Vector3(x, terrain.heights[i], z))
					var hl: float = terrain.heights[iz * nx + maxi(ix - 1, 0)]
					var hr: float = terrain.heights[iz * nx + mini(ix + 1, nx - 1)]
					var hu: float = terrain.heights[maxi(iz - 1, 0) * nx + ix]
					var hd: float = terrain.heights[mini(iz + 1, nz - 1) * nx + ix]
					# z decreases with iz: d/dz = (hu - hd) / (2 cell).
					normals.append(Vector3(hl - hr, 2.0 * terrain.cell, hd - hu).normalized())
					var c: Color = palette[terrain.surfaces[i]]
					var v: float = 1.0 + 0.06 * shade.get_noise_2d(x, z)
					cols.append(Color(c.r * v, c.g * v, c.b * v))
			for iz: int in range(0, ez - cz):
				for ix: int in range(0, ex - cx):
					var a: int = iz * w + ix
					var b: int = a + 1
					var c2: int = a + w
					var d: int = c2 + 1
					idx.append_array([a, c2, b, b, c2, d])
			var arrays: Array = []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = verts
			arrays[Mesh.ARRAY_NORMAL] = normals
			arrays[Mesh.ARRAY_COLOR] = cols
			arrays[Mesh.ARRAY_INDEX] = idx
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			var faces := PackedVector3Array()
			faces.resize(idx.size())
			for k: int in idx.size():
				faces[k] = verts[idx[k]]
			var body := StaticBody3D.new()
			body.name = "Ground_%d_%d" % [cx, cz]
			add_child(body)
			var shape := ConcavePolygonShape3D.new()
			shape.set_faces(faces)
			shape.backface_collision = true
			var col := CollisionShape3D.new()
			col.shape = shape
			body.add_child(col)
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			mi.material_override = mat
			body.add_child(mi)


## Pale concrete texture with darker expansion joints; multiplies the ground
## colour so concrete reads as the fast surface and speed is visible.
static func joint_texture() -> ImageTexture:
	if _joint_tex != null:
		return _joint_tex
	var img := Image.create(64, 64, true, Image.FORMAT_RGB8)
	img.fill(Color(1, 1, 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for y: int in 64:
		for x: int in 64:
			var v: float = 0.94 + rng.randf() * 0.06
			img.set_pixel(x, y, Color(v, v, v))
	for i: int in 64:
		for k: int in 2:
			img.set_pixel(i, k, Color(0.72, 0.72, 0.74))
			img.set_pixel(k, i, Color(0.72, 0.72, 0.74))
	img.generate_mipmaps()
	_joint_tex = ImageTexture.create_from_image(img)
	return _joint_tex
