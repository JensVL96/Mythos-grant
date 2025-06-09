extends Control

@onready var back_button = $VBoxContainer/BackButton

@onready var buttons = [
	[$VBoxContainer/BackButton]
]

var ui_navigator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	
	# Use the global navigator from the autoload singleton
	GlobalUI.setup_navigation(buttons)
	GlobalUI.navigator.connect("option_selected", Callable(self, "_on_option_selected"))

func _on_back_pressed() -> void:
	# Return to the main menu
	get_tree().change_scene_to_file("res://UI/Titlescreen/titlescreen.tscn")
