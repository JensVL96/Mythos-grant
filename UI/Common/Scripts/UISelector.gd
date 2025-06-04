# UISelector.gd
extends Node

enum InputMode { KEYBOARD, MOUSE }

var buttons: Array[Button] = []
var current_index := 0
var current_input_mode = InputMode.KEYBOARD
var pointer: Node = null  # Optional visual pointer

func setup(buttons: Array[Button], pointer: Node = null):
	buttons = buttons
	pointer = pointer
	_update_highlight()

func _process(_delta):
	if buttons.is_empty(): return

	if Input.is_action_just_pressed("up_1") or Input.is_action_just_pressed("up_2"):
		current_input_mode = InputMode.KEYBOARD
		current_index = (current_index - 1 + buttons.size()) % buttons.size()
		_update_highlight()
	elif Input.is_action_just_pressed("down_1") or Input.is_action_just_pressed("down_2"):
		current_input_mode = InputMode.KEYBOARD
		current_index = (current_index + 1) % buttons.size()
		_update_highlight()
	elif Input.is_action_just_pressed("ui_accept"):
		buttons[current_index].emit_signal("pressed")

func _update_highlight():
	for i in buttons.size():
		var color = Color(1, 0.3, 0) if i == current_index else Color(0, 0, 0)
		buttons[i].add_theme_color_override("font_outline_color", color)
		buttons[i].grab_focus()
	if pointer:
		pointer.global_position = buttons[current_index].global_position + Vector2(-30, 0)
