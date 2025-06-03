extends Control

@onready var MusicPlayer = $MusicPlayer
@onready var getPointer = $Pointer
@onready var buttons = [
	$HBoxContainer/VBoxContainer/Play,
	$HBoxContainer/VBoxContainer/Option,
	$HBoxContainer/VBoxContainer/Exit
]

var ui_navigator

var volume = -40  # Start low

func _ready():
	MusicPlayer.volume_db = volume
	MusicPlayer.play()
	fade_in_music()

	var pointer_positions = [
		Vector2(1100, 440), # PLAY
		Vector2(1100, 540), # OPTIONS
		Vector2(1100, 640)  # EXIT
	]

	ui_navigator = preload("res://UI/Common/Scripts/UINavigator.gd").new(buttons, getPointer, pointer_positions)
	add_child(ui_navigator)
	ui_navigator.connect("option_selected", Callable(self, "_on_option_selected"))

func fade_in_music():
	var tween = create_tween()
	tween.tween_property(MusicPlayer, "volume_db", 0, 3.0)  # Fade to 0dB in 3 seconds

func _on_option_selected(index):
	match index:
		0: # PLAY
			get_tree().change_scene_to_file("res://Stages/test_stage.tscn")
		1: # OPTIONS
			print("Options selected")
		2: # EXIT
			get_tree().quit()
