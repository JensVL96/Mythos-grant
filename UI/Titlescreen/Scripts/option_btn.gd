extends Button

@export var path = 'res://UI/options/options.tscn'

func _on_OptionsButton_focus_entered():
	add_theme_color_override("font_outline_color", Color(1, .32549020648003, 0))

func _on_OptionsButton_focus_exited():
	add_theme_color_override("font_outline_color", Color(0, 0, 0))

func _on_pressed():
	if path != '':
		get_tree().change_scene_to_file(path)

func _on_Area2D_area_entered(_area):
	emit_signal("focus_entered")

func _on_Area2D_area_exted(_area):
	emit_signal("focus_exited")

func _on_Button_mouse_entered():
	add_theme_color_override("font_outline_color", Color(1, 0.5, 0)) # Highlight color

func _on_Button_mouse_exited():
	add_theme_color_override("font_outline_color", Color(0, 0, 0)) # Default color
