extends CharacterBody2D

## 1 for Player 1, 2 for Player 2
@export var id: int

# Global variables
var frame = 0

# Attributes
@export var percentage = 0
@export var stocks = 3
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
@export var airJumpMax = 100

# Hitboxes
@export var hitbox: PackedScene
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

# Fox's main attributes
const RUNSPEED = 340*2
const DASHSPEED = 390*2
const WALKSPEED = 200*2
const GRAVITY = 1800*2
const JUMPFORCE = 500*2
const MAX_JUMPFORCE = 800*2
const DOUBLEJUMPFORCE = 1000*2
const MAXAIRSPEED = 300*2
const AIR_ACCEL = 25*2
const FALLSPEED = 60*2
const FALLINGSPEED = 900*2
const MAXFALLSPEED = 900*2
const TRACTION = 40*2
const ROLL_DISTANCE = 350*2
const air_dodge_speed = 500*2
const UP_B_LAUNCHSPEED = 700*2
#@export var AIRDASH_SPEED: float = 1000.0
#@export var airdash_duration: int = 10  # Duration in frames
#var dash_momentum: Vector2 = Vector2.ZERO
#var dash_timer: int = 0

# Onready variables
#@onready var state_machine = $StateMachine as StateMachine
#@onready var frames_label = $Frames  # Label node for frames
@onready var state_label = $State   # Label node for state
@onready var GroundL = get_node('Raycasts/GroundL')
@onready var GroundR = get_node('Raycasts/GroundR')
@onready var Ledge_Grab_F = get_node('Raycasts/Ledge_Grab_F')
@onready var Ledge_Grab_B = get_node('Raycasts/Ledge_Grab_B')
@onready var anim = $Sprite/AnimationPlayer
#@onready var sword = $Sword

func create_hitbox(width, height, damage, angle, base_kb ,kb_scaling, duration, type, points, angle_flipper, hitlag=1):
	if hitbox == null:
		push_error("Hitbox PackedScene is not assigned!")
		return null
	
	var hitbox_instance = hitbox.instantiate()
	self.add_child(hitbox_instance)
	
	if direction() == 1:
		hitbox_instance.set_parameters(width, height, damage, angle, base_kb ,kb_scaling, duration, type, points, angle_flipper, hitlag)
	else:
		var flip_x_points = Vector2(-points.x, points.y)
		hitbox_instance.set_parameters(width, height, damage, -angle + 180, base_kb ,kb_scaling, duration, type, flip_x_points, angle_flipper, hitlag)
	return hitbox_instance

func update_frames(delta: float):
	frame += floor(delta*60)
	l_cancel -= floor(delta * 60)
	clampi(l_cancel, 0, l_cancel)
	cooldown -= floor(delta*60)
	cooldown = clampi(cooldown, 0, cooldown)
	if freezeFrames > 0:
		freezeFrames -= floor(delta*60)
	freezeFrames = clampi(freezeFrames, 0, freezeFrames)
	

func turn(direction: bool):
	var dir = 0
	if direction:
		dir = -1
	else:
		dir = 1
	$Sprite.set_flip_h(direction)
	Ledge_Grab_F.target_position = Vector2(dir*abs(Ledge_Grab_F.target_position.x), Ledge_Grab_F.target_position.y)
	Ledge_Grab_F.position.x = dir * abs(Ledge_Grab_F.position.x)
	Ledge_Grab_B.position.x = dir * abs(Ledge_Grab_B.position.x)
	Ledge_Grab_B.target_position = Vector2(-dir*abs(Ledge_Grab_B.target_position.x), Ledge_Grab_B.target_position.y)
	
func direction():
	if Ledge_Grab_F.target_position.x > 0:
		return 1
	else:
		return -1
	# Returns 1 if facing right, -1 if facing left
	#return -1 if $Sprite.flip_h else 1

func _frame() -> void:
	frame = 0
	
func play_animation(animation_name):
	anim.play(animation_name)
	
func reset_Jumps():
	airJump = airJumpMax
	
func reset_ledge():
	last_ledge = false

func _ready() -> void:
	add_to_group("players")
	pass
	#velocity = Vector2.ZERO
	#print(sword)
	
#func _enter_tree():
	#set_multiplayer_authority(name.to_int())
	
#func take_damage(amount):
	#percentage += amount
	#print("Player took", amount, "damage")
	#
#func apply_knockback(knockback):
	#print("Applying knockback:", knockback)

func _physics_process(delta: float) -> void:	#print("Player", player_id, " physics process running")
	$Frames.text = str(frame)
	#$Health.text = str(percentage)
	selfState = state_label.text

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
			

 #Tilt attacks
func DOWN_TILT():
	if frame == 5:
		create_hitbox(40,20,8,90,70,50,3,'normal',Vector2(64,32),0,1)
	if frame >= 10:
		return true

func UP_TILT():
	if frame == 5:
		create_hitbox(48,68,8,110,20,110,3,'normal',Vector2(-22,-15),0,1)
	if frame >= 12:
		return true

func FORWARD_TILT():
	if frame == 5:
		create_hitbox(52,20,6,120,40,80,3,'normal',Vector2(22,8),0,1)
	if frame >= 8:
		return true

func NAIR():
	if frame == 1:
		create_hitbox(56,56,12,361,0,100,3,'normal',Vector2(0,0),0,.4)
	if frame > 1:
		if connected:
			if frame == 36:
				connected = false
				return true
		else:
			if frame == 5:
				create_hitbox(46,56,9,361,0,100,10,'normal',Vector2(0,0),0,.1)
			if frame == 36:
				return true

func UAIR():
	if frame == 2:
		create_hitbox(32,36,5,90,130,0,2,'normal',Vector2(0,-45),0,1)
	if frame == 6:
		create_hitbox(56,46,10,90,20,108,3,'normal',Vector2(0,-48),0,2)
	if frame >= 15:
		return true

func BAIR():
	if frame == 2:
		create_hitbox(52,55,15,45,1,100,5,'normal',Vector2(-47,7),6,1)
	if frame > 1:
		if connected:
			if frame == 18:
				connected = false
				return true
		else:
			if frame == 7:
				create_hitbox(52,55,5,45,3,140,10,'normal',Vector2(-47,7),6,1)
			if frame == 18:
				return true

func FAIR():
	if frame == 2:
		create_hitbox(35,47,3,76,10,150,3,'normal',Vector2(60,-7),0,1)
	if frame == 11:
		create_hitbox(35,47,3,76,10,150,3,'normal',Vector2(60,-7),0,1)
	if frame >= 18:
		return true

func DAIR():
	if frame == 2:
		create_hitbox(36,58,2,290,140,0,2,'normal',Vector2(28,17),0,1)
	if frame == 3:
		create_hitbox(36,58,2,290,140,0,2,'normal',Vector2(28,17),0,1)
	if frame == 5:
		create_hitbox(36,58,2,290,140,0,2,'normal',Vector2(28,17),0,1)
	if frame == 7:
		create_hitbox(36,58,2,290,140,0,2,'normal',Vector2(28,17),0,1)
	if frame == 9:
		create_hitbox(36,58,2,290,140,0,2,'normal',Vector2(28,17),0,1)
	if frame == 11:
		create_hitbox(36,58,2,290,140,0,2,'normal',Vector2(28,17),0,1)
	if frame == 14:
		create_hitbox(36,58,4,45,12,120,2,'normal',Vector2(28,17),0,1)
	if frame >= 17:
		return true
#
### Attacks
##func SWING():
	##if frame == 5:
		##create_hitbox(40,20,8,90,3,120,3,'normal',Vector2(64,32),0,1)
	##if frame >= 10:
		##return true
##
##func STAB():
	##if frame == 5:
		##create_hitbox(48, 68, 8, 76, 20,110,3, 'normal', Vector2(-22,-15), 0, 1)
	##if frame >= 10:
		##return true
