class_name CourseTerrain
extends RefCounted
## Builds a course's ground as a height grid plus a surface-type grid from
## course data (see docs/course-data-schema.md). Pure data in, arrays out: the
## scene side (CourseBuilder) turns the grids into meshes and collision.
## Implements design/levels/copperline-mountain.md §2.4.

## Surface types. Concrete is fast; grass and gravel slow you; rock is crash
## terrain (steep faces the skater treats as walls).
enum Surface { CONCRETE, GRASS, GRAVEL, ROCK }

## Grid spacing in metres.
var cell: float = 2.0
var x_min: float = 0.0
var z_max: float = 0.0
## Number of samples across (X) and down (Z).
var nx: int = 0
var nz: int = 0
## Heights, row-major: index = iz * nx + ix, iz grows downhill (z decreasing).
var heights := PackedFloat32Array()
## Surface type per sample (Surface enum values).
var surfaces := PackedByteArray()

var _data: Dictionary
var _axis_row := PackedFloat32Array()
var _half_row := PackedFloat32Array()
var _noise_large := FastNoiseLite.new()
var _noise_small := FastNoiseLite.new()
var _noise_wander := FastNoiseLite.new()
## 1 where a street's own width has set the height (feathers leave it alone).
var _lock := PackedByteArray()


## Builds both grids from the "terrain" block of a course data Dictionary.
func build(data: Dictionary) -> void:
	_data = data
	var g: Dictionary = data["grid"]
	cell = float(g.get("cell", 2.0))
	x_min = float(g["x_min"])
	var x_max: float = float(g["x_max"])
	z_max = float(g["z_max"])
	var z_min: float = float(g["z_min"])
	nx = int(round((x_max - x_min) / cell)) + 1
	nz = int(round((z_max - z_min) / cell)) + 1
	heights.resize(nx * nz)
	surfaces.resize(nx * nz)
	var seed: int = int(data.get("seed", 1))
	_setup_noise(_noise_large, seed, data["noise"]["large_wavelength"])
	_setup_noise(_noise_small, seed + 1, data["noise"]["small_wavelength"])
	_setup_noise(_noise_wander, seed + 2, 1.0)
	_base_pass()
	_lock.resize(nx * nz)
	_lock.fill(0)
	for st: Dictionary in data.get("streets", []):
		_stamp_street(st)
	# Order matters: surface bands, then carved channels, then raised islands
	# and bars on top, then cliff steps, then the steepness (rock) pass.
	for band: Dictionary in data.get("bands", []):
		_stamp_line(band, false)
	for ch: Dictionary in data.get("channels", []):
		_stamp_line(ch, true)
	for isl: Dictionary in data.get("islands", []):
		_stamp_island(isl)
	for field: Dictionary in data.get("islet_fields", []):
		for isl: Dictionary in islets(field):
			_stamp_island(isl)
	for bar: Dictionary in data.get("bars", []):
		_stamp_bar(bar)
	for st: Dictionary in data.get("steps", []):
		_stamp_step(st)
	_rock_pass(float(data.get("rock_slope_deg", 48.0)))


## World X of grid column [param ix].
func col_x(ix: int) -> float:
	return x_min + ix * cell


## World Z of grid row [param iz].
func row_z(iz: int) -> float:
	return z_max - iz * cell


## Bilinear height at world ([param x], [param z]); clamps to the grid.
func height_at(x: float, z: float) -> float:
	var fx: float = clampf((x - x_min) / cell, 0.0, nx - 1.001)
	var fz: float = clampf((z_max - z) / cell, 0.0, nz - 1.001)
	var ix: int = int(fx)
	var iz: int = int(fz)
	var tx: float = fx - ix
	var tz: float = fz - iz
	var i: int = iz * nx + ix
	var h00: float = heights[i]
	var h10: float = heights[i + 1]
	var h01: float = heights[i + nx]
	var h11: float = heights[i + nx + 1]
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)


## Surface type nearest world ([param x], [param z]).
func surface_at(x: float, z: float) -> int:
	var ix: int = clampi(int(round((x - x_min) / cell)), 0, nx - 1)
	var iz: int = clampi(int(round((z_max - z) / cell)), 0, nz - 1)
	return surfaces[iz * nx + ix]


## Base profile height (before crown, tilt, noise and stamps) at world [param z].
func base_at(z: float) -> float:
	return CourseMath.curve(_data["base"], z)


## Fan centre line X at world [param z].
func axis_at(z: float) -> float:
	return CourseMath.curve(_data["axis"], z)


## Fan full width at world [param z].
func width_at(z: float) -> float:
	return CourseMath.curve(_data["width"], z)


## Normalised across-fan coordinate: 0 on the axis, ±1 at the fan edge.
func fan_u(x: float, z: float) -> float:
	return (x - axis_at(z)) / (width_at(z) * 0.5)


func _setup_noise(n: FastNoiseLite, seed: int, wavelength: float) -> void:
	n.seed = seed
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 1.0 / maxf(wavelength, 0.001)
	n.fractal_type = FastNoiseLite.FRACTAL_NONE


func _base_pass() -> void:
	var noise: Dictionary = _data["noise"]
	var amp_l: float = float(noise["large_amp"])
	var amp_s: float = float(noise["small_amp"])
	var margin: Dictionary = _data["margin"]
	var m_tan: float = tan(deg_to_rad(float(margin["wall_deg"])))
	var m_cap: float = float(margin["cap"])
	var m_wander: float = float(margin["wander"])
	var m_wander_wl: float = float(margin["wander_wavelength"])
	var m_rock_above: float = float(margin["rock_above"])
	_axis_row.resize(nz)
	_half_row.resize(nz)
	# City courses: lot heights come from the street level grid instead of
	# the fan's base profile, tilt and crown.
	var level_grid: bool = _data.has("level_grid")
	var lg_x: Array = _data["level_grid"]["xs"] if level_grid else []
	var lg_z: Array = _data["level_grid"]["zs"] if level_grid else []
	var lg_y: Array = _data["level_grid"]["ys"] if level_grid else []
	for iz: int in nz:
		var z: float = row_z(iz)
		var base: float = CourseMath.curve(_data["base"], z)
		var axis: float = CourseMath.curve(_data["axis"], z)
		var half: float = CourseMath.curve(_data["width"], z) * 0.5
		var crown_h: float = CourseMath.curve(_data["crown"], z)
		var tilt: float = tan(deg_to_rad(CourseMath.curve(_data["tilt"], z)))
		_axis_row[iz] = axis
		_half_row[iz] = half
		var wander_e: float = m_wander * _noise_wander.get_noise_2d(z / m_wander_wl, 11.0)
		var wander_w: float = m_wander * _noise_wander.get_noise_2d(z / m_wander_wl, -37.0)
		var row: int = iz * nx
		for ix: int in nx:
			var x: float = col_x(ix)
			var dx: float = x - axis
			var edge: float = half + (wander_e if dx > 0.0 else wander_w)
			var u: float = dx / edge
			var au: float = absf(u)
			var h: float = base + tilt * dx
			if level_grid:
				h = CourseMath.grid_bilinear(lg_x, lg_z, lg_y, x, z)
			elif au <= 1.0:
				h += crown_h * (1.0 - u * u)
			var wall: float = 0.0
			if au > 1.0:
				wall = minf((au - 1.0) * edge * m_tan, m_cap)
				h += wall
			h += amp_l * _noise_large.get_noise_2d(x, z)
			h += amp_s * _noise_small.get_noise_2d(x, z)
			heights[row + ix] = h
			var s: int = Surface.GRASS
			if wall > m_rock_above:
				s = Surface.ROCK
			surfaces[row + ix] = s
	# Concrete zones: whole-width bands of the fan (apex, pans, toe).
	for zone: Dictionary in _data.get("concrete_zones", []):
		var z0: float = float(zone["z_from"])
		var z1: float = float(zone["z_to"])
		var ulim: float = float(zone.get("u_limit", 0.92))
		for iz: int in nz:
			var z: float = row_z(iz)
			if z > z0 or z < z1:
				continue
			var row: int = iz * nx
			for ix: int in nx:
				var u: float = (col_x(ix) - _axis_row[iz]) / _half_row[iz]
				if absf(u) <= ulim:
					surfaces[row + ix] = Surface.CONCRETE


func _surface_id(name: String) -> int:
	match name:
		"concrete":
			return Surface.CONCRETE
		"gravel":
			return Surface.GRAVEL
		"rock":
			return Surface.ROCK
	return Surface.GRASS


## Cell index range covering a world-space box, clamped to the grid.
func _cell_range(xa: float, xb: float, za: float, zb: float) -> Array[int]:
	var ix0: int = clampi(int(floor((minf(xa, xb) - x_min) / cell)), 0, nx - 1)
	var ix1: int = clampi(int(ceil((maxf(xa, xb) - x_min) / cell)), 0, nx - 1)
	var iz0: int = clampi(int(floor((z_max - maxf(za, zb)) / cell)), 0, nz - 1)
	var iz1: int = clampi(int(ceil((z_max - minf(za, zb)) / cell)), 0, nz - 1)
	return [ix0, ix1, iz0, iz1]


func _stamp_island(isl: Dictionary) -> void:
	var c := Vector2(float(isl["x"]), float(isl["z"]))
	var rx: float = float(isl["rx"])
	var rz: float = float(isl["rz"])
	var yaw: float = deg_to_rad(float(isl.get("yaw", 0.0)))
	var height: float = float(isl["height"])
	var edge: float = float(isl.get("edge", 4.0))
	var top: int = _surface_id(isl.get("top", "grass"))
	var flank: int = _surface_id(isl.get("flank", "rock"))
	var reach: float = maxf(rx, rz) + edge + 2.0
	var r: Array[int] = _cell_range(c.x - reach, c.x + reach, c.y - reach, c.y + reach)
	for iz: int in range(r[2], r[3] + 1):
		for ix: int in range(r[0], r[1] + 1):
			var p := Vector2(col_x(ix), row_z(iz))
			var out: float = CourseMath.ellipse_outside(p, c, rx, rz, yaw)
			var b: float = CourseMath.bump_profile(out, height, edge)
			if b <= 0.0:
				continue
			var i: int = iz * nx + ix
			heights[i] += b
			surfaces[i] = top if out <= 0.0 else flank


## Polyline along with optional lateral wander, sampled densely.
func _line_points(def: Dictionary) -> PackedVector2Array:
	var raw: PackedVector2Array = CourseMath.sample_spline(def["points"], 6.0)
	var wander: float = float(def.get("wander", 0.0))
	if wander <= 0.0 or raw.size() < 2:
		return raw
	var out := PackedVector2Array()
	var along: float = 0.0
	var fade: float = float(def.get("wander_fade", 40.0))
	var total: float = 0.0
	for i: int in range(1, raw.size()):
		total += raw[i].distance_to(raw[i - 1])
	for i: int in raw.size():
		if i > 0:
			along += raw[i].distance_to(raw[i - 1])
		var a: Vector2 = raw[maxi(i - 1, 0)]
		var b: Vector2 = raw[mini(i + 1, raw.size() - 1)]
		var tangent: Vector2 = (b - a).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		# Fade the wander out at both ends so the line meets its knots.
		var f: float = clampf(minf(along, total - along) / fade, 0.0, 1.0)
		var w: float = wander * f * _noise_wander.get_noise_1d(along / 90.0 + float(def.get("points").size()) * 13.0)
		out.append(raw[i] + normal * w)
	return out


## Stamps a channel (carved, concrete floor) or a band (surface only) along a
## polyline. Channels lower the ground; both paint their surface.
func _stamp_line(def: Dictionary, carve: bool) -> void:
	var pts: PackedVector2Array = _line_points(def)
	var width: float = float(def["width"])
	var half: float = width * 0.5
	var depth: float = float(def.get("depth", 0.0)) if carve else 0.0
	var floor_frac: float = float(def.get("floor_frac", 0.35))
	var surf: int = _surface_id(def.get("surface", "concrete"))
	var paint_frac: float = float(def.get("paint_frac", 0.85))
	var rim: float = float(def.get("rim_width", 0.0))
	var rim_surf: int = _surface_id(def.get("rim_surface", "grass"))
	var reach: float = half + rim + 1.0
	if pts.size() < 2:
		return
	var minx: float = INF
	var maxx: float = -INF
	var minz: float = INF
	var maxz: float = -INF
	for p: Vector2 in pts:
		minx = minf(minx, p.x)
		maxx = maxf(maxx, p.x)
		minz = minf(minz, p.y)
		maxz = maxf(maxz, p.y)
	var r: Array[int] = _cell_range(minx - reach, maxx + reach, minz - reach, maxz + reach)
	var w: int = r[1] - r[0] + 1
	var hgt: int = r[3] - r[2] + 1
	var dist := PackedFloat32Array()
	dist.resize(w * hgt)
	dist.fill(INF)
	var along := PackedFloat32Array()
	along.resize(w * hgt)
	var cum: float = 0.0
	for k: int in range(1, pts.size()):
		var a: Vector2 = pts[k - 1]
		var b: Vector2 = pts[k]
		var seg: float = a.distance_to(b)
		var sr: Array[int] = _cell_range(minf(a.x, b.x) - reach, maxf(a.x, b.x) + reach, minf(a.y, b.y) - reach, maxf(a.y, b.y) + reach)
		for iz: int in range(sr[2], sr[3] + 1):
			var pz: float = row_z(iz)
			var lrow: int = (iz - r[2]) * w
			for ix: int in range(sr[0], sr[1] + 1):
				var p := Vector2(col_x(ix), pz)
				var d: float = CourseMath.dist_to_segment(p, a, b)
				var li: int = lrow + ix - r[0]
				if d < dist[li]:
					dist[li] = d
					var t: float = clampf((p - a).dot(b - a) / maxf(seg * seg, 0.0001), 0.0, 1.0)
					along[li] = cum + t * seg
		cum += seg
	var taper_in: float = float(def.get("taper_in", def.get("taper", 40.0)))
	var taper_out: float = float(def.get("taper_out", def.get("taper", 40.0)))
	var keep: Array = def.get("keep", [] if carve else ["gravel", "rock"])
	var keep_ids: Array[int] = []
	for k: String in keep:
		keep_ids.append(_surface_id(k))
	for iz: int in range(r[2], r[3] + 1):
		for ix: int in range(r[0], r[1] + 1):
			var li: int = (iz - r[2]) * w + ix - r[0]
			var d: float = dist[li]
			if d >= reach:
				continue
			var i: int = iz * nx + ix
			var al: float = along[li]
			var fade: float = minf(clampf(al / maxf(taper_in, 0.01), 0.0, 1.0), clampf((cum - al) / maxf(taper_out, 0.01), 0.0, 1.0))
			if carve and depth > 0.0:
				heights[i] -= CourseMath.channel_profile(d, width, depth * fade, floor_frac)
			if surfaces[i] in keep_ids:
				continue
			if d <= half * paint_frac:
				surfaces[i] = surf
			elif rim > 0.0 and d <= half + rim:
				surfaces[i] = rim_surf


## Stamps a street: [x, z, y] points joined by straight runs, level across
## its [code]width[/code], painted [code]surface[/code] (default concrete),
## blended into the ground around it over [code]feather[/code] metres.
## Streets stamped later win where they overlap (intersections share heights).
func _stamp_street(def: Dictionary) -> void:
	var raw: Array = def["points"]
	if raw.size() < 2:
		return
	var pts: Array[Vector3] = []
	for q: Array in raw:
		pts.append(Vector3(float(q[0]), float(q[1]), float(q[2])))
	var half: float = float(def["width"]) * 0.5
	var feather: float = float(def.get("feather", 6.0))
	var surf: int = _surface_id(def.get("surface", "concrete"))
	var reach: float = half + feather + cell
	var minx: float = INF
	var maxx: float = -INF
	var minz: float = INF
	var maxz: float = -INF
	for p: Vector3 in pts:
		minx = minf(minx, p.x)
		maxx = maxf(maxx, p.x)
		minz = minf(minz, p.y)
		maxz = maxf(maxz, p.y)
	var r: Array[int] = _cell_range(minx - reach, maxx + reach, minz - reach, maxz + reach)
	var w: int = r[1] - r[0] + 1
	var hgt: int = r[3] - r[2] + 1
	var dist := PackedFloat32Array()
	dist.resize(w * hgt)
	dist.fill(INF)
	var sy := PackedFloat32Array()
	sy.resize(w * hgt)
	for k: int in range(1, pts.size()):
		var a: Vector3 = pts[k - 1]
		var b: Vector3 = pts[k]
		var a2 := Vector2(a.x, a.y)
		var b2 := Vector2(b.x, b.y)
		var sr: Array[int] = _cell_range(minf(a.x, b.x) - reach, maxf(a.x, b.x) + reach, minf(a.y, b.y) - reach, maxf(a.y, b.y) + reach)
		for iz: int in range(sr[2], sr[3] + 1):
			var pz: float = row_z(iz)
			var lrow: int = (iz - r[2]) * w - r[0]
			for ix: int in range(sr[0], sr[1] + 1):
				var p := Vector2(col_x(ix), pz)
				var d: float = CourseMath.dist_to_segment(p, a2, b2)
				var li: int = lrow + ix
				if d < dist[li]:
					dist[li] = d
					sy[li] = CourseMath.street_height(p, a, b)
	for iz: int in range(r[2], r[3] + 1):
		for ix: int in range(r[0], r[1] + 1):
			var li: int = (iz - r[2]) * w + ix - r[0]
			var d: float = dist[li]
			var i: int = iz * nx + ix
			if d <= half:
				heights[i] = sy[li]
				surfaces[i] = surf
				_lock[i] = 1
			elif d < half + feather and _lock[i] == 0:
				var k: float = smoothstep(0.0, 1.0, (d - half) / feather)
				heights[i] = lerpf(sy[li], heights[i], k)


## Scattered braid islets (seeded) inside a fan region, kept clear of the
## listed lines and circles. Returns island definitions for _stamp_island.
func islets(field: Dictionary) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(field.get("seed", 21))
	var out: Array[Dictionary] = []
	var avoid: Array[PackedVector2Array] = []
	for line: Array in field.get("avoid_lines", []):
		avoid.append(CourseMath.sample_spline(line, 8.0))
	var clear: float = float(field.get("clearance", 25.0))
	var gap: float = float(field.get("min_gap", 15.0))
	var tries: int = 0
	while out.size() < int(field["count"]) and tries < 2000:
		tries += 1
		var z: float = rng.randf_range(float(field["z_to"]), float(field["z_from"]))
		var u: float = rng.randf_range(float(field["u_from"]), float(field["u_to"]))
		var x: float = axis_at(z) + u * width_at(z) * 0.5
		var p := Vector2(x, z)
		var rx: float = rng.randf_range(float(field["rx"][0]), float(field["rx"][1]))
		var rz: float = rng.randf_range(float(field["rz"][0]), float(field["rz"][1]))
		var ok: bool = true
		for line: PackedVector2Array in avoid:
			for k: int in range(1, line.size()):
				if CourseMath.dist_to_segment(p, line[k - 1], line[k]) < clear + maxf(rx, rz):
					ok = false
					break
			if not ok:
				break
		for c: Array in field.get("avoid_circles", []):
			if p.distance_to(Vector2(float(c[0]), float(c[1]))) < float(c[2]) + maxf(rx, rz):
				ok = false
		for o: Dictionary in out:
			if p.distance_to(Vector2(o["x"], o["z"])) < gap + maxf(rx, rz) + maxf(float(o["rx"]), float(o["rz"])):
				ok = false
		if not ok:
			continue
		out.append({
			"x": x, "z": z, "rx": rx, "rz": rz, "yaw": rng.randf_range(-25.0, 25.0),
			"height": rng.randf_range(float(field["height"][0]), float(field["height"][1])),
			"edge": float(field.get("edge", 8.0)), "top": field.get("top", "grass"),
			"flank": field.get("flank", "grass"),
		})
	return out


func _stamp_bar(bar: Dictionary) -> void:
	var pts: PackedVector2Array = CourseMath.sample_spline(bar["points"], 6.0)
	var height: float = float(bar["height"])
	var edge: float = float(bar.get("edge", 6.0))
	var widths: Array = bar["widths"]
	var surf: int = _surface_id(bar.get("surface", "gravel"))
	var cuts: Array = bar.get("cuts", [])
	var max_half: float = 0.0
	for wk: Array in widths:
		max_half = maxf(max_half, float(wk[1]) * 0.5)
	var reach: float = max_half + edge + 2.0
	for k: int in range(1, pts.size()):
		var a: Vector2 = pts[k - 1]
		var b: Vector2 = pts[k]
		var sr: Array[int] = _cell_range(minf(a.x, b.x) - reach, maxf(a.x, b.x) + reach, minf(a.y, b.y) - reach, maxf(a.y, b.y) + reach)
		for iz: int in range(sr[2], sr[3] + 1):
			for ix: int in range(sr[0], sr[1] + 1):
				var p := Vector2(col_x(ix), row_z(iz))
				# Only the segment whose span contains p writes, to avoid double stamps.
				var ab: Vector2 = b - a
				var t: float = (p - a).dot(ab) / maxf(ab.length_squared(), 0.0001)
				if (t < 0.0 and k > 1) or (t > 1.0 and k < pts.size() - 1):
					continue
				var d: float = CourseMath.dist_to_segment(p, a, b)
				var half: float = CourseMath.piecewise(widths, p.x) * 0.5
				var bump: float = CourseMath.bump_profile(d - half, height, edge)
				if bump <= 0.0:
					continue
				var cut_open: bool = false
				for cut: Dictionary in cuts:
					var cx: float = float(cut["x"])
					var cw: float = float(cut["width"]) * 0.5
					if absf(p.x - cx) <= cw:
						cut_open = true
					elif absf(p.x - cx) <= cw + float(cut.get("flare", 6.0)):
						bump *= (absf(p.x - cx) - cw) / float(cut.get("flare", 6.0))
				var i: int = iz * nx + ix
				if cut_open:
					surfaces[i] = Surface.CONCRETE
					continue
				heights[i] += bump
				if d - half <= 0.0:
					surfaces[i] = surf


## A step (cliff band, drop lip): ground on the downhill side of a wavy line
## drops by a per-x-zone profile of [s, drop] where s is metres below the line.
func _stamp_step(st: Dictionary) -> void:
	var z0: float = float(st["z"])
	var amp: float = float(st.get("wave_amp", 0.0))
	var wl: float = float(st.get("wave_length", 100.0))
	var zones: Array = st["zones"]
	var edge_blend: float = float(st.get("edge_blend", 0.0))
	var s_min: float = INF
	var s_max: float = -INF
	var xa: float = INF
	var xb: float = -INF
	for zn: Dictionary in zones:
		xa = minf(xa, float(zn["x_from"]))
		xb = maxf(xb, float(zn["x_to"]))
		for pt: Array in zn["profile"]:
			s_min = minf(s_min, float(pt[0]))
			s_max = maxf(s_max, float(pt[0]))
	var extends_down: bool = bool(st.get("extends_down", true))
	var z_top: float = z0 + amp - s_min + 2.0
	var z_bot: float = (row_z(nz - 1) if extends_down else z0 - amp - s_max - 2.0)
	var r: Array[int] = _cell_range(xa - edge_blend, xb + edge_blend, z_bot, z_top)
	for iz: int in range(r[2], r[3] + 1):
		var z: float = row_z(iz)
		for ix: int in range(r[0], r[1] + 1):
			var x: float = col_x(ix)
			var line_z: float = z0 + amp * sin(x / wl * TAU)
			var s: float = line_z - z
			var drop: float = 0.0
			var found: bool = false
			for zn: Dictionary in zones:
				if x >= float(zn["x_from"]) and x < float(zn["x_to"]):
					drop = CourseMath.piecewise(zn["profile"], s)
					found = true
					if zn.has("surface") and s >= float(zn.get("surface_from", -INF)) and s <= float(zn.get("surface_to", INF)):
						surfaces[iz * nx + ix] = _surface_id(zn["surface"])
					break
			if not found and edge_blend > 0.0:
				# Fade the outermost zones' drops to nothing beyond the band ends.
				var near: Dictionary = zones[0] if x < xa else zones[zones.size() - 1]
				var dist: float = (xa - x) if x < xa else (x - xb)
				if dist < edge_blend:
					drop = CourseMath.piecewise(near["profile"], s) * (1.0 - dist / edge_blend)
			if drop != 0.0:
				heights[iz * nx + ix] -= drop


## Marks anything steeper than [param deg] as rock (crash terrain).
func _rock_pass(deg: float) -> void:
	var limit: float = tan(deg_to_rad(deg)) * cell
	for iz: int in range(0, nz - 1):
		for ix: int in range(0, nx - 1):
			var i: int = iz * nx + ix
			var h: float = heights[i]
			if absf(heights[i + 1] - h) > limit or absf(heights[i + nx] - h) > limit:
				surfaces[i] = Surface.ROCK
				surfaces[i + 1] = Surface.ROCK if absf(heights[i + 1] - h) > limit else surfaces[i + 1]
				surfaces[i + nx] = Surface.ROCK if absf(heights[i + nx] - h) > limit else surfaces[i + nx]
