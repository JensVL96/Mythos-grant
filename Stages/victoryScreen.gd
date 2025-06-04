# VictoryScreen.gd
extends Control

@onready var btn_retry = $VBoxContainer/HBoxContainer2/ButtonRetry
@onready var btn_exit  = $VBoxContainer/HBoxContainer2/ButtonExit

var UINavigator = preload("res://UI/Common/Scripts/UINavigator.gd")

func _ready():
	var ui_navigator = UINavigator.new([btn_retry, btn_exit], $Pointer, [Vector2(500, 500), Vector2(500, 600)])
	add_child(ui_navigator)
	ui_navigator.option_selected.connect(_on_option_selected)

	# Disable player movement when victory screen is active
	for player in get_tree().get_nodes_in_group("players"):
		if player.has_method("set_movement_enabled"):
			player.set_movement_enabled(false)

func _on_option_selected(index):
	match index:
		0: # Retry button
			get_tree().change_scene_to_file("res://Stages/Test stage.tscn")
		1: # Exit button
			get_tree().quit()

func _exit_tree():
	# Re-enable player movement when victory screen is closed
	for player in get_tree().get_nodes_in_group("players"):
		if player.has_method("set_movement_enabled"):
			player.set_movement_enabled(true)
