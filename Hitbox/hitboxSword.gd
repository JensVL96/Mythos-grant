extends Node2D

# Constants
const ANGLE_CONVERSION = PI / 180
const MAX_ANGULAR_VELOCITY = 15.0  # Hard cap swing speed

# Nodes
@onready var sword: Sprite2D = $Sword
@onready var hitbox = $Hitbox
@onready var parent_state = get_parent().selfState
#var stage = get_parent().get_parent()  # Player -> Stage
#var camera = stage.get_node("Camera2D")  # Adjust the name if it's different

#sounds
@onready var SwordClash = $swordClash
@onready var coin1 = $coin1
@onready var coin2 = $coin2
@onready var coin3 = $coin3
@onready var coin4 = $coin4
@onready var coin5 = $coin5
@onready var coin6 = $coin6
@onready var coin7 = $coin7
@onready var coinDeath = $coinDeath

# Exports - Physics
@export var gravity: float = 0.4 * 60
@export var damping: float = 0.995
@export var arm_length: float = 100.0
@export var input_sensitivity: float = 0.001

# Exports - Kockback Mechanics
@export var damage = 20
@export var kb_angle = 90
@export var base_kb = 3
@export var kb_scaling = 2
@export var duration = 1500
@export var hitlag_modifier = 1
@export var type = 'normal'
@export var angle_flipper = 3 #0136
@export var owning_player: Node2D
var recently_hit := {}
var hit_buffer_time := 0.3  # seconds before they can be hit again

# Exports - Attack Mechanics
@export var attack_damping: float = 0.9
@export var tracking_response: float = 3.0
@export var max_tracking_speed: float = 1.5
@export var release_deceleration: float = 0.85
@export var max_release_speed: float = 1.0
@export var CLASH_FORCE_MULTIPLIER := 1.8
@export var CLASH_DAMPING : float = 0.65

# Variables
var angle := 0.0
var angular_velocity := 0.0
var angular_acceleration := 0.0
var pivot_point := Vector2.ZERO
var end_position := Vector2.ZERO
var last_player_pos := Vector2.ZERO
var knockBackVal
var framez = 0.0
var player_list = []
var percentage = 10
var weight = 100
var base_knockback = 40
var ratio = 1
# damage, kb_angle, base_kb ,kb_scaling, type, angle_flipper, hitlag=1
# 8,90,3,120,'normal',0,1

# Attack State
var is_attacking: bool = false
var is_holding_attack: bool = false
var can_hold_attack: bool = true
var hold_disable_timer: float = 0.0
var HOLD_DISABLE_DURATION: float = 0.2
var target_angle: float = 0.0
var passed_target_angle: bool = false
var current_target_pos: Vector2
var release_timer: float = 0.0

# Clash State
var _clash_cooldown := 0.0
var _pre_clash_velocity : float = 0.0
var _is_recovering : bool = false

func _ready():
	sword.show()
	last_player_pos = global_position
	player_list.append(get_parent())
	player_list.append(self)

func _physics_process(delta: float) -> void:
	handle_clash_cooldown(delta)

	if _is_recovering:
		handle_recovery(delta)
		return

	update_player_position(delta)
	handle_attack_mechanics(delta)
	apply_pendulum_physics(delta)
	update_sword_position()

func handle_clash_cooldown(delta: float) -> void:
	_clash_cooldown = max(0.0, _clash_cooldown - delta)

func handle_recovery(delta: float) -> void:
	angular_velocity = lerp(angular_velocity, _pre_clash_velocity, delta * 5.0)
	if abs(angular_velocity - _pre_clash_velocity) < 0.1:
		_is_recovering = false

func update_player_position(delta: float) -> void:
	var current_player_pos = global_position
	pivot_point = current_player_pos
	var pivot_velocity = (current_player_pos - last_player_pos) / delta if delta > 0 else Vector2.ZERO
	last_player_pos = current_player_pos
	apply_movement_angular_velocity(pivot_velocity)

func apply_movement_angular_velocity(pivot_velocity: Vector2) -> void:
	var arm_vector = end_position - pivot_point
	if arm_vector.length() > 0.01:
		var perpendicular = Vector2(-arm_vector.y, arm_vector.x).normalized()
		var tangential_speed = pivot_velocity.dot(perpendicular)
		var angular_force = tangential_speed / arm_length
		angular_velocity += angular_force * input_sensitivity

func handle_attack_mechanics(delta: float) -> void:
	if is_attacking && is_holding_attack:
		handle_attack_tracking(delta)
		angular_velocity *= attack_damping
	else:
		if release_timer > 0:
			release_timer -= delta
			angular_velocity *= lerp(release_deceleration, damping, 1.0 - (release_timer/0.3))

func handle_attack_tracking(delta: float) -> void:
	var opponent = find_nearest_opponent()
	if opponent:
		current_target_pos = current_target_pos.lerp(opponent.global_position, tracking_response * delta)
		var desired_angle = calculate_sword_direction(opponent.global_position) # Calculate desired angle (pointing at opponent)
		var angle_diff = fmod(desired_angle - angle + PI, PI*2) - PI # Find shortest angular difference (-PI to PI range)
		var target_velocity = angle_diff * tracking_response
		angular_velocity = lerp(angular_velocity, target_velocity, delta)  # Smooth transition
		angular_velocity = clamp(angular_velocity, -max_tracking_speed, max_tracking_speed)
		
		# When very close to target, snap to prevent oscillation
		if abs(angle_diff) < 0.03:  # ~2.8 degrees
			angle = desired_angle
			angular_velocity = 0

func calculate_sword_direction(target_pos: Vector2) -> float:
	var direction = (target_pos - pivot_point).normalized()
	return atan2(direction.x, direction.y)

#func handle_attack_tracking(delta: float) -> void:
	#var opponent = find_nearest_opponent()
	#if opponent:
		#current_target_pos = current_target_pos.lerp(opponent.global_position, tracking_response * delta)
		#var desired_angle = calculate_sword_direction(opponent.global_position)
		#var angle_diff = fmod(desired_angle - angle + PI, PI*2) - PI
		#angular_velocity += clamp(angle_diff * delta * tracking_response, -max_tracking_speed, max_tracking_speed)

func apply_pendulum_physics(delta: float) -> void:
	if !is_attacking || !is_holding_attack:
		angular_acceleration = ((-gravity * delta) / arm_length) * sin(angle)
		angular_velocity += angular_acceleration
	
	angular_velocity *= damping
	angle += angular_velocity

func update_sword_position() -> void:
	end_position = pivot_point + Vector2(arm_length * sin(angle), arm_length * cos(angle))
	sword.global_position = end_position
	hitbox.global_position = end_position
	
	var direction = (end_position - pivot_point).normalized()
	sword.rotation = direction.angle() + PI/2
	hitbox.rotation = sword.rotation

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == owning_player:
		print("Skipping: hit self")
		return
		
	if body.invuln_time_remaining > 0.0:
		print("Skipping: still invulnerable (", body.invuln_time_remaining, ")")
		return

	if recently_hit.has(body):
		print("Skipping: recently hit")
		return
		
	if body.respawned:
		print("Skipping: body is respawning")
		return
		
	#recently_hit[body] = true
	player_list.append(body)
	
	
	var charstate
	charstate = body.get_node("StateMachine")
	weight = body.weight
	body.percentage += damage
	body.take_damage()
	knockBackVal = knockback(percentage, damage, weight, kb_scaling, base_kb, 1)
	s_angle(body)
	charstate.state = charstate.states.HITFREEZE
	var is_grounded = body.is_on_floor()
	charstate._hitFreeze(hitlag(damage,hitlag_modifier), swing_momentum(Vector2(body.velocity.x,body.velocity.y), body.global_position, 0, 0, is_grounded))
	body.knockback = knockBackVal
	body.hitstun = getHitstun(knockBackVal / 0.3)
	get_parent().connected = true
	body._frame()

	body.flash_hurt()	
	var camera = get_tree().get_current_scene().get_node_or_null("Stage/Camera2D")	
	if camera:
		camera.shake()

	if body.stocks <= 0:
		charstate.state = charstate.states.DYING
		coinDeath.play()
		return
	else:
		var coinList = [coin1, coin2, coin3, coin4, coin5, coin6, coin7]
		var hurtSound = randi() % 7
		coinList[hurtSound].play()
		
	body.invuln_time_remaining = body.INVULN_TIME
	body.is_invulnerable = true
	# Apply invulnerability to the attacker too (if they exist and are not the same)
	if owning_player and owning_player != body:
		owning_player.invuln_time_remaining = owning_player.INVULN_TIME
		owning_player.is_invulnerable = true
	await get_tree().create_timer(hit_buffer_time).timeout
	recently_hit.erase(body)
		
		#Globals.hitstun(hitlag(damage,hitlag_modifier), hitlag(damage,hitlag_modifier)/60)
		#get_parent().hit_pause_dur = duration - framez
		#get_parent().temp_pos = get_parent().position
		#get_parent().temp_vel = get_parent().velocity
		#charstate.state = charstate.states.HITSTUN

''' p: percentage, d: damage, w: weight, ks: kb_scaling, kb: base_kb, r: ratio'''
func knockback(p, d, w, ks, kb, r):
	return (((((((p/10) + (p*d/20))*(200/(w/100))*1.4)+18)*ks)+kb)*1)*.004

func getHitstun(knockbackStun):
	#return floor(knockbackStun * 0.533)
	return floor(knockbackStun * 0.4)

''' d: damage, hit: hitlag modifier'''
func hitlag(d, hit):
	#return floor(d/3)+4))
	return floor((((floor(d) * 0.65) + 6) * hit))

func s_angle(body):
	if angle == 361:
		angle = 40 if !body.is_on_floor() else (38 if knockBackVal > 28 else 25)
	elif angle == -181:
		angle = (-40 if !body.is_on_floor() else (-38 if knockBackVal > 28 else -25)) + 180

#func get_horizontal_decay(kb_decay_angle):
	#return abs(round(0.051 * cos(kb_decay_angle * ANGLE_CONVERSION) * 100000) / 100000 * 1000)
	#
#func get_vertical_decay(kb_decay_angle):
	#return abs(round(0.051 * sin(kb_decay_angle * ANGLE_CONVERSION) * 100000) / 100000 * 1000)
	#
#func get_horizontal_velocity(knockback_vel, kb_vel_angle):
	#return round((knockback_vel * 30 * cos(kb_vel_angle * ANGLE_CONVERSION)) * 100000) / 100000
	#
#func get_vertical_velocity(knockback_vel, kb_vel_angle):
	#return round((knockback_vel * 30 * sin(kb_vel_angle * ANGLE_CONVERSION)) * 100000) / 100000	
#
#func _angle_flipper(body):
	#var xangle
	#if get_parent().direction() == -1:
		#xangle = (-(((body.global_position.angle_to_point(body.get_parent().global_position))*180)/PI))
	#else:
		#xangle = (((body.global_position.angle_to_point(body.get_parent().global_position))*180)/PI)
	#match angle_flipper:
		#0: # Sends at the exact angle every time
			#body.velocity.x = (get_horizontal_velocity(knockBackVal, -kb_angle))
			#body.velocity.y = (get_vertical_velocity(knockBackVal, -kb_angle))
			#body.hdecay = (get_horizontal_decay(-kb_angle))
			#body.vdecay = (get_vertical_decay(kb_angle))
		#1: # Sends away from center of enemy player
			#if get_parent().direction() == -1:
				#xangle = -(((self.global_position.angle_to_point(body.get_parent().global_position))*180)/PI)
			#else:
				#xangle = (((self.global_position.angle_to_point(body.get_parent().global_position))*180)/PI)
			#body.velocity.x = (get_horizontal_velocity(knockBackVal, xangle+180))
			#body.velocity.y = (get_vertical_velocity(knockBackVal, -xangle))
			#body.hdecay = (get_horizontal_decay(kb_angle + 180))
			#body.vdecay = (get_vertical_decay(xangle))
		#2: # Sends towards center of enemy player
			#if get_parent().direction() == -1:
				#xangle = -(((body.get_parent().global_position.angle_to_point(self.global_position))*180)/PI)
			#else:
				#xangle = (((body.get_parent().global_position.angle_to_point(self.global_position))*180)/PI)
			#body.velocity.x = (get_horizontal_velocity(knockBackVal, -xangle+180))
			#body.velocity.y = (get_vertical_velocity(knockBackVal, -xangle))
			#body.hdecay = (get_horizontal_decay(xangle + 180))
			#body.vdecay = (get_vertical_decay(xangle))
		#3: # horizontal knockback sends away from the center of the hitbox
			#if get_parent().direction() == -1:
				#xangle = (-(((body.global_position.angle_to_point(self.global_position))*180)/PI))+180
			#else:
				#xangle = (((body.global_position.angle_to_point(self.global_position))*180)/PI)
			#body.velocity.x = (get_horizontal_velocity(knockBackVal, xangle))
			#body.velocity.y = (get_vertical_velocity(knockBackVal, -kb_angle))
			#body.hdecay = (get_horizontal_decay(xangle))
			#body.vdecay = (get_vertical_decay(kb_angle))
		#4: # horizontal knockback sends towards the center of the hitbox
			#if get_parent().direction() == -1:
				#xangle = -(((body.global_position.angle_to_point(self.global_position))*180)/PI)+180
			#else:
				#xangle = (((body.global_position.angle_to_point(self.global_position))*180)/PI)
			#body.velocity.x = (get_horizontal_velocity(knockBackVal, -xangle*180))
			#body.velocity.y = (get_vertical_velocity(knockBackVal, -kb_angle))
			#body.hdecay = (get_horizontal_decay(kb_angle))
			#body.vdecay = (get_vertical_decay(kb_angle))
		#5: # horizontal knockback is reversed
			#body.velocity.x = (get_horizontal_velocity(knockBackVal, kb_angle+180))
			#body.velocity.y = (get_vertical_velocity(knockBackVal, -kb_angle))
			#body.hdecay = (get_horizontal_decay(kb_angle+180))
			#body.vdecay = (get_vertical_decay(kb_angle))
		#6: # horizontal knockback sends away from the enemy player
			#body.velocity.x = (get_horizontal_velocity(knockBackVal, xangle))
			#body.velocity.y = (get_vertical_velocity(knockBackVal, -kb_angle))
			#body.hdecay = (get_horizontal_decay(xangle))
			#body.vdecay = (get_vertical_decay(kb_angle))
		#7: # horizontal knockback sends towards the center of the hitbox
			#body.velocity.x = (get_horizontal_velocity(knockBackVal, -xangle+180))
			#body.velocity.y = (get_vertical_velocity(knockBackVal, -kb_angle))
			#body.hdecay = (get_horizontal_decay(kb_angle))
			#body.vdecay = (get_vertical_decay(kb_angle))
#
#func _angle_flipper2(body_vel:Vector2, body_position:Vector2, hdecay=0, vdecay=0):
	#var xangle
	#if get_parent().direction() == -1:
		#xangle = (-(((body_position.angle_to_point(get_parent().global_position))*180)/PI))
	#else:
		#xangle = (((body_position.angle_to_point(get_parent().global_position))*180)/PI)
	#match angle_flipper:
		#0:
			#body_vel.x = (get_horizontal_velocity(knockBackVal, -angle))
			#body_vel.y = (get_vertical_velocity(knockBackVal, -angle))
			#hdecay = (get_horizontal_decay(angle + 180))
			#vdecay = (get_vertical_decay(angle + 180))
			#return ([body_vel.x, body_vel.y, hdecay, vdecay])
		#1: # Sends away from center of enemy player
			#if get_parent().direction() == -1:
				#xangle = -(((self.global_position.angle_to_point(body_position)*180))/PI)
			#else:
				#xangle = (((self.global_position.angle_to_point(body_position))*180)/PI)
			#body_vel.x = (get_horizontal_velocity(knockBackVal, xangle+180))
			#body_vel.y = (get_vertical_velocity(knockBackVal, -xangle))
			#hdecay = (get_horizontal_decay(angle + 180))
			#vdecay = (get_vertical_decay(xangle))
		#2: # Sends towards center of enemy player
			#if get_parent().direction() == -1:
				#xangle = -(((body_position.angle_to_point(self.global_position))*180)/PI)
			#else:
				#xangle = (((body_position.angle_to_point(self.global_position))*180)/PI)
			#body_vel.x = (get_horizontal_velocity(knockBackVal, -xangle+180))
			#body_vel.y = (get_vertical_velocity(knockBackVal, -xangle))
			#hdecay = (get_horizontal_decay(xangle + 180))
			#vdecay = (get_vertical_decay(xangle))
		#3: # horizontal knockback sends away from the center of the hitbox
			#if get_parent().direction() == -1:
				#xangle = (-(((body_position.angle_to_point(self.global_position))*180)/PI))+180
			#else:
				#xangle = (((body_position.angle_to_point(self.global_position))*180)/PI)
			#body_vel.x = (get_horizontal_velocity(knockBackVal, xangle))
			#body_vel.y = (get_vertical_velocity(knockBackVal, -angle))
			#hdecay = (get_horizontal_decay(xangle))
			#vdecay = (get_vertical_decay(angle))
		#4: # horizontal knockback sends towards the center of the hitbox
			#if get_parent().direction() == -1:
				#xangle = -(((body_position.angle_to_point(self.global_position))*180)/PI)+180
			#else:
				#xangle = (((body_position.angle_to_point(self.global_position))*180)/PI)
			#body_vel.x = (get_horizontal_velocity(knockBackVal, -xangle*180))
			#body_vel.y = (get_vertical_velocity(knockBackVal, -angle))
			#hdecay = (get_horizontal_decay(angle))
			#vdecay = (get_vertical_decay(angle))
		#5: # horizontal knockback is reversed
			#body_vel.x = (get_horizontal_velocity(knockBackVal, angle+180))
			#body_vel.y = (get_vertical_velocity(knockBackVal, -angle))
			#hdecay = (get_horizontal_decay(angle+180))
			#vdecay = (get_vertical_decay(angle))
		#6: # horizontal knockback sends away from the enemy player
			#body_vel.x = (get_horizontal_velocity(knockBackVal, xangle))
			#body_vel.y = (get_vertical_velocity(knockBackVal, -angle))
			#hdecay = (get_horizontal_decay(xangle))
			#vdecay = (get_vertical_decay(angle))
		#7: # horizontal knockback sends towards the center of the hitbox
			#body_vel.x = (get_horizontal_velocity(knockBackVal, -xangle+180))
			#body_vel.y = (get_vertical_velocity(knockBackVal, -angle))
			#hdecay = (get_horizontal_decay(angle))
			#vdecay = (get_vertical_decay(angle))

func _get_physics_values(kb_val: float, vel_x: float, vel_y: float, decay_h: float, decay_v: float) -> Array:
	return [
		round((kb_val * 30 * cos(vel_x * ANGLE_CONVERSION)) * 100000) / 100000,  # vel_x
		round((kb_val * 30 * sin(vel_y * ANGLE_CONVERSION)) * 100000) / 100000,  # vel_y
		abs(round(0.051 * cos(decay_h * ANGLE_CONVERSION) * 100000) / 100000 * 1000),  # hdecay
		abs(round(0.051 * sin(decay_v * ANGLE_CONVERSION) * 100000) / 100000 * 1000)   # vdecay
	]

func _angle_flipper(body):
	var dir = get_parent().direction()
	var base_angle = (body.global_position.angle_to_point(body.get_parent().global_position)) * 180/PI
	var base_angle_2 = ((self.global_position.angle_to_point(body.get_parent().global_position))*180)/PI
	var base_angle_3 = ((body.get_parent().global_position.angle_to_point(self.global_position))*180)/PI
	var xangle = dir * base_angle
	
	var result: Array
	match angle_flipper:
		0:
			result = _get_physics_values(knockBackVal, -kb_angle, -kb_angle, -kb_angle, kb_angle)
		1:# Sends away from center of enemy player
			xangle = -base_angle_2 if get_parent().direction() == -1 else base_angle_2
			result = _get_physics_values(knockBackVal, xangle+180, -xangle, kb_angle+180, xangle)
		2: # Sends towards center of enemy player
			xangle = -base_angle_3 if get_parent().direction() == -1 else base_angle_3
			result = _get_physics_values(knockBackVal, -xangle+180, -xangle, xangle+180, xangle)
		3: # horizontal knockback sends away from the center of the hitbox
			xangle = -base_angle_3+180 if get_parent().direction() == -1 else base_angle_3
			result = _get_physics_values(knockBackVal, xangle, -kb_angle, xangle, kb_angle)
		4:# horizontal knockback sends towards the center of the hitbox
			xangle = -base_angle_3+180 if get_parent().direction() == -1 else base_angle_3
			result = _get_physics_values(knockBackVal, -xangle*180, -kb_angle, kb_angle, kb_angle)
		5:# horizontal knockback is reversed
			result = _get_physics_values(knockBackVal, kb_angle+180, -kb_angle, kb_angle+180, kb_angle)
		6: # horizontal knockback sends away from the enemy player
			result = _get_physics_values(knockBackVal, xangle, -kb_angle, xangle, kb_angle)
		7:# horizontal knockback sends towards the center of the hitbox
			result = _get_physics_values(knockBackVal, -xangle+180, -kb_angle, kb_angle, kb_angle)
	
	body.velocity.x = result[0]
	body.velocity.y = result[1]
	body.hdecay = result[2]
	body.vdecay = result[3]

func swing_momentum(body_vel: Vector2, body_position: Vector2, hdecay=0, vdecay=0, is_grounded=true):
	var hitbox_center = global_position
	var to_target = (body_position - hitbox_center).normalized()
	# This is the sword’s pointing direction:
	var sword_dir = Vector2(cos(angle+PI/2), sin(angle+PI/2)).normalized()
	# How hard you swung (0.2–1.0)
	var swing_strength = clamp(abs(angular_velocity)/MAX_ANGULAR_VELOCITY, 0.2, 1.0)

	# Mix strongly toward the sword direction:
	var mix_amount = swing_strength  # try 0.7–1.0 for more sword influence
	var knock_dir = (sword_dir * mix_amount + to_target * (1.0 - mix_amount)).normalized()

	# If it’s a clear upward component, guarantee a minimum lift:
	if sword_dir.y < -0.1:
		knock_dir.y = min(knock_dir.y, -0.3)  # ensure at least 30% upward

	# If a downward “spike”:
	if sword_dir.y > 0.1 and not is_grounded:
		knock_dir.y *= 1.5

	# Now compute your actual physics values
	var angle_deg = rad_to_deg(knock_dir.angle())
	var result = _get_physics_values(
		knockBackVal,
		angle_deg, angle_deg, angle_deg, angle_deg
	)

	body_vel.x = result[0]
	body_vel.y = result[1]
	hdecay = result[2]
	vdecay = result[3]
	return [body_vel.x, body_vel.y, hdecay, vdecay]


func _angle_flipper2(body_vel: Vector2, body_position: Vector2, hdecay = 0, vdecay = 0):
	var dir = get_parent().direction()
	var angle_to_parent = (body_position.angle_to_point(get_parent().global_position)) * 180/PI
	var angle_from_self_to_body = (self.global_position.angle_to_point(body_position)) * 180/PI
	var angle_from_body_to_self = (body_position.angle_to_point(self.global_position)) * 180/PI
	
	var xangle = dir * angle_to_parent
	var result: Array
	
	match angle_flipper:
		0:  # Exact angle every time
			result = _get_physics_values(knockBackVal, -angle, -angle, angle + 180, angle + 180)
		1:  # Away from enemy center
			xangle = angle_from_self_to_body if dir == -1 else -angle_from_self_to_body
			result = _get_physics_values(knockBackVal, xangle + 180, -xangle, angle + 180, xangle)
		2:  # Towards enemy center
			xangle = angle_from_body_to_self if dir == -1 else -angle_from_body_to_self
			result = _get_physics_values(knockBackVal, -xangle + 180, -xangle, xangle + 180, xangle)
		3:  # Away from hitbox center
			var hitbox_center = self.global_position
			var body_pos = body_position
			var direction_vector = (body_pos - hitbox_center).normalized()
			var away_angle = rad_to_deg(direction_vector.angle())
			
			result = _get_physics_values(
				knockBackVal,
				away_angle,     # X velocity angle (directly away)
				away_angle,     # Y velocity angle (same as x for consistency)
				away_angle,     # Horizontal decay
				away_angle      # Vertical decay
			)
		4:  # Towards hitbox center
			xangle = angle_from_body_to_self + 180 if dir == -1 else -angle_from_body_to_self
			result = _get_physics_values(knockBackVal, -xangle * 180, -angle, angle, angle)
		5:  # Horizontal reversed
			result = _get_physics_values(knockBackVal, angle + 180, -angle, angle + 180, angle)
		6:  # Away from enemy player
			result = _get_physics_values(knockBackVal, xangle, -angle, xangle, angle)
		7:  # Towards hitbox center (alternate)
			result = _get_physics_values(knockBackVal, -xangle + 180, -angle, angle, angle)
	
	body_vel.x = result[0]
	body_vel.y = result[1]
	hdecay = result[2]
	vdecay = result[3]
	return [body_vel.x, body_vel.y, hdecay, vdecay]

# Attack Functions
func start_attack():
	var opponent = find_nearest_opponent()
	if opponent:
		current_target_pos = opponent.global_position
		target_angle = (current_target_pos - pivot_point).angle() + PI/2
		is_attacking = true
		is_holding_attack = true

func release_attack():
	is_holding_attack = false
	release_timer = 0.3
	angular_velocity = clamp(angular_velocity, -max_release_speed, max_release_speed)

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

# Sword Clash Functions
func _on_sword_clash(area: Area2D) -> void:
	if area == $Hitbox: return
	if _clash_cooldown > 0: return
	
	var other_sword = area.get_parent()
	if !other_sword.has_method("_receive_sword_clash"): return
	
	_pre_clash_velocity = angular_velocity
	_is_recovering = true
	_clash_cooldown = 0.1
	
	# Calculate speed difference between the two swords
	var speed_diff = angular_velocity - other_sword.angular_velocity
	
	# Apply a force proportional to the speed difference
	var force = speed_diff * CLASH_FORCE_MULTIPLIER
	
	# Determine the direction of rotation for counter-rotation effect
	# If this sword is rotating clockwise (negative angular velocity in Godot),
	# the other sword should be knocked counter-clockwise (positive)
	var counter_direction = sign(angular_velocity) * -1
	
	# Apply forces to both swords (reduced by half for each)
	angular_velocity = clamp(angular_velocity - force * 0.8, -MAX_ANGULAR_VELOCITY, MAX_ANGULAR_VELOCITY)
	
	# Pass both the force and the counter direction to the other sword
	other_sword._receive_sword_clash(force * 0.5, counter_direction)
	
	# Apply damping to prevent excessive oscillation
	angular_velocity *= CLASH_DAMPING
	
	# Break aiming hold on both swords for a short buffer
	is_holding_attack = false
	can_hold_attack = false
	hold_disable_timer = HOLD_DISABLE_DURATION

	other_sword.is_holding_attack = false
	other_sword.can_hold_attack = false
	other_sword.hold_disable_timer = HOLD_DISABLE_DURATION
	
	# Play clash sound
	SwordClash.play()

# Called by the other sword during a clash
func _receive_sword_clash(force: float, counter_direction: float = 0) -> void:
	# Apply the force to this sword's angular velocity with counter-rotation
	if counter_direction != 0:
		# If a counter direction is specified, ensure the force pushes in that direction
		var force_magnitude = abs(force)
		angular_velocity = clamp(counter_direction * force_magnitude, -MAX_ANGULAR_VELOCITY, MAX_ANGULAR_VELOCITY)
	else:
		# Fallback to the original behavior if no counter direction is specified
		angular_velocity = clamp(angular_velocity + force, -MAX_ANGULAR_VELOCITY, MAX_ANGULAR_VELOCITY)
	
	# Apply damping to prevent excessive oscillation
	angular_velocity *= CLASH_DAMPING
	
	# Break aim for a short window
	is_holding_attack = false
	can_hold_attack = false
	hold_disable_timer = HOLD_DISABLE_DURATION

# Helper Functions
func calculate_target_angle(target_pos: Vector2) -> float:
	var direction = (target_pos - pivot_point).normalized()
	var raw_angle = atan2(direction.x, direction.y)
	var current_normalized = fmod(angle + PI, PI*2) - PI
	var target_normalized = fmod(raw_angle + PI, PI*2) - PI
	var angle_diff = fmod(target_normalized - current_normalized + PI, PI*2) - PI
	return angle + angle_diff
