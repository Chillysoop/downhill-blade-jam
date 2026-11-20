class_name CarveGuide
extends MeshInstance3D
## Faint lines drawn on the ground ahead of the skater: the tightest carve
## you can make left and right at the current speed, and the arc you are
## carving now. Faster means wider; a tuck widens them too.

## Metres of arc drawn ahead.
@export var arc_length: float = 14.0
## Opacity of the tightest-turn arcs and of the current arc.
@export var limit_alpha: float = 0.45
@export var current_alpha: float = 0.6
## Width (m) of the painted lines.
@export var line_width: float = 0.09

var _skater: Skater
var _im := ImmediateMesh.new()


func _ready() -> void:
	_skater = get_parent() as Skater
	top_level = true
	mesh = _im
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.no_depth_test = false
	material_override = m


func _process(_dt: float) -> void:
	_im.clear_surfaces()
	global_transform = Transform3D.IDENTITY
	if _skater == null or _skater.state != Skater.State.GROUNDED:
		return
	var speed: float = _skater.get_speed()
	if speed < 1.0:
		return
	var n: Vector3 = _skater.ground_normal
	var travel: Vector3 = SkateMath.project_on_plane(_skater.velocity, n).normalized()
	var origin: Vector3 = _skater.get_global_transform_interpolated().origin + n * 0.05
	var tight: float = SkateMath.tightest_radius(_skater.tuning, speed, _skater.tuck_amount)
	_arc(origin, travel, n, tight, Color(1, 1, 1, limit_alpha))
	_arc(origin, travel, n, -tight, Color(1, 1, 1, limit_alpha))
	var rate: float = _skater.turn_rate()
	if absf(rate) > 0.02:
		var hot: bool = _skater.grip_usage >= 1.0
		var col := Color(1.0, 0.4, 0.3, current_alpha) if hot else Color(0.35, 1.0, 0.55, current_alpha)
		_arc(origin + n * 0.01, travel, n, speed / rate, col)


## Adds an arc of signed [param radius] (positive turns right) to the mesh.
func _arc(origin: Vector3, dir: Vector3, n: Vector3, radius: float, col: Color) -> void:
	var r: float = absf(radius)
	var sweep: float = minf(arc_length / maxf(r, 0.01), PI)
	var steps: int = 24
	var right: Vector3 = dir.cross(n).normalized()
	var centre: Vector3 = origin + right * radius
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i: int in range(0, steps + 1):
		var a: float = sweep * float(i) / float(steps)
		var off: Vector3 = (origin - centre).rotated(n, -a * signf(radius))
		var p: Vector3 = centre + off
		var side: Vector3 = off.normalized() * line_width * 0.5
		var fade: float = 1.0 - float(i) / float(steps)
		var c := Color(col.r, col.g, col.b, col.a * (fade * 0.9 + 0.1))
		_im.surface_set_color(c)
		_im.surface_add_vertex(p - side)
		_im.surface_set_color(c)
		_im.surface_add_vertex(p + side)
	_im.surface_end()
