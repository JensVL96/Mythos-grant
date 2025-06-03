extends Button

func _on_QuitButton_focus_entered():
	add_theme_color_override("font_outline_color", Color(1, .32549020648003, 0))

func _on_QuitButton_focus_exited():
	add_theme_color_override("font_outline_color", Color(0, 0, 0))

func _on_pressed():
	get_tree().quit()

func _on_Area2D_area_entered(area):
	emit_signal("focus_entered")

func _on_Area2D_area_exted(area):
	emit_signal("focus_exited")

func _on_Button_mouse_entered():
	add_theme_color_override("font_outline_color", Color(1, 0.5, 0)) # Highlight color

func _on_Button_mouse_exited():
	add_theme_color_override("font_outline_color", Color(0, 0, 0)) # Default color
