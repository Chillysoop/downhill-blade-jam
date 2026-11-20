class_name CarveMeter
extends Control
## See-through carve meter at the bottom of the screen: a half dial whose
## needle is your lean, a red band where the wheels' grip runs out at the
## current speed (lean into it and you wash wide), and the turn radius you are
## carving next to the tightest one this speed allows.

## The skater being shown. Set by the HUD's owner.
var skater: Skater
## Dial radius in pixels.
@export var dial_radius: float = 92.0
## Overall opacity of the meter.
@export var opacity: float = 0.55

var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font


func _process(_dt: float) -> void:
	queue_redraw()


## Needle position (-1 full left .. 1 full right) for [param lean] radians
## with [param tuck_amount] of a tuck.
static func needle(t: SkaterTuning, lean: float, tuck_amount: float) -> float:
	return clampf(lean / SkateMath.lean_limit(t, tuck_amount), -1.0, 1.0)


## Share of full lean (0..) at which the wheels' grip runs out at
## [param speed]: 1 or more means a full lean holds.
static func grip_edge(t: SkaterTuning, speed: float, tuck_amount: float) -> float:
	return atan(SkateMath.side_grip_at(t, speed)) / SkateMath.lean_limit(t, tuck_amount)


## A radius as the meter prints it: tenths under 2 m, whole metres above.
static func radius_text(r: float) -> String:
	if r < 2.0:
		return "%.1f m" % r
	return "%d m" % roundi(r)


func _draw() -> void:
	if skater == null or skater.tuning == null or skater.state != Skater.State.GROUNDED:
		return
	var t: SkaterTuning = skater.tuning
	var speed: float = skater.get_speed()
	var c := Vector2(size.x * 0.5, size.y)
	var r: float = dial_radius
	var base := Color(0.1, 0.1, 0.12, 0.3 * opacity / 0.55)
	# Dial: a half ring from full left (PI) to full right (2 PI).
	draw_arc(c, r, PI, TAU, 48, base, 10.0, true)
	var edge: float = grip_edge(t, speed, skater.tuck_amount)
	if edge < 1.0:
		var wash := Color(1.0, 0.3, 0.25, 0.5 * opacity / 0.55)
		var a0: float = PI * 0.5 * edge
		draw_arc(c, r, PI * 1.5 + a0, TAU, 16, wash, 10.0, true)
		draw_arc(c, r, PI, PI * 1.5 - a0, 16, wash, 10.0, true)
	var k: float = needle(t, skater.lean, skater.tuck_amount)
	var ang: float = PI * 1.5 + k * PI * 0.5
	var tip: Vector2 = c + Vector2(cos(ang), sin(ang)) * (r + 8.0)
	var hot: bool = absf(k) > edge
	var needle_col := Color(1.0, 0.45, 0.35, opacity + 0.3) if hot else Color(1, 1, 1, opacity + 0.3)
	draw_line(c + Vector2(cos(ang), sin(ang)) * (r - 18.0), tip, needle_col, 4.0, true)
	# Numbers: the radius you are carving now, and the tightest at this speed.
	var tight: float = SkateMath.tightest_radius(t, speed, skater.tuck_amount)
	var rate: float = absf(skater.turn_rate())
	var now: String = "straight" if rate < 0.02 or speed < 0.5 else radius_text(speed / rate)
	var text: String = "turn %s   tightest %s" % [now, radius_text(tight)]
	var fs: int = 18
	var w: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	var at: Vector2 = c + Vector2(-w * 0.5, -r * 0.3)
	draw_string_outline(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, opacity * 0.6))
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, opacity + 0.3))
