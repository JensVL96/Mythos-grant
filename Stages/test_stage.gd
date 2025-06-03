extends Node2D

# How many rounds to play this series
var target_games := 1
var match_over := false

# Track wins: index 1 and 2
var wins := {1: 0, 2: 0}

var start_position: Vector2
var max_stocks = 5

@onready var invuln_timer = $InvulnTimer
var is_invulnerable: bool = false

func start_invulnerability(duration := 1.0):
	is_invulnerable = true
	invuln_timer.wait_time = duration
	invuln_timer.start()
	
func _on_InvulnTimer_timeout():
	is_invulnerable = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

@onready var hb1    = $CanvasLayer/UI/HealthbarP1
@onready var hb2    = $CanvasLayer/UI/HealthbarP2
@onready var victory_ui = $CanvasLayer/UI/VictoryScreen
#@onready var spin_box  = victory_ui.get_node("VBoxContainer/HBoxContainer/SpinBox")
@onready var btn_game1 = victory_ui.get_node("VBoxContainer/GamesContainer/VBoxContainer/HBoxContainer/1‐game")
@onready var btn_game3 = victory_ui.get_node("VBoxContainer/GamesContainer/VBoxContainer/HBoxContainer/3‐game")
@onready var btn_game5 = victory_ui.get_node("VBoxContainer/GamesContainer/VBoxContainer/HBoxContainer/5‐game")
@onready var red_score = victory_ui.get_node("VBoxContainer/Scoreboard/redWrap/RedSide/redScore")
@onready var blue_score= victory_ui.get_node("VBoxContainer/Scoreboard/blueWrap/BlueSide/blueScore")
@onready var win_label = victory_ui.get_node("VBoxContainer/winningPlayer")  # your `winningPlayer` node
@onready var btn_retry = victory_ui.get_node("VBoxContainer/HBoxContainer2/ButtonRetry")
@onready var btn_exit  = victory_ui.get_node("VBoxContainer/HBoxContainer2/ButtonExit")
@onready var spawn_p1 = $SpawnPoints/SpawnP1
@onready var spawn_p2 = $SpawnPoints/SpawnP2

func update_health(player_id: int, lives: int) -> void:
	lives = clamp(lives, 0, 5)
	if str(lives) == '0':
		return

	if player_id == 1:
		hb1.play(str(lives))
	else:
		hb2.play(str(lives))


func _ready():
	match_over = false
	invuln_timer.timeout.connect(_on_InvulnTimer_timeout)
	btn_retry.pressed.connect(_on_retry_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	
	#btn_game1.toggled.connect(func(toggled): if toggled: _update_game_buttons(1))
	#btn_game3.toggled.connect(func(toggled): if toggled: _update_game_buttons(3))
	#btn_game5.toggled.connect(func(toggled): if toggled: _update_game_buttons(5))
	btn_game1.toggled.connect(_on_game_toggled.bind(btn_game1))
	btn_game3.toggled.connect(_on_game_toggled.bind(btn_game3))
	btn_game5.toggled.connect(_on_game_toggled.bind(btn_game5))
	#btn_game1.toggled.connect(_on_game_toggled)
	#btn_game3.toggled.connect(_on_game_toggled)
	#btn_game5.toggled.connect(_on_game_toggled)

	
	start_position = global_position
	
	for p in get_tree().get_nodes_in_group("players"):
		p.stocks_depleted.connect(_on_player_out.bind(p.id))
		if p.id == 1:
			p.color = "blue"
			p.play_animation("Idle_blue")
		else:
			p.color = "red"
			p.play_animation("Idle_red")
		p.stocks = max_stocks
		
		match p.id:
			1:
				p.global_position = spawn_p1.global_position
			2:
				p.global_position = spawn_p2.global_position
			3:
				p.global_position = spawn_p2.global_position

	# Update target_games from spin box before starting
	#target_games = spin_box.value if spin_box else 1
	btn_game1.set_pressed(true)
	#btn_game1.pressed = true
	target_games = 1
	# Clear wins at start of series
	wins = {1: 0, 2: 0}
	# Update scoreboard UI
	red_score.text = "0"
	blue_score.text = "0"
	# Hide victory UI
	victory_ui.visible = true
	
	start_round()

func start_round():
	# Read how many rounds to play
	#target_games = spin_box.value if spin_box else 1
	#target_games = target_games
	# Hide victory UI
	#victory_ui.visible = true
	# Reset health/stocks on both players
	for p in get_tree().get_nodes_in_group("players"):
		p.stocks = 5
		p.percentage = 0
		p.emit_signal("reset_health")  # optionally if you have such a signal
		update_health(p.id, p.stocks)
		
		if p.color == "blue":
			p.play_animation("Idle_blue")
		elif p.color == "red":
			p.play_animation("Idle_red")
		
		var charState = p.get_node("StateMachine")
		charState.state = charState.states.STAND

		Globals.round_started = true

		# Stop any momentum (especially if CharacterBody2D)
		if "velocity" in p:
			p.velocity = Vector2.ZERO
			p.knockback = 0
			p.hitstun   = 0
			p.hdecay = 0
			p.vdecay = 0
			p.is_invulnerable = false
			p.invuln_time_remaining = 0
		if p.has_method("stop_movement"):
			p.stop_movement()  # Optional if you implemented this
		
		p.reset_for_new_round()

		# Set knockback immunity (optional)
		#if "is_invulnerable" in p:
			#start_invulnerability(1.0)
		
		# Reset position
		match p.id:
			1:
				p.global_position = spawn_p1.global_position
			2:
				p.global_position = spawn_p2.global_position
			3:
				p.global_position = spawn_p2.global_position
		p.move_and_slide()
	# (Re)start your round logic here—e.g. reposition players, unpause physics…

func _on_player_out(player_id):
	Globals.round_started = false
	print("Player out: ", player_id)
	
	if match_over:
		return
	wins[player_id] = wins.get(player_id, 0) + 1
	
	# Update scoreboard labels
	red_score.text  = str(wins[1])
	blue_score.text = str(wins[2])

	if wins[player_id] >= target_games:
		match_over = true
		# Series over → show Victory UI
		win_label.text = "Blue Player Wins!" if player_id == 1 else "Red Player Wins!"
		
		match target_games:
			1: btn_game1.set_pressed(true)
			3: btn_game3.set_pressed(true)
			5: btn_game5.set_pressed(true)

		victory_ui.visible = true
		# Enable buttons
		btn_retry.disabled = false
		btn_exit.disabled = false
	else:
		# Next round automatically, no UI shown
		await get_tree().create_timer(2.0).timeout
		start_round()

# Button callbacks
func _on_retry_pressed():
	match_over = false
	btn_retry.disabled = true
	btn_exit.disabled = true
	victory_ui.visible = false

	# Reset wins and scoreboard
	wins = {1: 0, 2: 0}
	red_score.text = "0"
	blue_score.text = "0"
	#target_games = spin_box.value if spin_box else 1

	# Reset players
	for p in get_tree().get_nodes_in_group("players"):
		# To avoid duplicate connections, don't reconnect signals here (already connected)
		p.stocks = max_stocks
		p.percentage = 0
		var charState = p.get_node("StateMachine")
		charState.state = charState.states.STAND
		
		match p.id:
			1:
				p.global_position = spawn_p1.global_position
			2, 3:
				p.global_position = spawn_p2.global_position

	start_round()

func _on_game_toggled(pressed: bool, sender):
	if not pressed:
		return
	if sender == btn_game1:
		target_games = 1
	elif sender == btn_game3:
		target_games = 3
	elif sender == btn_game5:
		target_games = 5

func _on_exit_pressed():
	# Either change to your title scene:
	get_tree().change_scene_to_file("res://UI/Titlescreen/titlescreen.tscn")
	# —or, if you have a menu UI you show, just toggle visibility there:
	# $CanvasLayer/UI/TitleScreenUI.visible = true
	# victory_ui.visible = false
