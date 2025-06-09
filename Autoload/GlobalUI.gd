# GlobalUI.gd
extends Node

var navigator: UINavigator

func _ready():
	navigator = preload("res://UI/Common/Scripts/UINavigator.gd").new()
	add_child(navigator)

func setup_navigation(buttons: Array):
	navigator.setup(buttons)

func set_navigation_enabled(value: bool):
	print("trying to disable inputs Global 1")
	navigator.set_enabled(value)

func disable_navigation():
	print("trying to disable inputs Global 2")
	navigator.set_enabled(false)
	navigator.setup([])  # Clear any previous buttons
