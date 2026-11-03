extends Node
## Registers the game's input actions at startup so keyboard and gamepad
## bindings live in one readable place instead of serialized project settings.
##
## Actions: steer_left, steer_right, forward (push/tuck), brake, jump, restart.


func _ready() -> void:
	_add_action("steer_left", [KEY_A, KEY_LEFT], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_add_action("steer_right", [KEY_D, KEY_RIGHT], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_add_action("forward", [KEY_W, KEY_UP], [], [[JOY_AXIS_TRIGGER_RIGHT, 1.0]])
	_add_action("brake", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_TRIGGER_LEFT, 1.0]])
	_add_action("jump", [KEY_SPACE], [JOY_BUTTON_A], [])
	_add_action("restart", [KEY_R, KEY_BACKSPACE], [JOY_BUTTON_Y, JOY_BUTTON_BACK], [])


## Creates [param action] (if missing) and binds the given keys, joypad
## buttons and joypad axes ([axis, direction] pairs) to it.
func _add_action(action: StringName, keys: Array, buttons: Array, axes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for k: int in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b: int in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b
		jb.device = -1
		InputMap.action_add_event(action, jb)
	for pair: Array in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = pair[0]
		jm.axis_value = pair[1]
		jm.device = -1
		InputMap.action_add_event(action, jm)
