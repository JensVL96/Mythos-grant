# UINavigator.gd
extends Node
class_name UINavigator

signal option_selected(index)

enum InputMode { KEYBOARD, MOUSE }

var current_state = 0
var current_input_mode = InputMode.KEYBOARD

var enabled: bool = true

var button_grid: Array = []
var current_row: int = 0
var current_col: int = 0
#var pointer_node: Node2D = null
#var pointer_positions: Array = []

func setup(new_grid: Array):
	# Disconnect old signals safely
	for row in button_grid:
		for btn in row:
			if btn != null and is_instance_valid(btn):
				if btn.is_connected("mouse_entered", Callable(self, "_on_button_mouse_entered")):
					btn.disconnect("mouse_entered", Callable(self, "_on_button_mouse_entered"))

	# Apply new grid
	button_grid = new_grid
	current_row = 0
	current_col = 0
	
	if button_grid.size() == 0 or not enabled:
		print("grid is empty")
		return

	_update_highlight()

	# Connect new signals
	for i in range(button_grid.size()):
		for j in range(button_grid[i].size()):
			var btn = button_grid[i][j]
			if btn != null and is_instance_valid(btn):
				btn.connect("mouse_entered", Callable(self, "_on_button_mouse_entered").bind(btn))

func _process(_delta):
	if not enabled or button_grid.size() == 0:
		# print for debug:
		return

	if Input.is_action_just_pressed("ui_up") or _is_action_just_pressed_prefix("up_"):
		current_row = (current_row - 1 + button_grid.size()) % button_grid.size()
		current_col = min(current_col, button_grid[current_row].size() - 1)
		_update_highlight()

	elif Input.is_action_just_pressed("ui_down") or _is_action_just_pressed_prefix("down_"):
		current_row = (current_row + 1) % button_grid.size()
		current_col = min(current_col, button_grid[current_row].size() - 1)
		_update_highlight()

	elif Input.is_action_just_pressed("ui_left") or _is_action_just_pressed_prefix("left_"):
		current_col = (current_col - 1 + button_grid[current_row].size()) % button_grid[current_row].size()
		_update_highlight()

	elif Input.is_action_just_pressed("ui_right") or _is_action_just_pressed_prefix("right_"):
		current_col = (current_col + 1) % button_grid[current_row].size()
		_update_highlight()

	elif enabled and Input.is_action_just_pressed("ui_accept"):  # <-- add `enabled` here
		var btn = button_grid[current_row][current_col]
		var flat_index = _get_flat_index(btn)
		if flat_index != -1:
			emit_signal("option_selected", flat_index)

func _on_button_mouse_entered(btn):
	if not enabled:
		return
	current_input_mode = InputMode.MOUSE
	for i in range(button_grid.size()):
		for j in range(button_grid[i].size()):
			if button_grid[i][j] == btn:
				current_row = i
				current_col = j
				_update_highlight()
				return

func _update_highlight():
	if current_input_mode == InputMode.KEYBOARD:
		_highlight_button(current_row, current_col)

func _highlight_button(row: int, col: int):
	_clear_all_highlights()
	if row < button_grid.size() and col < button_grid[row].size():
		var btn = button_grid[row][col]
		btn.grab_focus()
		btn.add_theme_color_override("font_outline_color", Color(1, 0.3, 0))  # orange

func _clear_all_highlights():
	for row in button_grid:
		for btn in row:
			btn.add_theme_color_override("font_outline_color", Color(0, 0, 0))  # default black

func _get_flat_index(target_btn):
	var flat_index = 0
	for row in button_grid:
		for btn in row:
			if btn == target_btn:
				return flat_index
			flat_index += 1
	return -1

func _is_action_just_pressed_prefix(prefix: String) -> bool:
	for action in InputMap.get_actions():
		if action.begins_with(prefix) and Input.is_action_just_pressed(action):
			return true
	return false

func set_enabled(value: bool):
	print("trying to disable inputs local: " + str(value))
	enabled = value
