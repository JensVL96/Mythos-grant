extends Area2D

@onready var parent = get_parent()
@export var width = 300
@export var height = 400
@export var damage = 50
@export var angle = 90
@export var base_kb = 100
@export var kb_scaling = 2
@export var duration = 1500
@export var hitlag_modifier = 1
@export var type = 'normal'
@export var angle_flipper = 0

@onready var hitbox = get_node("Hitbox_Shape")
@onready var parentState = get_parent().selfState

var knockBackVal
var framez = 0.0
var player_list = []

func set_parameters(w, h, d, a, b_kb, kb_s, dur, t, p, af, hit, parent=get_parent()):
	self.position = Vector2(0, 0)
	player_list.append(parent)
	player_list.append(self)	
	width = w
	height = h
	damage = d
	angle = a
	base_kb = b_kb
	kb_scaling = kb_s
	duration = dur
	type = t
	self.position = p
	hitlag_modifier = hit
	angle_flipper = af
	update_extents()
	connect("body_entered", Callable(self, "Hitbox_Collide"))
	set_physics_process(true)
	
func Hitbox_Collide(body):
	if !(body in player_list):
		player_list.append(body)
		var charstate
		charstate = body.get_node("StateMachine")
		weight = body.weight
		body.percentage += damage
		knockBackVal = knockback(body.percentage, damage, weight, kb_scaling, base_kb, 1) * 0.05
		s_angle(body)
		#angle_flipperer(body)
		#_angle_flipper(body)
		#print("in hitbox: " + charstate.states.keys())
		charstate.state = charstate.states.HITFREEZE
		var knockback_result = _angle_flipper2(Vector2(body.velocity.x, body.velocity.y), body.global_position)
		print("Knockback result before _hitFreeze:", knockback_result)
		charstate._hitFreeze(hitlag(damage, hitlag_modifier), knockback_result)
		body.knockback = knockBackVal
		body.hitstun = getHitstun(knockBackVal / 0.3)
		get_parent().connected = true
		body._frame()
		#charstate.state = charstate.states.HITSTUN
		Globals.hitstun(hitlag(damage,hitlag_modifier), hitlag(damage,hitlag_modifier)/60)
		get_parent().hit_pause_dur = duration - framez
		get_parent().temp_pos = get_parent().position
		get_parent().temp_vel = get_parent().velocity
		

func update_extents():
	hitbox.shape.extents = Vector2(width, height)

func _ready():
	hitbox.shape = RectangleShape2D.new()
	set_physics_process(false)
	pass

func _physics_process(delta):
	if framez < duration:
		framez += floor(delta*60)#1
	elif framez == duration:
		queue_free()
		return
	if get_parent().selfState != parentState:
		Engine.time_scale = 1
		queue_free()
		return
		
func getHitstun(knockback):
	#return floor(knockback * 0.533)
	return floor(knockback * 0.4)
	
func hitlag(d, hit):
	damage = d
	hitlag_modifier = hit
	#return floor(d/3)+4))
	return floor((((floor(d) * 0.65) + 6) * hit))

@export var percentage = 0
@export var weight = 100
@export var base_knockback = 40
@export var ratio = 1

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
	
const angleConversion = PI / 180

func getHorizontalDecay(angle):
	var decay = 0.051 * cos(angle * angleConversion)
	decay = round(decay * 100000) / 100000
	decay = decay * 1000
	return decay
	
func getVerticalDecay(angle):
	var decay = 0.051 * sin(angle * angleConversion)
	decay = round(decay * 100000) / 100000
	decay = decay * 1000
	return abs(decay)
	
func getHorizontalVelocity(knockback, angle):
	var initialHorizontal = knockback * 30
	var horizontalAngle = cos(angle * angleConversion)
	var horizontalVelocity = initialHorizontal * horizontalAngle
	horizontalVelocity = round(horizontalVelocity * 100000) / 100000
	return horizontalVelocity
	
func getVerticalVelocity(knockback, angle):
	var initialVelocity = knockback * 30
	var verticalAngle = sin(angle * angleConversion)
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
			body.velocity.x = (getHorizontalVelocity(knockBackVal, -angle))
			body.velocity.y = (getVerticalVelocity(knockBackVal, -angle))
			body.hdecay = (getHorizontalDecay(-angle))
			body.vdecay = (getVerticalDecay(angle))
		1: # Sends away from center of enemy player
			if get_parent().direction() == -1:
				xangle = -(((self.global_position.angle_to_point(body.get_parent().global_position))*180)/PI)
			else:
				xangle = (((self.global_position.angle_to_point(body.get_parent().global_position))*180)/PI)
			body.velocity.x = (getHorizontalVelocity(knockBackVal, xangle+180))
			body.velocity.y = (getVerticalVelocity(knockBackVal, -xangle))
			body.hdecay = (getHorizontalDecay(angle + 180))
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
			body.velocity.y = (getVerticalVelocity(knockBackVal, -angle))
			body.hdecay = (getHorizontalDecay(xangle))
			body.vdecay = (getVerticalDecay(angle))
		4: # horizontal knockback sends towards the center of the hitbox
			if get_parent().direction() == -1:
				xangle = -(((body.global_position.angle_to_point(self.global_position))*180)/PI)+180
			else:
				xangle = (((body.global_position.angle_to_point(self.global_position))*180)/PI)
			body.velocity.x = (getHorizontalVelocity(knockBackVal, -xangle*180))
			body.velocity.y = (getVerticalVelocity(knockBackVal, -angle))
			body.hdecay = (getHorizontalDecay(angle))
			body.vdecay = (getVerticalDecay(angle))
		5: # horizontal knockback is reversed
			body.velocity.x = (getHorizontalVelocity(knockBackVal, angle+180))
			body.velocity.y = (getVerticalVelocity(knockBackVal, -angle))
			body.hdecay = (getHorizontalDecay(angle+180))
			body.vdecay = (getVerticalDecay(angle))
		6: # horizontal knockback sends away from the enemy player
			body.velocity.x = (getHorizontalVelocity(knockBackVal, xangle))
			body.velocity.y = (getVerticalVelocity(knockBackVal, -angle))
			body.hdecay = (getHorizontalDecay(xangle))
			body.vdecay = (getVerticalDecay(angle))
		7: # horizontal knockback sends towards the center of the hitbox
			body.velocity.x = (getHorizontalVelocity(knockBackVal, -xangle+180))
			body.velocity.y = (getVerticalVelocity(knockBackVal, -angle))
			body.hdecay = (getHorizontalDecay(angle))
			body.vdecay = (getVerticalDecay(angle))

func _angle_flipper2(body_vel:Vector2, body_position:Vector2, hdecay=0, vdecay=0):
	var xangle
	if get_parent().direction() == -1:
		xangle = (-(((body_position.angle_to_point(get_parent().global_position))*180)/PI))+180
	else:
		xangle = (((body_position.angle_to_point(get_parent().global_position))*180)/PI)+180
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
			return ([body_vel.x, body_vel.y, hdecay, vdecay])
		2: # Sends towards center of enemy player
			if get_parent().direction() == -1:
				xangle = -(((body_position.angle_to_point(self.global_position))*180)/PI)
			else:
				xangle = (((body_position.angle_to_point(self.global_position))*180)/PI)
			body_vel.x = (getHorizontalVelocity(knockBackVal, -xangle+180))
			body_vel.y = (getVerticalVelocity(knockBackVal, -xangle))
			hdecay = (getHorizontalDecay(xangle + 180))
			vdecay = (getVerticalDecay(xangle))
			return ([body_vel.x, body_vel.y, hdecay, vdecay])
		3: # horizontal knockback sends away from the center of the hitbox
			if get_parent().direction() == -1:
				xangle = (-(((body_position.angle_to_point(self.global_position))*180)/PI))+180
			else:
				xangle = (((body_position.angle_to_point(self.global_position))*180)/PI)
			body_vel.x = (getHorizontalVelocity(knockBackVal, xangle))
			body_vel.y = (getVerticalVelocity(knockBackVal, -angle))
			hdecay = (getHorizontalDecay(xangle))
			vdecay = (getVerticalDecay(angle))
			return ([body_vel.x, body_vel.y, hdecay, vdecay])
		4: # horizontal knockback sends towards the center of the hitbox
			if get_parent().direction() == -1:
				xangle = -(((body_position.angle_to_point(self.global_position))*180)/PI)+180
			else:
				xangle = (((body_position.angle_to_point(self.global_position))*180)/PI)
			body_vel.x = (getHorizontalVelocity(knockBackVal, -xangle*180))
			body_vel.y = (getVerticalVelocity(knockBackVal, -angle))
			hdecay = (getHorizontalDecay(angle))
			vdecay = (getVerticalDecay(angle))
			return ([body_vel.x, body_vel.y, hdecay, vdecay])
		5: # horizontal knockback is reversed
			body_vel.x = (getHorizontalVelocity(knockBackVal, angle+180))
			body_vel.y = (getVerticalVelocity(knockBackVal, -angle))
			hdecay = (getHorizontalDecay(angle+180))
			vdecay = (getVerticalDecay(angle))
			return ([body_vel.x, body_vel.y, hdecay, vdecay])
		6: # horizontal knockback sends away from the enemy player
			body_vel.x = (getHorizontalVelocity(knockBackVal, xangle))
			body_vel.y = (getVerticalVelocity(knockBackVal, -angle))
			hdecay = (getHorizontalDecay(xangle))
			vdecay = (getVerticalDecay(angle))
			print("This is where it should be")
			return ([body_vel.x, body_vel.y, hdecay, vdecay])
		7: # horizontal knockback sends towards the center of the hitbox
			body_vel.x = (getHorizontalVelocity(knockBackVal, -xangle+180))
			body_vel.y = (getVerticalVelocity(knockBackVal, -angle))
			hdecay = (getHorizontalDecay(angle))
			vdecay = (getVerticalDecay(angle))
			return ([body_vel.x, body_vel.y, hdecay, vdecay])

#func _on_area_entered(area):
	## Handle collision logic here
	#print("Hitbox collided with:", area.name)
	#pass
