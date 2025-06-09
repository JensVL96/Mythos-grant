extends Button

signal hovered

@export var path = 'res://Stages/Test stage.tscn'
@onready var tutorial = $"../../../Control/Tutorial"

func _on_SinglePlayerButton_focus_entered():
	add_theme_color_override("font_outline_color", Color(1, .32549020648003, 0))

func _on_SinglePlayerButton_focus_exited():
	add_theme_color_override("font_outline_color", Color(0, 0, 0))

func _on_pressed():
	if tutorial:
		tutorial.visible = true
	GlobalUI.navigator.set_enabled(false)
	GlobalUI.setup_navigation([])

func _on_Area2D_area_entered(_area):
	grab_focus()
	#emit_signal("focus_entered")

func _ready():
	$Area2D.connect("area_entered", Callable(self, "_on_area_entered"))

	#tutorial.visible = true

func _on_area_entered(_area):
	emit_signal("hovered")

func _on_area_exited(area):
	if GlobalUI.navigator:
		GlobalUI.navigator.enabled = true

func _on_Button_mouse_entered():
	add_theme_color_override("font_outline_color", Color(1, 0.5, 0)) # Highlight color

func _on_Button_mouse_exited():
	add_theme_color_override("font_outline_color", Color(0, 0, 0)) # Default color

var can_continue = true
var continue_cooldown = 0.3 # 300ms cooldown to prevent accidental double skips

func _unhandled_input(event):
	if tutorial and tutorial.visible and can_continue:
		if event is InputEventMouseButton and event.pressed:
			_continue()
			event.set_input_as_handled()
		elif event is InputEventKey and event.pressed:
			_continue()
			event.set_input_as_handled()
		elif event is InputEventAction and event.pressed and event.action == "ui_accept" or Input.is_action_just_pressed("attack_3") or Input.is_action_just_pressed("attack_4"):
			_continue()
	else:
		get_viewport().set_input_as_handled()

func _continue():
	can_continue = false
	get_tree().create_timer(continue_cooldown).timeout.connect(func(): can_continue = true)
	if path != "":
		get_tree().change_scene_to_file(path)

func _on_image_clicked(event):
	if !can_continue:
		return
	
	if event is InputEventKey and event.pressed:
		# Any key press will continue
		can_continue = false
		get_tree().create_timer(continue_cooldown).timeout.connect(func(): can_continue = true)
		if path != "":
			get_tree().change_scene_to_file(path)
	elif event is InputEventMouseButton and event.pressed:
		# Mouse click will continue
		can_continue = false
		get_tree().create_timer(continue_cooldown).timeout.connect(func(): can_continue = true)
		if path != "":
			get_tree().change_scene_to_file(path)
	elif Input.is_action_just_pressed("ui_accept"):  # <-- add `enabled` here
		# Controller click will continue
		can_continue = false
		get_tree().create_timer(continue_cooldown).timeout.connect(func(): can_continue = true)
		if path != "":
			get_tree().change_scene_to_file(path)
