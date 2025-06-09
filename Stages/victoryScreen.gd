# VictoryScreen.gd
extends Control

@onready var btn_retry = $HBoxContainer/VBoxContainer/HBoxContainer2/ButtonRetry
@onready var btn_exit  = $HBoxContainer/VBoxContainer/HBoxContainer2/ButtonExit
@onready var win_label = $HBoxContainer/VBoxContainer/winningPlayer
@onready var red_score = $HBoxContainer/VBoxContainer/Scoreboard/redWrap/RedSide/redScore
@onready var blue_score = $HBoxContainer/VBoxContainer/Scoreboard/blueWrap/BlueSide/blueScore
@onready var btn_game1 = $"HBoxContainer/VBoxContainer/GamesContainer/VBoxContainer/HBoxContainer/1‐game"
@onready var btn_game3 = $"HBoxContainer/VBoxContainer/GamesContainer/VBoxContainer/HBoxContainer/3‐game"
@onready var btn_game5 = $"HBoxContainer/VBoxContainer/GamesContainer/VBoxContainer/HBoxContainer/5‐game"
@onready var hb1    = $"../HealthbarP1"
@onready var hb2    = $"../HealthbarP2"
@onready var BL1 = $HBoxContainer/Player1Config/InputButtons/ButtonLeft
@onready var BR1 = $HBoxContainer/Player1Config/InputButtons/ButtonRight
@onready var BL2 = $HBoxContainer/Player2Config/InputButtons/ButtonLeft
@onready var BR2 = $HBoxContainer/Player2Config/InputButtons/ButtonRight


signal retry_pressed
signal exit_pressed
signal game_count_selected(count: int)
signal player_input_changed(player_side: String, control: String)

var button_grid = [
	[BL1, BR1],                      # Top left: Player 1 input
	[btn_game1, btn_game3, btn_game5],  # Center: Game count
	[BL2, BR2],                      # Top right: Player 2 input
	[btn_retry, btn_exit]           # Bottom row: Retry & Exit
]

func _ready():
	# Use the global navigator from the autoload singleton
	
	GlobalUI.setup_navigation(button_grid)
	GlobalUI.navigator.connect("option_selected", Callable(self, "_on_option_selected"))

	
	#defaults
	btn_game1.set_pressed(true)
	red_score.text = "0"
	blue_score.text = "0"
	$".".visible = true

	btn_retry.pressed.connect(func(): emit_signal("retry_pressed"))
	btn_exit.pressed.connect(func(): emit_signal("exit_pressed"))
	# Connect visibility changed signal to detect when VictoryScreen is shown/hidden
	connect("visibility_changed", Callable(self, "_on_visibility_changed"))

	# Call once to set initial state (usually hidden)
	_on_visibility_changed()

	btn_game1.toggled.connect(_on_game_toggled.bind(1), CONNECT_DEFERRED)
	btn_game3.toggled.connect(_on_game_toggled.bind(3), CONNECT_DEFERRED)
	btn_game5.toggled.connect(_on_game_toggled.bind(5), CONNECT_DEFERRED)
	
	btn_game1.focus_mode = Control.FOCUS_ALL
	btn_game3.focus_mode = Control.FOCUS_ALL
	btn_game5.focus_mode = Control.FOCUS_ALL
	
	BL1.toggled.connect(_on_player1_input_toggled.bind(BL1))
	BR1.toggled.connect(_on_player1_input_toggled.bind(BR1))
	BL2.toggled.connect(_on_player2_input_toggled.bind(BL2))
	BR2.toggled.connect(_on_player2_input_toggled.bind(BR2))
	
	# Defaults
	BR1.set_pressed(true)
	BR2.set_pressed(true)

	# Disable player movement when victory screen is active
	for player in get_tree().get_nodes_in_group("players"):
		if player.has_method("set_movement_enabled"):
			print("VictoryScreen _ready(): Disabling movement on player id %d" % player.player_id)
			player.set_movement_enabled(false)
		else:
			print("VictoryScreen _ready(): Player id %d has no set_movement_enabled()" % player.player_id)

# Handler for Player1Config toggle buttons
func _on_player1_input_toggled(pressed: bool, toggled_button: Button):
	if not pressed:
		return
	# Toggle off the other button
	if toggled_button == BL1:
		BR1.set_pressed(false)
		emit_signal("player_input_changed", "red", "key")
	else:
		BL1.set_pressed(false)
		emit_signal("player_input_changed", "red", "con")

func _on_player2_input_toggled(pressed: bool, toggled_button: Button):
	if not pressed:
		return
	if toggled_button == BL2:
		BR2.set_pressed(false)
		emit_signal("player_input_changed", "blue", "key")
	else:
		BL2.set_pressed(false)
		emit_signal("player_input_changed", "blue", "con")

func update_healthbar(player_id: int, lives: int) -> void:
	lives = clamp(lives, 0, 5)
	if str(lives) == '0':
		return

	if player_id == 1:
		hb1.play(str(lives))
	else:
		hb2.play(str(lives))


#func _on_option_selected(index):
	#match index:
		#0: # Retry button
			#get_tree().change_scene_to_file("res://Stages/Test stage.tscn")
		#1: # Exit button
			#get_tree().quit()

func _on_game_toggled(pressed: bool, count: int):
	if pressed:
		emit_signal("game_count_selected", count)

func update_scores(score1: int, score2: int):
	red_score.text = str(score1)
	blue_score.text = str(score2)

func show_winner(player_id: int):
	win_label.text = "Blue Player Wins!" if player_id == 1 else "Red Player Wins!"

func set_game_button(count: int):
	match count:
		1: btn_game1.set_pressed(true)
		3: btn_game3.set_pressed(true)
		5: btn_game5.set_pressed(true)

func set_buttons_enabled(is_enabled: bool):
	btn_retry.disabled = not is_enabled
	btn_exit.disabled = not is_enabled

func _on_visibility_changed():
	if visible:
		_disable_players()
	else:
		_enable_players()

func _disable_players():
	for player in get_tree().get_nodes_in_group("players"):
		if player.has_method("set_movement_enabled"):
			player.set_movement_enabled(false)

func _enable_players():
	for player in get_tree().get_nodes_in_group("players"):
		if player.has_method("set_movement_enabled"):
			player.set_movement_enabled(true)
