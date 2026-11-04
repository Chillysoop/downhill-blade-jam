class_name RunMenu
extends CanvasLayer
## Finish screen, pause menu and map select (design/quick-specs/run-menus-2026-11-04.md).
## Builds its own controls and only emits signals; main.gd decides what each
## choice does. Works with mouse, keyboard and gamepad (ui_* actions), and keeps
## running while the game is paused.

## "Ride again" / "Restart run".
signal restart_requested
## "Resume", or the pause button pressed while the pause menu is open.
signal resume_requested
## The pause button pressed during a run with no menu open.
signal pause_requested
## A course picked in map select.
signal map_chosen(course_id: String)
## "Quit game".
signal quit_requested

enum Screen { NONE, FINISH, PAUSE, MAPS }

const ACCENT := Color(0.98, 0.62, 0.22)
const GOOD := Color(0.45, 1.0, 0.55)
const BAD := Color(1.0, 0.5, 0.4)

## Set by main: opens map select (main owns the catalog and records).
var open_maps: Callable
## Which panel is showing.
var panel: Screen = Screen.NONE
var _return_panel: Screen = Screen.NONE
var _root: Control
var _box: VBoxContainer
var _blurb: Label
var _last_finish: Callable


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = _make_theme()
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(560, 0)
	center.add_child(card)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 12)
	card.add_child(_box)
	_root.visible = false


## True while any panel is showing.
func is_open() -> bool:
	return panel != Screen.NONE


## Results panel after crossing the finish. [param prev_best] is the best time
## before this run (0 = none); the split arrays are seconds since the start.
func show_finish(course_name: String, time_s: float, prev_best: float, splits: Array[float],
		prev_best_splits: Array[float], split_names: Array[String]) -> void:
	_last_finish = show_finish.bind(course_name, time_s, prev_best, splits, prev_best_splits, split_names)
	_clear()
	var pb: bool = prev_best <= 0.0 or time_s < prev_best
	_add_label(course_name.to_upper(), 20, Color(1, 1, 1, 0.6))
	_add_label("NEW BEST!" if pb else "FINISH", 40, GOOD if pb else ACCENT)
	_add_label(Hud.format_time(time_s), 64, Color.WHITE)
	if prev_best > 0.0:
		var d: float = time_s - prev_best
		_add_label("Previous best  %s   (%s)" % [Hud.format_time(prev_best), Hud.format_delta(d)],
			22, GOOD if d < 0.0 else BAD)
	else:
		_add_label("First finish on this map. Now go find a faster line.", 20, Color(1, 1, 1, 0.75))
	for i: int in splits.size():
		var name: String = split_names[i] if i < split_names.size() else "Split %d" % (i + 1)
		var line: String = "%s   %s" % [name, Hud.format_time(splits[i])]
		var col := Color(1, 1, 1, 0.85)
		if i < prev_best_splits.size():
			var sd: float = splits[i] - prev_best_splits[i]
			line += "   (%s)" % Hud.format_delta(sd)
			col = GOOD if sd < 0.0 else BAD
		_add_label(line, 18, col)
	_add_spacer()
	var first := _add_button("Ride again   [R]", restart_requested.emit)
	_add_button("Choose map", _open_maps_from.bind(Screen.FINISH))
	_add_button("Quit game", quit_requested.emit)
	_open(Screen.FINISH, first)


## Pause menu during a run.
func show_pause() -> void:
	_clear()
	_add_label("PAUSED", 40, ACCENT)
	_add_label("The clock is stopped.", 18, Color(1, 1, 1, 0.7))
	_add_spacer()
	var first := _add_button("Resume   [Esc]", resume_requested.emit)
	_add_button("Restart run   [R]", restart_requested.emit)
	_add_button("Choose map", _open_maps_from.bind(Screen.PAUSE))
	_add_button("Quit game", quit_requested.emit)
	_open(Screen.PAUSE, first)


## Map select: every course in [param catalog] with its saved best time.
func show_maps(catalog: CourseCatalog, records: RunRecords, current_id: String) -> void:
	_clear()
	_add_label("CHOOSE MAP", 40, ACCENT)
	var focus: Button = null
	for e: Dictionary in catalog.courses:
		var best: float = records.best_time(e["id"])
		var text: String = "%s      Best %s" % [e["name"], Hud.format_time(best) if best > 0.0 else "--:--.--"]
		if e["id"] == current_id:
			text = "> " + text
		var b := _add_button(text, map_chosen.emit.bind(e["id"]))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var blurb: String = e["blurb"]
		b.focus_entered.connect(func() -> void: _blurb.text = blurb)
		b.mouse_entered.connect(func() -> void: _blurb.text = blurb)
		if focus == null or e["id"] == current_id:
			focus = b
	_blurb = _add_label("", 18, Color(1, 1, 1, 0.75))
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blurb.custom_minimum_size = Vector2(520, 48)
	_add_button("Back   [Esc]", _back)
	_open(Screen.MAPS, focus)


## Hides whatever is showing.
func hide_menu() -> void:
	panel = Screen.NONE
	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if panel == Screen.PAUSE and event.is_action_pressed("restart"):
		get_viewport().set_input_as_handled()
		restart_requested.emit()
		return
	if not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	match panel:
		Screen.NONE:
			pause_requested.emit()
		Screen.PAUSE:
			resume_requested.emit()
		Screen.MAPS:
			_back()
		Screen.FINISH:
			pass


func _open_maps_from(from: Screen) -> void:
	_return_panel = from
	if open_maps.is_valid():
		open_maps.call()


func _back() -> void:
	if _return_panel == Screen.FINISH and _last_finish.is_valid():
		_last_finish.call()
	else:
		show_pause()


func _open(p: Screen, focus: Button) -> void:
	panel = p
	_root.visible = true
	if focus:
		focus.grab_focus.call_deferred()


func _clear() -> void:
	for c: Node in _box.get_children():
		_box.remove_child(c)
		c.queue_free()


func _add_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_box.add_child(l)
	return l


func _add_spacer() -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, 8)
	_box.add_child(s)


func _add_button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 54)
	b.pressed.connect(on_press)
	_box.add_child(b)
	return b


func _make_theme() -> Theme:
	var t := Theme.new()
	var card := StyleBoxFlat.new()
	card.bg_color = Color(0.07, 0.08, 0.11, 0.94)
	card.set_corner_radius_all(14)
	card.set_content_margin_all(32)
	card.border_color = Color(1, 1, 1, 0.08)
	card.set_border_width_all(1)
	t.set_stylebox(&"panel", &"PanelContainer", card)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1, 1, 1, 0.07)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(12)
	normal.content_margin_left = 20.0
	normal.content_margin_right = 20.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1, 1, 1, 0.16)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.bg_color = Color(ACCENT, 0.28)
	focus.border_color = ACCENT
	focus.set_border_width_all(3)
	t.set_stylebox(&"normal", &"Button", normal)
	t.set_stylebox(&"hover", &"Button", hover)
	t.set_stylebox(&"pressed", &"Button", focus)
	t.set_stylebox(&"focus", &"Button", focus)
	t.set_font_size(&"font_size", &"Button", 26)
	t.set_color(&"font_color", &"Button", Color(1, 1, 1, 0.9))
	t.set_color(&"font_focus_color", &"Button", Color.WHITE)
	t.set_color(&"font_hover_color", &"Button", Color.WHITE)
	t.set_color(&"font_outline_color", &"Label", Color(0, 0, 0, 0.6))
	t.set_constant(&"outline_size", &"Label", 4)
	return t
