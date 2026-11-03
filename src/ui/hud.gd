class_name Hud
extends CanvasLayer
## Run timer, speed readout, crash/finish banner and a controls reminder.

var _timer_label: Label
var _speed_label: Label
var _best_label: Label
var _banner: Label
var _banner_time: float = 0.0


func _ready() -> void:
	_timer_label = _label(Vector2(24, 18), 44)
	_speed_label = _label(Vector2(24, 76), 28)
	_best_label = _label(Vector2(24, 114), 22)
	_banner = _label(Vector2(0, 0), 56)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.offset_top = 160.0
	_banner.offset_bottom = 240.0
	var hint := _label(Vector2(24, 0), 18)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_left = 24.0
	hint.offset_top = -44.0
	hint.offset_bottom = -12.0
	hint.text = "A/D steer   W push / tuck   S brake   Space hold+release jump (tap = hop)   R restart"
	hint.modulate = Color(1, 1, 1, 0.75)


## Updates the timer and speed readouts.
func show_run(time_s: float, speed_ms: float, best_s: float) -> void:
	_timer_label.text = format_time(time_s)
	_speed_label.text = "%d km/h" % roundi(speed_ms * 3.6)
	_best_label.text = "Best  " + (format_time(best_s) if best_s > 0.0 else "--:--.--")


## Shows a big centred message for [param seconds].
func flash(text: String, color: Color, seconds: float = 1.6) -> void:
	_banner.text = text
	_banner.modulate = color
	_banner_time = seconds


func _process(dt: float) -> void:
	if _banner_time > 0.0:
		_banner_time -= dt
		if _banner_time <= 0.0:
			_banner.text = ""


## Formats seconds as M:SS.cc.
static func format_time(t: float) -> String:
	var m: int = int(t / 60.0)
	var s: float = t - m * 60.0
	return "%d:%05.2f" % [m, s]


func _label(pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 8)
	add_child(l)
	return l
