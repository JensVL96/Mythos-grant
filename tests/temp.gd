extends Node

##states.AIRDASH:
			##pass
			##var direction = Vector2.ZERO
			##if Input.is_action_pressed("left_" + str(id)):
				##direction.x -= 1
			##if Input.is_action_pressed("right_" + str(id)):
				##direction.x += 1
			##if Input.is_action_pressed("up_" + str(id)):
				##direction.y -= 1
			##if Input.is_action_pressed("down_" + str(id)):
				##direction.y += 1
##
			##if direction != Vector2.ZERO:
				##direction = direction.normalized()
				##parent.dash_momentum = direction * parent.AIRDASH_SPEED
				##parent.velocity = parent.dash_momentum
			##else:
				##parent.velocity = parent.dash_momentum
##
			### Decrease dash timer
			##parent.dash_timer -= 1
			##if parent.dash_timer <= 0:
				##parent.dash_momentum = Vector2.ZERO  # Reset dash momentum after duration
				##if parent.is_on_floor():
					##return states.STAND
				##else:
					##return states.AIR

#states.AIRDASH:
			#parent.play_animation("AIRDASH")
			#parent.state_label.text = str("AIRDASH")
			#parent.dash_timer = parent.airdash_duration  # Initialize dash timer
			#parent.dash_momentum = parent.velocity


extends Node2D

@onready var sword: Sprite2D = $Sword

@export var gravity: float = 0.4 * 60
@export var damping: float = 0.995
@export var arm_length: float = 100.0
@export var input_sensitivity: float = 0.001

var angle := 0.0
var angular_velocity := 0.0
var angular_acceleration := 0.0
var pivot_point := Vector2.ZERO
var end_position := Vector2.ZERO
var last_mouse_pos := Vector2.ZERO

# damage, kb_angle, base_kb ,kb_scaling, type, angle_flipper, hitlag=1
# 8,90,3,120,'normal',0,1

var is_attacking: bool = false
var is_holding_attack: bool = false
var target_angle: float = 0.0
var passed_target_angle: bool = false
@export var attack_response_speed: float = 5.0  # Lower = smoother approach
@export var attack_damping: float = 0.9  # Higher = less oscillation
@export var max_attack_accel: float = 1.5  # Limit how fast it can accelerate

var parent = get_parent()
@export var damage = 8#50
@export var kb_angle = 90
@export var base_kb = 3#100
@export var kb_scaling = 2#2
@export var duration = 1500
@export var hitlag_modifier = 1
@export var type = 'normal'
@export var angle_flipper = 0

@onready var hitbox = $Hitbox
@export var owning_player: Node2D
@onready var parentState = get_parent().selfState

var knockBackVal
var framez = 0.0
var player_list = []
const angleConversion = PI / 180
@export var percentage = 0
@export var weight = 100
@export var base_knockback = 40
@export var ratio = 1

func setup():
	player_list.append(parent)
	player_list.append(self)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body != owning_player:
		#print("Applying knockback to:", body.name)
		player_list.append(body)
		var charstate
		charstate = body.get_node("StateMachine")
		weight = body.weight
		body.percentage += damage
		knockBackVal = knockback(body.percentage, damage, weight, kb_scaling, base_kb, 1)
		s_angle(body)
		#_angle_flipper(body)
		charstate.state = charstate.states.HITFREEZE
		charstate._hitFreeze(hitlag(damage,hitlag_modifier), _angle_flipper2(Vector2(body.velocity.x,body.velocity.y), body.global_position))
		body.knockback = knockBackVal
		body.hitstun = getHitstun(knockBackVal / 0.3)
		get_parent().connected = true
		body._frame()
		#Globals.hitstun(hitlag(damage,hitlag_modifier), hitlag(damage,hitlag_modifier)/60)
		#get_parent().hit_pause_dur = duration - framez
		#get_parent().temp_pos = get_parent().position
		#get_parent().temp_vel = get_parent().velocity
		#charstate.state = charstate.states.HITSTUN

func getHitstun(knockback):
	#return floor(knockback * 0.533)
	return floor(knockback * 0.4)
	
func hitlag(d, hit):
	damage = d
	hitlag_modifier = hit
	#return floor(d/3)+4))
	return floor((((floor(d) * 0.65) + 6) * hit))

func _ready():
	sword.show()
	last_mouse_pos = global_position

func _physics_process(delta: float) -> void:
	var current_mouse_pos = global_position
	pivot_point = current_mouse_pos
	var pivot_velocity = (current_mouse_pos - last_mouse_pos) / delta if delta > 0 else Vector2.ZERO
	last_mouse_pos = current_mouse_pos
	
	if is_attacking && is_holding_attack:
		# Calculate target direction
		var angle_diff = fmod(target_angle - angle + PI, PI*2) - PI
		
		# Apply controlled acceleration
		var desired_velocity = angle_diff * attack_response_speed
		var vel_diff = desired_velocity - angular_velocity
		angular_velocity += clamp(vel_diff, -max_attack_accel * delta, max_attack_accel * delta)
		
		# Strong damping during attack
		angular_velocity *= attack_damping
		
		# Snap when very close
		if abs(angle_diff) < 0.05:
			angle = target_angle
			angular_velocity = 0
	else:
		# Normal pendulum physics
		angular_acceleration = ((-gravity * delta) / arm_length) * sin(angle)
		angular_velocity += angular_acceleration

	# Pendulum physics
	#angular_acceleration = ((-gravity * delta) / arm_length) * sin(angle)
	#angular_velocity += angular_acceleration
	angular_velocity *= damping
	angle += angular_velocity

	# Update end position and sword placement
	end_position = pivot_point + Vector2(arm_length * sin(angle), arm_length * cos(angle))
	sword.global_position = end_position
	hitbox.global_position = end_position

	# Rotate sword so the blade points away from pivot
	var direction = (end_position - pivot_point).normalized()
	sword.rotation = direction.angle() + PI/2
	hitbox.rotation = sword.rotation

func knockback(p, d, w, ks, kb, r):
	percentage = p
	damage = d
	weight = w
	kb_scaling = ks
	base_kb = kb
	ratio = r
	return((((((((percentage/10) + (percentage*damage/20))*(200/(weight/100))*1.4)+18)*(kb_scaling))+base_kb)*1))*.004

func s_angle(body):
	if angle == 361:
		if knockBackVal > 28:
			if !body.is_on_floor():
				angle = 40
			else:
				angle = 38
		else:
			if !body.is_on_floor():
				angle = 40
			else:
				angle = 25
	elif angle == -181:
		if knockBackVal > 28:
			if !body.is_on_floor():
				angle = (-40)+180
			else:
				angle = (-38)+180
		else:
			if !body.is_on_floor():
				angle = (-40)+180
			else:
				angle = (-25)+180

func getHorizontalDecay(kb_angle):
	var decay = 0.051 * cos(kb_angle * angleConversion)
	decay = round(decay * 100000) / 100000
	decay = decay * 1000
	return decay
	
func getVerticalDecay(kb_angle):
	var decay = 0.051 * sin(kb_angle * angleConversion)
	decay = round(decay * 100000) / 100000
	decay = decay * 1000
	return abs(decay)
	
func getHorizontalVelocity(knockback, kb_angle):
	var initialHorizontal = knockback * 30
	var horizontalAngle = cos(kb_angle * angleConversion)
	var horizontalVelocity = initialHorizontal * horizontalAngle
	horizontalVelocity = round(horizontalVelocity * 100000) / 100000
	return horizontalVelocity
	
func getVerticalVelocity(knockback, kb_angle):
	var initialVelocity = knockback * 30
	var verticalAngle = sin(kb_angle * angleConversion)
	var verticalVelocity = initialVelocity * verticalAngle
	verticalVelocity = round(verticalVelocity * 100000) / 100000
	return verticalVelocity	

func _angle_flipper(body):
	var xangle
	if get_parent().direction() == -1:
		xangle = (-(((body.global_position.angle_to_point(body.get_parent().global_position))*180)/PI))
	else:
		xangle = (((body.global_position.angle_to_point(body.get_parent().global_position))*180)/PI)
	match angle_flipper:
		0: # Sends at the exact angle every time
			body.velocity.x = (getHorizontalVelocity(knockBackVal, -kb_angle))
			body.velocity.y = (getVerticalVelocity(knockBackVal, -kb_angle))
			body.hdecay = (getHorizontalDecay(-kb_angle))
			body.vdecay = (getVerticalDecay(kb_angle))
		1: # Sends away from center of enemy player
			if get_parent().direction() == -1:
				xangle = -(((self.global_position.angle_to_point(body.get_parent().global_position))*180)/PI)
			else:
				xangle = (((self.global_position.angle_to_point(body.get_parent().global_position))*180)/PI)
			body.velocity.x = (getHorizontalVelocity(knockBackVal, xangle+180))
			body.velocity.y = (getVerticalVelocity(knockBackVal, -xangle))
			body.hdecay = (getHorizontalDecay(kb_angle + 180))
			body.vdecay = (getVerticalDecay(xangle))
		2: # Sends towards center of enemy player
			if get_parent().direction() == -1:
				xangle = -(((body.get_parent().global_position.angle_to_point(self.global_position))*180)/PI)
			else:
				xangle = (((body.get_parent().global_position.angle_to_point(self.global_position))*180)/PI)
			body.velocity.x = (getHorizontalVelocity(knockBackVal, -xangle+180))
			body.velocity.y = (getVerticalVelocity(knockBackVal, -xangle))
			body.hdecay = (getHorizontalDecay(xangle + 180))
			body.vdecay = (getVerticalDecay(xangle))
		3: # horizontal knockback sends away from the center of the hitbox
			if get_parent().direction() == -1:
				xangle = (-(((body.global_position.angle_to_point(self.global_position))*180)/PI))+180
			else:
				xangle = (((body.global_position.angle_to_point(self.global_position))*180)/PI)
			body.velocity.x = (getHorizontalVelocity(knockBackVal, xangle))
			body.velocity.y = (getVerticalVelocity(knockBackVal, -kb_angle))
			body.hdecay = (getHorizontalDecay(xangle))
			body.vdecay = (getVerticalDecay(kb_angle))
		4: # horizontal knockback sends towards the center of the hitbox
			if get_parent().direction() == -1:
				xangle = -(((body.global_position.angle_to_point(self.global_position))*180)/PI)+180
			else:
				xangle = (((body.global_position.angle_to_point(self.global_position))*180)/PI)
			body.velocity.x = (getHorizontalVelocity(knockBackVal, -xangle*180))
			body.velocity.y = (getVerticalVelocity(knockBackVal, -kb_angle))
			body.hdecay = (getHorizontalDecay(kb_angle))
			body.vdecay = (getVerticalDecay(kb_angle))
		5: # horizontal knockback is reversed
			body.velocity.x = (getHorizontalVelocity(knockBackVal, kb_angle+180))
			body.velocity.y = (getVerticalVelocity(knockBackVal, -kb_angle))
			body.hdecay = (getHorizontalDecay(kb_angle+180))
			body.vdecay = (getVerticalDecay(kb_angle))
		6: # horizontal knockback sends away from the enemy player
			body.velocity.x = (getHorizontalVelocity(knockBackVal, xangle))
			body.velocity.y = (getVerticalVelocity(knockBackVal, -kb_angle))
			body.hdecay = (getHorizontalDecay(xangle))
			body.vdecay = (getVerticalDecay(kb_angle))
		7: # horizontal knockback sends towards the center of the hitbox
			body.velocity.x = (getHorizontalVelocity(knockBackVal, -xangle+180))
			body.velocity.y = (getVerticalVelocity(knockBackVal, -kb_angle))
			body.hdecay = (getHorizontalDecay(kb_angle))
			body.vdecay = (getVerticalDecay(kb_angle))

func _angle_flipper2(body_vel:Vector2, body_position:Vector2, hdecay=0, vdecay=0):
	var xangle
	if get_parent().direction() == -1:
		xangle = (-(((body_position.angle_to_point(get_parent().global_position))*180)/PI))
	else:
		xangle = (((body_position.angle_to_point(get_parent().global_position))*180)/PI)
	match angle_flipper:
		0:
			body_vel.x = (getHorizontalVelocity(knockBackVal, -angle))
			body_vel.y = (getVerticalVelocity(knockBackVal, -angle))
			hdecay = (getHorizontalDecay(angle + 180))
			vdecay = (getVerticalDecay(angle + 180))
			return ([body_vel.x, body_vel.y, hdecay, vdecay])
		1: # Sends away from center of enemy player
			if get_parent().direction() == -1:
				xangle = -(((self.global_position.angle_to_point(body_position)*180))/PI)
			else:
				xangle = (((self.global_position.angle_to_point(body_position))*180)/PI)
			body_vel.x = (getHorizontalVelocity(knockBackVal, xangle+180))
			body_vel.y = (getVerticalVelocity(knockBackVal, -xangle))
			hdecay = (getHorizontalDecay(angle + 180))
			vdecay = (getVerticalDecay(xangle))
		2: # Sends towards center of enemy player
			if get_parent().direction() == -1:
				xangle = -(((body_position.angle_to_point(self.global_position))*180)/PI)
			else:
				xangle = (((body_position.angle_to_point(self.global_position))*180)/PI)
			body_vel.x = (getHorizontalVelocity(knockBackVal, -xangle+180))
			body_vel.y = (getVerticalVelocity(knockBackVal, -xangle))
			hdecay = (getHorizontalDecay(xangle + 180))
			vdecay = (getVerticalDecay(xangle))
		3: # horizontal knockback sends away from the center of the hitbox
			if get_parent().direction() == -1:
				xangle = (-(((body_position.angle_to_point(self.global_position))*180)/PI))+180
			else:
				xangle = (((body_position.angle_to_point(self.global_position))*180)/PI)
			body_vel.x = (getHorizontalVelocity(knockBackVal, xangle))
			body_vel.y = (getVerticalVelocity(knockBackVal, -angle))
			hdecay = (getHorizontalDecay(xangle))
			vdecay = (getVerticalDecay(angle))
		4: # horizontal knockback sends towards the center of the hitbox
			if get_parent().direction() == -1:
				xangle = -(((body_position.angle_to_point(self.global_position))*180)/PI)+180
			else:
				xangle = (((body_position.angle_to_point(self.global_position))*180)/PI)
			body_vel.x = (getHorizontalVelocity(knockBackVal, -xangle*180))
			body_vel.y = (getVerticalVelocity(knockBackVal, -angle))
			hdecay = (getHorizontalDecay(angle))
			vdecay = (getVerticalDecay(angle))
		5: # horizontal knockback is reversed
			body_vel.x = (getHorizontalVelocity(knockBackVal, angle+180))
			body_vel.y = (getVerticalVelocity(knockBackVal, -angle))
			hdecay = (getHorizontalDecay(angle+180))
			vdecay = (getVerticalDecay(angle))
		6: # horizontal knockback sends away from the enemy player
			body_vel.x = (getHorizontalVelocity(knockBackVal, xangle))
			body_vel.y = (getVerticalVelocity(knockBackVal, -angle))
			hdecay = (getHorizontalDecay(xangle))
			vdecay = (getVerticalDecay(angle))
		7: # horizontal knockback sends towards the center of the hitbox
			body_vel.x = (getHorizontalVelocity(knockBackVal, -xangle+180))
			body_vel.y = (getVerticalVelocity(knockBackVal, -angle))
			hdecay = (getHorizontalDecay(angle))
			vdecay = (getVerticalDecay(angle))

func calculate_target_angle(target_pos: Vector2) -> float:
	var direction = (target_pos - pivot_point).normalized()
	var raw_angle = atan2(direction.x, direction.y)
	
	# Normalize angles to -PI to PI range
	var current_normalized = fmod(angle + PI, PI*2) - PI
	var target_normalized = fmod(raw_angle + PI, PI*2) - PI
	
	# Find shortest angular difference
	var angle_diff = fmod(target_normalized - current_normalized + PI, PI*2) - PI
	
	# Return angle that takes shortest path
	return angle + angle_diff

func start_attack():
	var opponent = find_nearest_opponent()
	if opponent:
		target_angle = calculate_target_angle(opponent.global_position)
		is_attacking = true
		is_holding_attack = true

func release_attack():
	is_holding_attack = false

func _reset_attack():
	is_attacking = false
	is_holding_attack = false
	passed_target_angle = false

func find_nearest_opponent() -> Node2D:
	var opponents = get_tree().get_nodes_in_group("players")
	var nearest = null
	var min_dist = INF
	
	for opp in opponents:
		if opp != owning_player:
			var dist = global_position.distance_to(opp.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = opp
	return nearest
