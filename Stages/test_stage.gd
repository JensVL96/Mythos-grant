# test_stage.gd
extends Node2D

# How many rounds to play this series
var target_games := 1
var match_over := false
var round_ended := false

# Track wins: index 1 and 2
var wins := {1: 0, 2: 0}

var current_player_ids = {
	"red": 1,
	"blue": 2,
}

var start_position: Vector2
var max_stocks = 5
var current_coin: Node = null

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

@onready var spawn_p1 = $SpawnPoints/SpawnP1
@onready var spawn_p2 = $SpawnPoints/SpawnP2

var CoinScene := preload("res://UI/Common/Scenes/Coin.tscn")
@onready var coin_spawn_points = [
	$SpawnPoints/MoneySpawn1,
	$SpawnPoints/MoneySpawn2,
	$SpawnPoints/MoneySpawn3,
]

@onready var canvas_layer := $CanvasLayer
@onready var ui_overlay := $CanvasLayer/UIOverlay
var screenOverlay = null

func _ready():
	GlobalMusic.stop()
	match_over = false
	invuln_timer.timeout.connect(_on_InvulnTimer_timeout)

	# Now get the ScreenOverlay node inside overlay_instance
	screenOverlay = ui_overlay.get_node("ScreenOverlay")

	# Connect signals on screenOverlay (VictoryScreen.gd)
	screenOverlay.retry_pressed.connect(_on_retry_pressed)
	screenOverlay.exit_pressed.connect(_on_exit_pressed)
	screenOverlay.game_count_selected.connect(_on_game_toggled)
	screenOverlay.player_input_changed.connect(_on_player_input_changed)
	
	start_position = global_position
	
	for p in get_tree().get_nodes_in_group("players"):
		p.stocks_depleted.connect(_on_player_out.bind(p.player_id))
		if p.player_id == 1 or p.player_id == 3:
			p.color = "blue"
			p.play_animation("Idle_blue")
		else:
			p.color = "red"
			p.play_animation("Idle_red")
		p.stocks = max_stocks
		
		match p.player_id:
			1:
				p.global_position = spawn_p1.global_position
			2:
				p.global_position = spawn_p2.global_position
			3:
				p.global_position = spawn_p2.global_position

	# Update target_games from spin box before starting
	#target_games = spin_box.value if spin_box else 1
	
	#btn_game1.pressed = true
	target_games = 1
	# Clear wins at start of series
	wins = {1: 0, 2: 0}
	
	start_round()

func start_round():
	#print(">>> START ROUND")
	round_ended = false
	# Spawn the first coin for this round
	#randomize()
	#await get_tree().create_timer(10.0).timeout
	spawn_coin()
	# Read how many rounds to play
	#target_games = spin_box.value if spin_box else 1
	#target_games = target_games
	# Hide victory UI
	#overlay_ui.visible = true
	# Reset health/stocks on both players
	for p in get_tree().get_nodes_in_group("players"):
		p.stocks = 5
		p.percentage = 0
		p.emit_signal("reset_health")  # optionally if you have such a signal
		screenOverlay.update_healthbar(p.player_id, p.stocks)
		
		if p.color == "blue":
			#p.player_id = current_player_ids["blue"]
			p.player_id = current_player_ids["blue"]
			print("at start time setting player id for blue to: " + str(current_player_ids["blue"]))
			p.play_animation("Idle_blue")
		elif p.color == "red":
			#p.player_id = current_player_ids["red"]
			p.player_id = current_player_ids["red"]
			print("at start time setting player id for red to: " + str(current_player_ids["red"]))
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
		match p.player_id:
			1:
				p.global_position = spawn_p1.global_position
			2:
				p.global_position = spawn_p2.global_position
			3:
				p.global_position = spawn_p2.global_position
		p.move_and_slide()
	# (Re)start your round logic here—e.g. reposition players, unpause physics…

func _on_player_out(player_id):
	#print(">>> PLAYER OUT:", player_id)
	Globals.round_started = false
	#print("Player out: ", player_id)
	
	if match_over or round_ended:
		return
	wins[player_id] = wins.get(player_id, 0) + 1
	
	round_ended = true

	# Update scoreboard labels
	screenOverlay.red_score.text  = str(wins[1])
	screenOverlay.blue_score.text = str(wins[2])

	if wins[player_id] >= target_games:
		match_over = true
		# Series over → show Victory UI
		screenOverlay.win_label.text = "Blue Player Wins!" if player_id == 1 else "Red Player Wins!"
		
		match target_games:
			1: screenOverlay.btn_game1.set_pressed(true)
			3: screenOverlay.btn_game3.set_pressed(true)
			5: screenOverlay.btn_game5.set_pressed(true)

		screenOverlay.visible = true
		# Enable buttons
		screenOverlay.btn_retry.disabled = false
		screenOverlay.btn_exit.disabled = false
	else:
		# Next round automatically, no UI shown
		await get_tree().create_timer(2.0).timeout
		start_round()

# Button callbacks
func _on_retry_pressed():
	#print(">>> RETRY PRESSED")
	match_over = false
	screenOverlay.btn_retry.disabled = true
	screenOverlay.btn_exit.disabled = true
	if screenOverlay:
		screenOverlay.visible = false

	# Reset wins and scoreboard
	wins = {1: 0, 2: 0}
	screenOverlay.red_score.text = "0"
	screenOverlay.blue_score.text = "0"
	#target_games = spin_box.value if spin_box else 1

	# Reset players
	for p in get_tree().get_nodes_in_group("players"):
		# To avoid duplicate connections, don't reconnect signals here (already connected)
		p.stocks = max_stocks
		p.percentage = 0
		var charState = p.get_node("StateMachine")
		charState.state = charState.states.STAND
		
		match p.player_id:
			1:
				p.global_position = spawn_p1.global_position
			2, 3:
				p.global_position = spawn_p2.global_position

	start_round()

func _on_game_toggled(count: int):
	target_games = count
	print("Target games set to: ", count)

func _on_player_input_changed(player_side: String, desired: String):
	var new_id = 0
	if player_side == "red":
		new_id = 3 if desired == "con" else 1
	elif player_side == "blue":
		new_id = 4 if desired == "con" else 2
	#print("trying to update input")
	if player_side == "red":
		if new_id == 1:
			print("left side  has chosen keyboard with id 1")
		if new_id == 3:
			print("left side  has chosen controller with id 3")
	elif player_side == "blue":
		if new_id == 2:
			print("right side  has chosen keyboard with id 2")
		if new_id == 4:
			print("right side  has chosen controller with id 4")

	current_player_ids[player_side] = new_id

	## Update players in group "players"
	#for p in get_tree().get_nodes_in_group("players"):
		#if player_side == "red" and (p.player_id == 1 or p.player_id == 3):
			#p.player_id = new_id
			#print("Updated Player 1 id to ", new_id)
		#elif player_side == "blue" and (p.player_id == 2 or p.player_id == 4):
			#p.player_id = new_id
			#print("Updated Player 2 id to ", new_id)

func _on_exit_pressed():
	# Either change to your title scene:
	get_tree().change_scene_to_file("res://UI/Titlescreen/titlescreen.tscn")
	# —or, if you have a menu UI you show, just toggle visibility there:
	# $CanvasLayer/UI/TitleScreenUI.visible = true
	# screenOverlay.visible = false

func update_health(id: int, stocks: int) -> void:
	screenOverlay.update_healthbar(id, stocks)

func spawn_coin():
	if current_coin != null and current_coin.is_inside_tree():
		# Coin already exists, do not spawn another
		return

	current_coin = CoinScene.instantiate()
	var spawn_marker = coin_spawn_points[randi() % coin_spawn_points.size()]
	current_coin.global_position = spawn_marker.global_position
	add_child(current_coin)

	current_coin.picked_up.connect(_on_coin_picked_up)

func _on_coin_picked_up(player):
	if player.stocks < max_stocks:
		player.stocks += 1
		screenOverlay.update_health(player.player_id, player.stocks)

	# Remove the coin reference as it was picked up
	current_coin = null

	# Wait a random time before spawning a new coin
	var delay = randf_range(3.0, 6.0)
	await get_tree().create_timer(delay).timeout

	spawn_coin()
