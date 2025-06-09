# titlescreen.gd
extends Control

@onready var Music = $Music
#@onready var getPointer = $Pointer
@onready var buttons = [
	[$HBoxContainer/VBoxContainer/Play],
	[$HBoxContainer/VBoxContainer/Option],
	[$HBoxContainer/VBoxContainer/Credits],
	[$HBoxContainer/VBoxContainer/Exit]
]

var ui_navigator

func _ready():
	#MusicPlayer.volume_db = volume
	#MusicPlayer.play()
	#fade_in_music()
	
	GlobalMusic.ensure_playing()

	#var pointer_positions = [
		#Vector2(1100, 440), # PLAY
		#Vector2(1100, 540), # OPTIONS
		#Vector2(1100, 640), # CREDITS
		#Vector2(1100, 740)  # EXIT
	#]

	# Use the global navigator from the autoload singleton
	GlobalUI.setup_navigation(buttons)
	GlobalUI.navigator.connect("option_selected", Callable(self, "_on_option_selected"))
	GlobalUI.navigator.enabled = true

#func _on_option_selected(index):
	#match index:
		#0: # PLAY
			#await GlobalMusic.fade_out()
			#GlobalMusic.music_player.stop()
			#GlobalMusic.has_faded_in = false  # Reset for future menu entries
			#get_tree().change_scene_to_file("res://Stages/Test stage.tscn")
		#1: # OPTIONS
			#pass
			##print("Options selected")
		#2: # CREDITS
			#pass
		#3: # EXIT
			#get_tree().quit()
