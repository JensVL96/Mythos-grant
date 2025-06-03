extends Node

signal option_selected(index)

enum InputMode { KEYBOARD, MOUSE }

var current_state = 0
var current_input_mode = InputMode.KEYBOARD

var buttons: Array = []
var pointer_node: Node2D = null
var pointer_positions: Array = []

func _init(btns: Array, ptr_node: Node2D, ptr_pos: Array):
	buttons = btns
	pointer_node = ptr_node
	pointer_positions = ptr_pos
	
	# Connect mouse hover signals on each button's Area2D
	for i in range(buttons.size()):
		var area = buttons[i].get_node("Area2D")
		if area:
			area.connect("mouse_entered", Callable(self, "_on_button_mouse_entered").bind(i))
			area.connect("mouse_exited", Callable(self, "_on_button_mouse_exited").bind(i))
		
	_update_highlight()

func _process(delta):
	# Keyboard input moves the current_state and updates highlight
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("up_2") or Input.is_action_just_pressed("up_1") or Input.is_action_just_pressed("left_1") or Input.is_action_just_pressed("left_2"):
		current_input_mode = InputMode.KEYBOARD
		current_state -= 1
		if current_state < 0:
			current_state = buttons.size() - 1
		_update_highlight()
	elif Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("down_2") or Input.is_action_just_pressed("down_1") or Input.is_action_just_pressed("right_1") or Input.is_action_just_pressed("right_2"):
		current_input_mode = InputMode.KEYBOARD
		current_state = (current_state + 1) % buttons.size()
		_update_highlight()
	
	if Input.is_action_just_pressed("ui_accept"):
		emit_signal("option_selected", current_state)

	# Move the pointer based on current_state
	if pointer_node and current_state < pointer_positions.size():
		pointer_node.global_position = pointer_positions[current_state]

func _on_button_mouse_entered(index):
	current_input_mode = InputMode.MOUSE
	current_state = index
	_update_highlight()

func _on_button_mouse_exited(index):
	# When mouse leaves, if in mouse mode, clear highlight (or restore keyboard highlight)
	if current_input_mode == InputMode.MOUSE:
		_clear_all_highlights()
		# Re-highlight the current_state button if it's still in keyboard mode or if the mouse is not over any other button
		if current_input_mode == InputMode.KEYBOARD or not get_viewport().get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			_highlight_button(current_state)

func _highlight_button(index):
	# Clear all first
	_clear_all_highlights()
	# Highlight font outline on hovered button
	var btn = buttons[index]
	btn.add_theme_color_override("font_outline_color", Color(1, 0.3, 0))  # example highlight color

func _clear_all_highlights():
	for btn in buttons:
		btn.add_theme_color_override("font_outline_color", Color(0, 0, 0))  # reset to black

func _update_highlight():
	if current_input_mode == InputMode.KEYBOARD:
		_clear_all_highlights()
		_highlight_button(current_state)
		buttons[current_state].grab_focus()
