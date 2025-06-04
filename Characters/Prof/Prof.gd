extends CharacterBody2D

signal stocks_depleted

## 1 for Player 1, 2 for Player 2
@export var id: int

# Global variables
var frame = 0

# Attributes
@export var percentage = 0
@export var stocks = 5
@export var weight = 100
var freezeFrames = 0

# Buffers
var l_cancel = 0
var cooldown = 0

# Knockback
var hdecay
var vdecay
var knockback
var hitstun
var connected:bool

#Ground variables
var dash_duration: int = 10

# Landing variables
var landing_frames = 0
var lag_frames = 0
var perfect_airdash_modifier = 1

# Air variables
var jump_squat = 3
var fastfall = false
var airJump = 0
@export var airJumpMax = 1
@export var dashMax = 1
var WALL_JUMP_HORIZONTAL_SPEED = 10
var dash_jump_window = 0
const DASH_JUMP_BUFFER_FRAMES  = 18  # about 0.3s at 60fps

# Hitboxes
@export var pendulum_sword: PackedScene
var sword_instance: Node2D = null
var selfState

# Temporary variables
var hit_pause = 0
var hit_pause_dur = 0
var temp_pos = Vector2(0,0)
var temp_vel = Vector2(0,0)

# Ledges
var last_ledge = false
var regrab = 30
var catch = false

# Prof's main attributes
const RUNSPEED = 340
const DASHSPEED = 390
const WALKSPEED = 200
const GRAVITY = 1800
const JUMPFORCE = 500
const MAX_JUMPFORCE = 800
const DOUBLEJUMPFORCE = 1000
const MAXAIRSPEED = 300
const AIR_ACCEL = 25
const FALLSPEED = 60
const FALLINGSPEED = 900
const MAXFALLSPEED = 900
const TRACTION = 40
const ROLL_DISTANCE = 350
const air_dodge_speed = 500
const UP_B_LAUNCHSPEED = 700
@export var AIRDASH_SPEED: float = 1000.0
@export var airdash_duration: int = 10  # Duration in frames
var dash_momentum: Vector2 = Vector2.ZERO
var dash_timer: int = 0
var used_dash = false
var gain_dash_on_land = true
var can_jump_during_dash = false
var ground_dash_friction = 50
#var platform_drop_timer = 0.0
#var dropping_through_platforms = false

var dropping_through_platforms : bool = false
var platform_drop_timer : float = 0.2  # Timer for how long to disable collisions
var platforms_layer : TileMapLayer  # Reference to your platform layer

var color = Color(0, 0, 0)

# Onready variables
#@onready var state_machine = $StateMachine as StateMachine
#@onready var frames_label = $Frames  # Label node for frames
@onready var state_label = $State   # Label node for state
var facing = 1  # 1 for right, -1 for left
@onready var GroundL = get_node('Raycasts/GroundL')
@onready var GroundR = get_node('Raycasts/GroundR')
@onready var anim = $Sprite
@onready var tilemap := get_parent().get_node('map')
#@onready var sword = $Sword
@onready var sprite := $Sprite
@onready var coinParticles = $coinParticles
@onready var landingSound = $Landing
@onready var dashSound = $Dash

var respawned: bool = false
var ignore_knockback_frames := 0
var is_invulnerable: bool = false
var invuln_time_remaining: float = 0.0
const INVULN_TIME := 0.5

func take_damage(particle_amount: int = 5):
	if is_invulnerable:
		return
	#print("Player ", id, " took damage. Stocks left: ", stocks)
	stocks -= 1
	get_parent().update_health(id, stocks)
	
	# Spawn coins at player position
	spawn_coins(particle_amount)
	
	if stocks <= 0:
		emit_signal("stocks_depleted")

func spawn_coins(amount: int):
	coinParticles.amount = amount
	
	var material  = coinParticles.process_material as ParticleProcessMaterial
	if material:
		var grav_x = 98 * direction()  # Facing right or left
		var grav_y = -98                # Gravity downwards
		material.gravity = Vector3(grav_x, grav_y, 0)  # Note Vector3 here
		
	coinParticles.global_position = global_position
	coinParticles.restart()

func stop_movement():
	velocity = Vector2.ZERO
	move_and_slide()
	
func reset_for_new_round():
	respawned = true
	ignore_knockback_frames = 3  # e.g. ignore knockback for 3 frames after respawn

func setup_sword_hitbox():
	var hitbox_instance = pendulum_sword.instantiate()
	hitbox_instance.owning_player = self
	self.add_child(hitbox_instance)
	#hitbox_instance.setup()
	sword_instance = hitbox_instance

func update_frames(delta: float):
	frame += floor(delta*60)
	l_cancel -= floor(delta * 60)
	clampi(l_cancel, 0, l_cancel)
	cooldown -= floor(delta*60)
	cooldown = clampi(cooldown, 0, cooldown)
	if freezeFrames > 0:
		freezeFrames -= floor(delta*60)
	freezeFrames = clampi(freezeFrames, 0, freezeFrames)

func flash_hurt() -> void:
	sprite.modulate = Color(1, 0.5, 0.5)  # Tint red
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1)  # Reset

func _hit_pause(delta):
	if hit_pause < hit_pause_dur:
		self.position = temp_pos
		hit_pause += floor((1 * delta) * 60)
	else:
		if temp_vel != Vector2(0,0):
			self.velocity.x = temp_vel.x
			self.velocity.y = temp_vel.y
			temp_vel = Vector2(0,0)
		hit_pause_dur = 0
		hit_pause = 0

func turn(turnDirection: bool):
	if turnDirection:
		facing = -1
	else:
		facing = 1
	$Sprite.set_flip_h(turnDirection)
	
func direction() -> int:
	return facing
	# Returns 1 if facing right, -1 if facing left
	#return -1 if $Sprite.flip_h else 1

func _frame() -> void:
	frame = 0
	
func get_wall_direction() -> int:
	if is_on_wall():
		return sign(get_slide_collision(0).normal.x)
	return 0

func play_animation(animation_name):
	anim.play(animation_name)
	
	#match animation_name:
		#"Idle":
			#sprite.scale = Vector2(1.5, 1.5)
		#"Death":
			#sprite.scale = Vector2(0.15, 0.15)
		#_:
			#sprite.scale = Vector2(1, 1) # default

func reset_Jumps():
	airJump = airJumpMax
	
func reset_ledge():
	last_ledge = false
	
func is_on_platform() -> bool:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		#print("Collider: ", collider, ", groups: ", collider.get_groups() if collider else "None")
		if collider and collider.name == "Platforms_0":
			#print("Colliding with platform")
			return true
	return false

func _ready() -> void:
	platforms_layer = get_parent().get_node("map/Platforms_0")
	setup_sword_hitbox()

	# Ensure the sprite_frames are set from the scene's resource
	# This assumes $Sprite.sprite_frames is already set to SpriteFrames_lkorh in the .tscn file
	# If not, you would need to load it: sprite.sprite_frames = preload("res://Characters/Prof/Prof.tscn").get_node("Prof/Sprite").sprite_frames

	if id == 1:
		sprite.scale = Vector2(0.15, 0.15)
		anim.play("IDLE_RED")
	elif id == 2:
		sprite.scale = Vector2(0.15, 0.15)
		anim.play("IDLE_BLUE")

var last_pos: Vector2

func _physics_process(delta: float) -> void:
	if ignore_knockback_frames > 0:
		#print("counting down knockback frames")
		ignore_knockback_frames -= 1
	if ignore_knockback_frames == 0:
		respawned = false
		
	if invuln_time_remaining > 0.0:
		invuln_time_remaining = max(invuln_time_remaining - delta, 0.0)
	if invuln_time_remaining == 0.0 and is_invulnerable:
		#print("no more I-frames for player: " + str(id))
		is_invulnerable = false
		
	if global_position.distance_to(last_pos) > 100:
		pass
		#print("Player", id, "jumped position!", last_pos, "->", global_position)
	last_pos = global_position

	#Debug
	$Frames.text = str(frame)
	$Health.text = str(percentage)
	selfState = state_label.text
	
	if dropping_through_platforms:
		platform_drop_timer -= delta
		if platform_drop_timer <= 0.0:
			dropping_through_platforms = false
			#set_collision_mask_value(3, true)
			set_collision_mask_value(2, true)
			GroundL.enabled = true
			GroundR.enabled = true

 #Tilt attacks
func trigger_sword_attack():
	if sword_instance and sword_instance.has_method("start_attack"):
		sword_instance.start_attack()

func release_sword_attack():
	if sword_instance and sword_instance.has_method("release_attack"):
		sword_instance.release_attack()
		sword_instance._reset_attack()
