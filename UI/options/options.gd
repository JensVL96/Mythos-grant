extends Control

# Node references
@onready var fullscreen_toggle = $HBoxContainer/VBoxContainer/FullscreenToggle
@onready var music_toggle = $HBoxContainer/VBoxContainer/MusicToggle
@onready var sound_toggle = $HBoxContainer/VBoxContainer/SoundToggle
@onready var volume_slider = $HBoxContainer/VBoxContainer/HBoxContainer/VolumeSlider
@onready var back_button = $HBoxContainer/VBoxContainer/BackButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set up slider range
	volume_slider.min_value = 0.0
	volume_slider.max_value = 2.0
	volume_slider.step = 0.01
	volume_slider.custom_minimum_size = Vector2(200, 0)

	# Initialize toggle states
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	music_toggle.button_pressed = !AudioServer.is_bus_mute(AudioServer.get_bus_index("Music"))
	sound_toggle.button_pressed = !AudioServer.is_bus_mute(AudioServer.get_bus_index("Sound"))
	
	# Set initial volume slider (volume_db from -80 to 0)
	var music_bus_index = AudioServer.get_bus_index("Music")
	var volume_db = AudioServer.get_bus_volume_db(music_bus_index)
	var volume_linear = clamp(db_to_linear(volume_db), 0.0, 2.0)
	volume_slider.value = db_to_linear(volume_db)  # Converts to 0.0 – 1.0
	
	# Connect signals
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	music_toggle.toggled.connect(_on_music_toggled)
	sound_toggle.toggled.connect(_on_sound_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	back_button.pressed.connect(_on_back_pressed)
	
	volume_slider.editable = music_toggle.button_pressed
	volume_slider.custom_minimum_size = Vector2(200, 0)

func _on_fullscreen_toggled(button_pressed: bool) -> void:
	print("Toggled fullscreen to: ", button_pressed)
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1280, 720))

#func _on_fullscreen_toggled(button_pressed: bool) -> void:
	#OS.window_fullscreen = button_pressed

func _on_music_toggled(button_pressed: bool) -> void:
	var music_index = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_mute(music_index, !button_pressed)
	volume_slider.editable = button_pressed
	## Implement music toggle logic
	## You might want to use an AudioServer bus for music
	#AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), !button_pressed)
	## Enable or disable the volume slider based on music toggle
	#volume_slider.editable = button_pressed


func _on_sound_toggled(button_pressed: bool) -> void:
	var sound_index = AudioServer.get_bus_index("Sound")
	AudioServer.set_bus_mute(sound_index, !button_pressed)
	## Implement sound effects toggle logic
	## You might want to use an AudioServer bus for sound effects
	#AudioServer.set_bus_mute(AudioServer.get_bus_index("Sound"), !button_pressed)

func _on_volume_changed(value: float) -> void:
	var music_index = AudioServer.get_bus_index("Music")
	var volume_db = linear_to_db(clamp(value, 0.001, 2.0))  # Avoid -inf from zero
	AudioServer.set_bus_volume_db(music_index, volume_db)
	## Convert slider value (usually 0 to 100) to decibels (-80 to 0)
	#var volume_db = linear_to_db(value / 100.0)
	## You might want to set this on your music bus
	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), volume_db)

func _on_back_pressed() -> void:
	# Return to the main menu
	get_tree().change_scene_to_file("res://UI/Titlescreen/titlescreen.tscn")
