class_name CourseMath
extends RefCounted
## Pure helpers for building courses from data: 1D curves, 2D splines and
## distance queries. No scene access, so everything here is unit-testable.
## Implements the terrain composition in design/levels/copperline-mountain.md §2.4.


## Interpolates a list of [z, value] knots (any order) at [param z] with a
## smooth monotone cubic, clamping beyond the ends. Used for the base profile,
## fan axis, fan width, crown height and cross-slope tilt.
static func curve(knots: Array, z: float) -> float:
	var n: int = knots.size()
	if n == 0:
		return 0.0
	if n == 1:
		return float(knots[0][1])
	# Knots run downhill (decreasing z) in data; work in "distance down" t = -z.
	var t: float = -z
	var t0: float = -float(knots[0][0])
	if t <= t0:
		return float(knots[0][1])
	var tn: float = -float(knots[n - 1][0])
	if t >= tn:
		return float(knots[n - 1][1])
	var i: int = 0
	while i < n - 2 and t > -float(knots[i + 1][0]):
		i += 1
	var ta: float = -float(knots[i][0])
	var tb: float = -float(knots[i + 1][0])
	var va: float = float(knots[i][1])
	var vb: float = float(knots[i + 1][1])
	var h: float = tb - ta
	if h <= 0.0:
		return vb
	var u: float = (t - ta) / h
	var ma: float = _knot_slope(knots, i)
	var mb: float = _knot_slope(knots, i + 1)
	var u2: float = u * u
	var u3: float = u2 * u
	return (2.0 * u3 - 3.0 * u2 + 1.0) * va + (u3 - 2.0 * u2 + u) * h * ma \
		+ (-2.0 * u3 + 3.0 * u2) * vb + (u3 - u2) * h * mb


## Monotone (Fritsch-Carlson style) slope at knot [param i], in value per t.
static func _knot_slope(knots: Array, i: int) -> float:
	var n: int = knots.size()
	var d_prev: float = 0.0
	var d_next: float = 0.0
	if i > 0:
		d_prev = (float(knots[i][1]) - float(knots[i - 1][1])) / maxf(float(knots[i - 1][0]) - float(knots[i][0]), 0.001)
	if i < n - 1:
		d_next = (float(knots[i + 1][1]) - float(knots[i][1])) / maxf(float(knots[i][0]) - float(knots[i + 1][0]), 0.001)
	if i == 0:
		return d_next
	if i == n - 1:
		return d_prev
	if d_prev * d_next <= 0.0:
		return 0.0
	return 2.0 / (1.0 / d_prev + 1.0 / d_next)


## Piecewise-linear lookup in [[s, value], ...] sorted by s, clamped at the ends.
static func piecewise(points: Array, s: float) -> float:
	var n: int = points.size()
	if n == 0:
		return 0.0
	if s <= float(points[0][0]):
		return float(points[0][1])
	for i: int in range(1, n):
		var sb: float = float(points[i][0])
		if s <= sb:
			var sa: float = float(points[i - 1][0])
			var va: float = float(points[i - 1][1])
			var vb: float = float(points[i][1])
			if sb - sa <= 0.0001:
				return vb
			return lerpf(va, vb, (s - sa) / (sb - sa))
	return float(points[n - 1][1])


## Samples a Catmull-Rom spline through [param pts] (Array of [x, z]) every
## [param step] metres (approximately). Returns PackedVector2Array of (x, z).
static func sample_spline(pts: Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n: int = pts.size()
	if n == 0:
		return out
	var p: Array[Vector2] = []
	for q: Array in pts:
		p.append(Vector2(float(q[0]), float(q[1])))
	if n == 1:
		out.append(p[0])
		return out
	for i: int in n - 1:
		var p0: Vector2 = p[maxi(i - 1, 0)]
		var p1: Vector2 = p[i]
		var p2: Vector2 = p[i + 1]
		var p3: Vector2 = p[mini(i + 2, n - 1)]
		var seg_len: float = p1.distance_to(p2)
		var count: int = maxi(1, ceili(seg_len / step))
		for k: int in count:
			var t: float = float(k) / float(count)
			out.append(_catmull(p0, p1, p2, p3, t))
	out.append(p[n - 1])
	return out


static func _catmull(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 \
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


## Distance from point [param p] to segment [param a]-[param b].
static func dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var l2: float = ab.length_squared()
	if l2 < 0.000001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Channel cross-section: depth carved at distance [param d] from the centre
## line, for a channel [param width] wide and [param depth] deep. The middle
## [param floor_frac] of the width is flat; the banks follow a cosine.
static func channel_profile(d: float, width: float, depth: float, floor_frac: float) -> float:
	var half: float = width * 0.5
	if d >= half:
		return 0.0
	var flat: float = half * clampf(floor_frac, 0.0, 0.95)
	if d <= flat:
		return depth
	var u: float = (d - flat) / (half - flat)
	return depth * (0.5 + 0.5 * cos(PI * u))


## Island/bar bump: full [param height] inside the plateau, falling to zero
## across [param edge] metres at the rim. [param r] is the distance outside the
## plateau edge (negative inside).
static func bump_profile(r: float, height: float, edge: float) -> float:
	if r <= 0.0:
		return height
	if r >= edge:
		return 0.0
	var u: float = r / edge
	return height * (1.0 - u * u * (3.0 - 2.0 * u))


## Signed distance outside an ellipse centred at [param c] with half axes
## [param rx], [param rz], rotated by [param yaw] (radians). Approximate (scaled
## radial), good enough for terrain stamps.
static func ellipse_outside(p: Vector2, c: Vector2, rx: float, rz: float, yaw: float) -> float:
	var d: Vector2 = (p - c).rotated(-yaw)
	var nx: float = d.x / maxf(rx, 0.01)
	var nz: float = d.y / maxf(rz, 0.01)
	var r: float = sqrt(nx * nx + nz * nz)
	if r < 0.0001:
		return -minf(rx, rz)
	# First-order distance: (r - 1) divided by the gradient length of r.
	var gx: float = nx / maxf(rx, 0.01)
	var gz: float = nz / maxf(rz, 0.01)
	var grad: float = sqrt(gx * gx + gz * gz) / r
	return (r - 1.0) / maxf(grad, 0.0001)
