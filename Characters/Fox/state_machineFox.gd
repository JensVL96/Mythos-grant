extends StateMachine
#@export var id: int
@onready var id = get_parent().id

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_state('STAND')
	add_state('JUMP_SQUAT')
	add_state('SHORT_HOP')
	add_state('FULL_HOP')
	add_state('DASH')
	add_state('MOONWALK')
	add_state('WALK')
	add_state('AIR')
	add_state('LANDING')
	add_state('TURN')
	add_state('RUN')
	add_state('CROUCH')
	add_state('LEDGE_CATCH')
	add_state('LEDGE_HOLD')
	add_state('LEDGE_CLIMB')
	add_state('LEDGE_JUMP')
	add_state('LEDGE_ROLL')
	#add_state('AIRDASH')
	add_state('GROUND_ATTACK')
	add_state('DOWN_TILT')
	add_state('UP_TILT')
	add_state('FORWARD_TILT')
	add_state('JAB')
	add_state('AIR_ATTACK')
	add_state('NAIR')
	add_state('UAIR')
	add_state('BAIR')
	add_state('FAIR')
	add_state('DAIR')
	add_state('HITSTUN')
	add_state('HITFREEZE')
	add_state('TEST')
	
	#print("States in StateMachine:", states.keys())
	
	#if "STAND" in states:
	call_deferred("set_state", states.STAND)
		#print("Player", id, " initialized in STAND state")

func state_logic(delta):
	parent.update_frames(delta)
	parent._physics_process(delta)
	
	if parent.regrab > 0:
		parent.regrab -= 1
	parent._hit_pause(delta)
	#parent.sword._physics_process(delta)

func get_transition(delta):
	parent.set_up_direction(Vector2.UP)
	parent.move_and_slide()

	##print("Checking transition for state:", state, "Player ID:", id)  # Add Player ID for clarity
	if LANDING():
		parent._frame()
		return states.LANDING
		
	if FALLING():
		return states.AIR
		
	if Ledge():
		parent._frame()
		return states.LEDGE_CATCH
	else:
		parent.reset_ledge()
		
	if Input.is_action_pressed("attack_" + str(id)) && TILT():
		parent._frame()
		return states.GROUND_ATTACK
		
	if Input.is_action_pressed("attack_" + str(id)) && AIREAL():
		if Input.is_action_pressed("up_" + str(id)):
			parent._frame()
			return states.UAIR
		if Input.is_action_pressed("down_" + str(id)):
			parent._frame()
			return states.DAIR
		match parent.direction():
			1:
				if Input.is_action_pressed("left_" + str(id)):
					parent._frame()
					return states.BAIR
				if Input.is_action_pressed("right_" + str(id)):
					parent._frame()
					return states.FAIR
			-1:
				if Input.is_action_pressed("right_" + str(id)):
					parent._frame()
					return states.BAIR
				if Input.is_action_pressed("left_" + str(id)):
					parent._frame()
					return states.FAIR
		parent._frame()
		return states.AIR
		
	if Input.is_action_pressed("shield_" + str(id)) && AIREAL() && parent.cooldown == 0:
		parent.l_cancel = 11
		parent.cooldown = 40

	#if Input.is_action_pressed("swing_" + str(id)):
		#parent._frame()
		##parent.sword.swing() #parent.direction()
		#return states.GROUND_ATTACK
#
	match state:
		states.STAND:
			parent.reset_Jumps()
			if Input.is_action_just_pressed("jump_" + str(id)):
				parent._frame()
				return states.JUMP_SQUAT
			if Input.is_action_pressed("down_" + str(id)):
				parent._frame()
				return states.CROUCH
			#if Input.is_action_just_pressed("dash_" + str(id)):
				#print("Player", id, "pressed dash! Transitioning to AIRDASH")
				#return states.AIRDASH
			if Input.get_action_strength("right_" + str(id)):
				parent.velocity.x = parent.RUNSPEED
				parent._frame()
				parent.turn(false)
				return states.DASH  # Transition to DASH state
			elif Input.get_action_strength("left_" + str(id)):
				parent.velocity.x = -parent.RUNSPEED
				parent._frame()
				parent.turn(true)
				return states.DASH
			#else:
			if parent.velocity.x > 0 and state == states.STAND:
				parent.velocity.x += -parent.TRACTION*1
				parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				#parent.velocity.x = move_toward(parent.velocity.x, 0, parent.TRACTION * delta)
			elif parent.velocity.x < 0 and state == states.STAND:
				parent.velocity.x += parent.TRACTION*1
				parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				#parent.velocity.x = move_toward(parent.velocity.x, 0, parent.TRACTION * delta)
	#
		states.JUMP_SQUAT:
			if parent.frame == parent.jump_squat:
				#if (Input.is_action_pressed("shield_" + str(id))) and (Input.is_action_pressed("left_" + str(id))) or (Input.is_action_pressed("right_" + str(id))):
					#if Input.is_action_pressed("right_" + str(id)):
						#parent.velocity.x = parent.air_dodge_speed / parent.perfect_airdash_modifier
					#if Input.is_action_pressed("left_" + str(id)):
						#parent.velocity.x = -parent.air_dodge_speed / parent.perfect_airdash_modifier
					#parent.lag_frames = 6
					#parent._frame()
					#return states.LANDING
				if not Input.is_action_pressed("jump_" + str(id)):
					parent.velocity.x = lerpf(parent.velocity.x, 0, 0.08)
					#parent.velocity.x = lerpf(parent.velocity.x, parent.dash_momentum.x, 0.08)
					parent._frame()
					return states.SHORT_HOP
				else:
					parent.velocity.x = lerpf(parent.velocity.x, 0, 0.08)
					#parent.velocity.x = lerpf(parent.velocity.x, parent.dash_momentum.x, 0.08)
					parent._frame()
					return states.FULL_HOP
	#
		states.SHORT_HOP:
			parent.velocity.y = -parent.JUMPFORCE
			parent._frame()
			return states.AIR
	#
		states.FULL_HOP:
			parent.velocity.y = -parent.MAX_JUMPFORCE
			parent._frame()
			return states.AIR
	#
		states.DASH:
			if Input.is_action_just_pressed("jump_" + str(id)):
				parent._frame()
				return states.JUMP_SQUAT
			if Input.is_action_pressed("left_" + str(id)):
				if parent.velocity.x > 0:
					parent._frame()
				parent.velocity.x = -parent.DASHSPEED
				if parent.frame <= parent.dash_duration - 1:
					if Input.is_action_just_pressed("down_" + str(id)):
						parent._frame()
						return states.CROUCH
					parent.turn(true)
					return states.DASH
				else:
					parent.turn(true)
					parent._frame()
					return states.RUN
			elif Input.is_action_pressed("right_" + str(id)):
				if parent.velocity.x < 0:
					parent._frame()
				parent.velocity.x = parent.DASHSPEED
				if parent.frame <= parent.dash_duration - 1:
					if Input.is_action_just_pressed("down_" + str(id)):
						parent._frame()
						return states.MOONWALK
					parent.turn(false)
					return states.DASH
				else:
					parent.turn(false)
					parent._frame()
					return states.RUN
			else:
				if parent.frame >= parent.dash_duration - 1:
					for state in states:
						if state != "JUMP_SQUAT":
							parent._frame()
							return states.STAND
	#
		states.WALK:
			if Input.is_action_just_pressed("jump_" + str(id)):
				parent._frame()
				return states.JUMP_SQUAT
			if Input.is_action_just_pressed("down_" + str(id)):
				parent._frame()
				return states.CROUCH
			if Input.get_action_strength("left_" + str(id)):
				if parent.velocity.x <= 0:
					parent.velocity.x = -parent.WALKSPEED * Input.get_action_strength("left_" + str(id))
					parent.turn(false)
			elif Input.get_action_strength("right_" + str(id)):
				if parent.velocity.x >= 0:
					parent.velocity.x = parent.WALKSPEED * Input.get_action_strength("right_" + str(id))
					parent.turn(true)
			else:
				parent._frame()
				return states.STAND
	
		states.CROUCH:
			if Input.is_action_just_pressed("jump_" + str(id)):
				parent._frame()
				return states.JUMP_SQUAT
			if Input.is_action_just_released("down_" + str(id)):
				parent._frame()
				return states.STAND
			elif parent.velocity.x > 0:
				if parent.velocity.x > parent.RUNSPEED:
					parent.velocity.x += -(parent.TRACTION * 4)
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				else:
					parent.velocity.x += -(parent.TRACTION / 2)
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			elif parent.velocity.x < 0:
				if abs(parent.velocity.x) > parent.RUNSPEED:
					parent.velocity.x += (parent.TRACTION * 4)
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				else:
					parent.velocity.x += (parent.TRACTION / 2)
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
	
		states.RUN:
			if Input.is_action_just_pressed("jump_" + str(id)):
				parent._frame()
				return states.JUMP_SQUAT
			if Input.is_action_just_pressed("down_" + str(id)):
				parent._frame()
				return states.CROUCH
			if Input.get_action_strength("left_" + str(id)):
				if parent.velocity.x <= 0:
					parent.velocity.x = -parent.RUNSPEED
					parent.turn(true)
				else:
					parent._frame()
					return states.TURN
			elif Input.get_action_strength("right_" + str(id)):
				if parent.velocity.x >= 0:
					parent.velocity.x = parent.RUNSPEED
					parent.turn(false)
				else:
					parent._frame()
					return states.TURN
			else:
				parent._frame()
				return states.STAND
	
		states.TURN:
			if Input.is_action_just_pressed("jump_" + str(id)):
				parent._frame()
				return states.JUMP_SQUAT
			if parent.velocity.x > 0:
				parent.turn(true)
				parent.velocity.x += -parent.TRACTION * 2
				parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			elif parent.velocity.x < 0:
				parent.turn(false)
				parent.velocity.x += parent.TRACTION * 2
				parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
			else:
				if not Input.is_action_pressed("left_" + str(id)) and not Input.is_action_pressed("right_" + str(id)):
					parent._frame()
					return states.STAND
				else:
					parent._frame()
					return states.RUN

		states.MOONWALK:
			if Input.is_action_just_pressed("jump_" + str(id)):
				parent._frame()
				return states.JUMP_SQUAT
			elif Input.is_action_pressed("left_" + str(id)) and parent.direction():
				if parent.velocity.x > 0:
					parent._frame()
				parent.velocity.x += -parent.AIR_ACCEL * Input.get_action_strength("left_" + str(id))
				parent.velocity.x = clampf(parent.velocity.x, -parent.DASHSPEED * 1.4, parent.velocity.x)
				if parent.frame <= parent.dash_duration * 2:
					parent.turn(false)
					return states.MOONWALK
				else:
					parent.turn(true)
					parent._frame()
					return states.STAND

			elif Input.is_action_pressed("right_" + str(id)) and parent.direction() == -1:
				if parent.velocity.x < 0:
					parent._frame()
				parent.velocity.x += parent.AIR_ACCEL * Input.get_action_strength("right_" + str(id))
				parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, parent.DASHSPEED * 1.5)
				if parent.frame <= parent.dash_duration * 2:
					parent.turn(true)
					return states.MOONWALK
				else:
					parent.turn(false)
					return states.STAND
			else:
				if parent.frame >= parent.dash_duration - 1:
					for state in states:
						if state != 'JUMP_SQUAT':
							return states.STAND

	
		states.AIR:
			#if Input.is_action_just_pressed("dash_" + str(id)):
				#return states.AIRDASH
			AIRMOVEMENT()
			if Input.is_action_just_pressed("jump_" + str(id)):
				parent.fastfall = false
				parent.velocity.x = 0
				parent.velocity.y = -parent.DOUBLEJUMPFORCE
				parent.airJump -= 1
				if Input.is_action_just_pressed("left_" + str(id)):
					parent.velocity.x = -parent.MAXAIRSPEED
				if Input.is_action_just_pressed("right_" + str(id)):
					parent.velocity.x = parent.MAXAIRSPEED

		states.HITFREEZE:
			if parent.freezeFrames == 0:
				parent._frame()
				parent.velocity.x = kbx
				parent.velocity.y = kby
				parent.hdecay = hd
				parent.vdecay = vd
				return states.HITSTUN
			parent.position = pos
			
		states.HITSTUN:
			if parent.knockback >= 3:
				var bounce = parent.move_and_collide(parent.velocity * delta)
				if bounce:
					parent.velocity = parent.velocity.bounce(bounce.normal) * 0.8
					parent.hitstun = round(parent.hitstun * 0.8)
			if parent.velocity.y < 0:
				parent.velocity.y += parent.vdecay * 0.5 * Engine.time_scale
				parent.velocity.y = clampf(parent.velocity.y, parent.velocity.y, 0)
			if parent.velocity.x < 0:
				parent.velocity.x += parent.hdecay * 0.4 * -1 * Engine.time_scale
				parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
			elif parent.velocity.x > 0:
				parent.velocity.x -= parent.hdecay * 0.4 * Engine.time_scale
				parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			
			if parent.frame >= parent.hitstun:
				if parent.knockback >= 24:
					parent._frame()
					return states.AIR
				else:
					parent._frame()
					return states.AIR
			elif parent.frame > 60 * 5:
				return states.AIR
#
		states.LANDING:
			if parent.frame == 1:
				if parent.l_cancel >= 0:
					parent.lag_frames = floor(parent.lag_frames/2)
			if parent.frame <= parent.landing_frames + parent.lag_frames:
				if parent.frame > 0:
					parent.velocity.x = parent.velocity.x - parent.TRACTION / 2
					#parent.velocity.x = lerpf(parent.velocity.x, parent.dash_momentum.x, 0.5)  # Preserve dash momentum
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.frame < 0:
					parent.velocity.x = parent.velocity.x + parent.TRACTION / 2
					#parent.velocity.x = lerpf(parent.velocity.x, parent.dash_momentum.x, 0.5)
					parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
				if Input.is_action_pressed("jump_" + str(id)):
					parent._frame()
					return states.JUMP_SQUAT
			else:
				if Input.is_action_pressed("down_" + str(id)):
					parent.lag_frames = 0
					parent._frame()
					parent.reset_Jumps()
					return states.CROUCH
				else:
					parent._frame()
					parent.lag_frames = 0
					parent.reset_Jumps()
					return states.STAND
				parent.lag_frames = 0
				
		states.LEDGE_CATCH:
			if parent.frame > 7:
				parent.lag_frames = 0
				parent.reset_jumps()
				parent._frame()
				return states.LEDGE_HOLD

		states.LEDGE_HOLD:
			if parent.frame >= 390:
				self.parent.position.y += -25
				parent._frame()
				return states.AIR #TUMBLE
			if Input.is_action_just_pressed("down_" + str(id)):
				parent.fastfall = true
				parent.regrab = 30
				parent.reset_ledge()
				self.parent.position.y += -25
				parent.catch = false
				parent._frame()
				return states.AIR

			elif parent.Ledge_Grab_F.target_position.x > 0:
				if Input.is_action_just_pressed("left_" + str(id)):
					parent.velocity.x = (parent.AIR_ACCEL/2)
					parent.regrab = 30
					parent.reset_ledge()
					self.parent.position.y += -25
					parent.catch = false
					parent._frame()
					return states.AIR
				elif Input.is_action_just_pressed("right_" + str(id)):
					parent._frame()
					return states.LEDGE_CLIMB
				elif Input.is_action_just_pressed("shield_" + str(id)):
					parent._frame()
					return states.LEDGE_ROLL
				elif Input.is_action_just_pressed("jump_" + str(id)):
					parent._frame()
					return states.LEDGE_JUMP

			elif parent.Ledge_Grab_F.target_position.x < 0:
				if Input.is_action_just_pressed("right_" + str(id)):
					parent.velocity.x = (parent.AIR_ACCEL/2)
					parent.regrab = 30
					parent.reset_ledge()
					self.parent.position.y += -25
					parent.catch = false
					parent._frame()
					return states.AIR
				elif Input.is_action_just_pressed("left_" + str(id)):
					parent._frame()
					return states.LEDGE_CLIMB
				elif Input.is_action_just_pressed("shield_" + str(id)):
					parent._frame()
					return states.LEDGE_ROLL
				elif Input.is_action_just_pressed("jump_" + str(id)):
					parent._frame()
					return states.LEDGE_JUMP

		states.LEDGE_CLIMB:
			if parent.frame == 1:
				pass
			if parent.frame == 5:
				parent.position.y -= 25
			if parent.frame == 10:
				parent.position.y -= 25
			if parent.frame == 20:
				parent.position.y -= 25
			if parent.frame == 22:
				parent.catch = false
				parent.position.y -= 25
				parent.position.x += 50 * parent.direction()
			if parent.frame == 25:
				parent.position.y = 0
				parent.position.x = 0
				parent.move_and_collide(Vector2(parent.direction()*20, 50))
			if parent.frame == 30:
				parent.reset_ledge()
				parent._frame()
				return states.STAND

		states.LEDGE_JUMP:
			if parent.frame > 14:
				if Input.is_action_just_pressed("attack_" + str(id)):
					parent._frame()
					return states.AIR_ATTACK
				if Input.is_action_just_pressed("special_" + str(id)):
					parent._frame()
					return states.SPECIAL
			if parent.frame == 5:
				parent.reset_ledge()
				parent.position.y -= 20
			if parent.frame == 10:
				parent.catch = false
				parent.position.y -= 20
				if Input.is_action_just_pressed("jump_" + str(id)):
					parent.fastfall = false
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.velocity.x = 0
					parent.airJump -= 1
					parent._frame()
					return states.AIR
			if parent.frame == 15:
				parent.position.y -= 20
				parent.velocity.y -= parent.DOUBLEJUMPFORCE
				parent.velocity.x += 220 * parent.direction()
				if Input.is_action_just_pressed("jump_" + str(id)) and parent.airJump > 0:
					parent.fastfall = false
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.velocity.x = 0
					parent.airJump -= 1
					parent._frame()
					return states.AIR
				if Input.is_action_just_pressed("attack_" + str(id)):
					parent._frame()
					return states.AIR_ATTACK
			elif parent.frame > 15 and parent.frame < 20:
				parent.position.y += parent.FALLSPEED
				if Input.is_action_just_pressed("jump_" + str(id)) and parent.airJump > 0:
					parent.fastfall = false
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.velocity.x = 0
					parent.airJump -= 1
					parent._frame()
					return states.AIR
				if Input.is_action_just_pressed("attack_" + str(id)):
					parent._frame()
					return states.AIR_ATTACK
			if parent.frame == 20:
				parent._frame()
				return states.AIR

		states.LEDGE_ROLL:
			if parent.frame == 1:
				pass
			if parent.frame == 5:
				parent.position.y -= 30
			if parent.frame == 10:
				parent.position.y -= 30

			if parent.frame == 20:
				parent.catch = false
				parent.position.y -= 30

			if parent.frame == 22:
				parent.position.y -= 30
				parent.position.x += 50 * parent.direction()

			if parent.frame > 22 and parent.frame < 28:
				parent.position.x += 30 * parent.direction()

			if parent.frame == 29:
				parent.move_and_collide(Vector2(parent.direction()*20, 50))
			if parent.frame == 30:
				parent.position.y = 0
				parent.position.x = 0
				parent.reset_ledge()
				parent._frame()
				return states.STAND

		states.GROUND_ATTACK:
			if Input.is_action_pressed("up_" + str(id)):
				parent._frame()
				return states.UP_TILT
			if Input.is_action_pressed("down_" + str(id)):
				parent._frame()
				return states.DOWN_TILT
			if Input.is_action_pressed("left_" + str(id)):
				parent.turn(true)
				parent._frame()
				return states.FORWARD_TILT
			elif Input.is_action_pressed("right_" + str(id)):
				parent.turn(false)
				parent._frame()
				return states.FORWARD_TILT
			else:
				parent._frame()
				return states.JAB

		states.DOWN_TILT:
			if parent.frame == 0:
				parent.DOWN_TILT()
				pass
			if parent.frame >= 1:
				if parent.velocity.x > 0:
					parent.velocity.x += -parent.TRACTION*3
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				elif parent.velocity.x < 0:
					parent.velocity.x += parent.TRACTION*3
					parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
			if parent.DOWN_TILT():
				if Input.is_action_pressed("down_" + str(id)):
					parent._frame()
					return states.CROUCH
				else:
					parent._frame()
					return states.STAND

		states.UP_TILT:
			if parent.frame == 0:
				parent.UP_TILT()  # Your existing hitbox setup
			
			# Freeze horizontal movement
			if parent.frame >= 1:
				parent.velocity.x = lerpf(parent.velocity.x, 0, 0.5)  # Stronger slowdown
			
			# End after animation
			if parent.UP_TILT():  # Your custom completion check
				parent._frame()
				return states.STAND

		states.FORWARD_TILT:
			if parent.frame == 0:
				parent.FORWARD_TILT()  # Your existing hitbox setup
			
			# Apply traction during active frames
			if parent.frame >= 1:
				if parent.velocity.x > 0:
					parent.velocity.x = lerpf(parent.velocity.x, 0, 0.2)  # Gentle slowdown
				elif parent.velocity.x < 0:
					parent.velocity.x = lerpf(parent.velocity.x, 0, 0.2)
			
			# Return to STAND after 12 frames (or when attack completes)
			if parent.FORWARD_TILT():  # Your custom completion check
				parent._frame()
				return states.STAND

		states.JAB:
			if parent.frame == 0:
				parent.JAB()  # Your existing hitbox setup
			
			# Rapid jab input check (hold attack button to continue)
			if parent.frame == 3:
				parent._frame()  # Reset timer for rapid jabs
				return states.JAB
			
			# End jab after 8 frames or if button released
			if parent.frame >= 8:
				parent._frame()
				return states.STAND

		states.AIR_ATTACK:
			AIRMOVEMENT()
			if Input.is_action_pressed("up_" + str(id)):
				parent._frame()
				return states.UAIR
			if Input.is_action_pressed("down_" + str(id)):
				parent._frame()
				return states.DAIR
			match parent.direction():
				1:
					if Input.is_action_pressed("left_" + str(id)):
						parent._frame()
						return states.BAIR
					if Input.is_action_pressed("right_" + str(id)):
						parent._frame()
						return states.FAIR
				-1:
					if Input.is_action_pressed("right_" + str(id)):
						parent._frame()
						return states.BAIR
					if Input.is_action_pressed("left_" + str(id)):
						parent._frame()
						return states.FAIR
			parent._frame()
			return states.NAIR

		states.NAIR:
			AIRMOVEMENT()
			if parent.frame == 0:
				print("nair")
				parent.NAIR()
			if parent.NAIR():
				parent.lag_frames = 0
				parent._frame()
				return states.AIR
			elif parent.frame < 5:
				parent.lag_frames = 0
			elif parent.frame > 15:
				parent.lag_frames = 0
			else:
				parent.lag_frames = 7

		states.UAIR:
			AIRMOVEMENT()
			if parent.frame == 0:
				print("uair")
				parent.UAIR()
			if parent.UAIR():
				parent.lag_frames = 0
				parent._frame()
				return states.AIR
			else:
				parent.lag_frames = 13

		states.BAIR:
			AIRMOVEMENT()
			if parent.frame == 0:
				print("bair")
				parent.BAIR()
			if parent.BAIR():
				parent.lag_frames = 0
				parent._frame()
				return states.AIR
			else:
				parent.lag_frames = 9

		states.FAIR:
			AIRMOVEMENT()
			if Input.is_action_pressed("jump_" + str(id)) and parent.airJump > 0:
				parent.fastfall = false
				parent.velocity.x = 0
				parent.veloity.y = -parent.DOUBLEJUMPFORCE
				parent.airJump -= 1
				if Input.is_action_pressed("left_" + str(id)):
					parent.velocity.x = -parent.MAXAIRSPEED
				elif Input.is_action_pressed("right_" + str(id)):
					parent.velocity.x = parent.MAXAIRSPEED
				return states.AIR
			if parent.frame == 0:
				print("fair")
				parent.FAIR()
			if parent.FAIR():
				parent.lag_frames = 30
				parent._frame()
				return states.AIR
			else:
				parent.lag_frames = 18

		states.DAIR:
			AIRMOVEMENT()
			if parent.frame == 0:
				print("dair")
				parent.DAIR()
			if parent.DAIR():
				parent.lag_frames = 0
				parent._frame()
				return states.AIR
			else:
				parent.lag_frames = 17

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

# Animations
func enter_state(new_state, old_state):
	match new_state:
		states.STAND:
			parent.play_animation("Idle")
			parent.state_label.text = str("STAND")
		states.DASH:
			#parent.play_animation("DASH")
			parent.state_label.text = str("DASH")
		states.WALK:
			#parent.play_animation("WALK")
			parent.state_label.text = str("WALK")
		states.MOONWALK:
			#parent.play_animation("WALK")
			parent.state_label.text = str("MOONWALK")
		states.TURN:
			#parent.play_animation("TURN")
			parent.state_label.text = str("TURN")
		states.CROUCH:
			#parent.play_animation("CROUCH")
			parent.state_label.text = str("CROUCH")
		states.RUN:
			#parent.play_animation("RUN")
			parent.state_label.text = str("RUN")
		states.JUMP_SQUAT:
			#parent.play_animation("JUMP_SQUAT")
			parent.state_label.text = str("JUMP_SQUAT")
		states.SHORT_HOP:
			#parent.play_animation("AIR")
			parent.state_label.text = str("SHORT_HOP")
		states.FULL_HOP:
			#parent.play_animation("AIR")
			parent.state_label.text = str("FULL_HOP")
		states.AIR:
			#parent.play_animation("AIR")
			parent.state_label.text = str("AIR")
		states.HITFREEZE:
			#parent.play_animation("HITSTUN")
			parent.state_label.text = str("HITFREEZE")
		states.HITSTUN:
			#parent.play_animation("HITSTUN")
			parent.state_label.text = str("HITSTUN")
		states.LANDING:
			#parent.play_animation("LANDING")
			parent.state_label.text = str("LANDING")
		states.LEDGE_CATCH:
			#parent.play_animation("LEDGE_CATCH")
			parent.state_label.text = str("LEDGE_CATCH")
		states.LEDGE_HOLD:
			#parent.play_animation("LEDGE_CATCH")
			parent.state_label.text = str("LEDGE_HOLD")
		states.LEDGE_JUMP:
			#parent.play_animation("AIR")
			parent.state_label.text = str("LEDGE_JUMP")
		states.LEDGE_CLIMB:
			#parent.play_animation("ROLL_FORWARD")
			parent.state_label.text = str("LEDGE_CLIMB")
		states.LEDGE_ROLL:
			#parent.play_animation("ROLL_FORWARD")
			parent.state_label.text = str("LEDGE_ROLL")
		states.GROUND_ATTACK:
			parent.state_label.text = str("GROUND_ATTACK")
		states.DOWN_TILT:
			parent.play_animation("Down_tilt")
			parent.state_label.text = str("DOWN_TILT")
		states.UP_TILT:
			#parent.play_animation("UP_TILT")
			parent.state_label.text = str("UP_TILT")
		states.FORWARD_TILT:
			#parent.play_animation("FORWARD_TILT")
			parent.state_label.text = str("FORWARD_TILT")
		states.JAB:
			parent.state_label.text = str("JAB")
		states.AIR_ATTACK:
			parent.state_label.text = str("AIR_ATTACK")
		states.NAIR:
			#parent.play_animation("NAIR")
			parent.state_label.text = str("NAIR")
		states.UAIR:
			#parent.play_animation("UAIR")
			parent.state_label.text = str("UAIR")
		states.BAIR:
			parent.play_animation("Bair")
			parent.state_label.text = str("BAIR")
		states.FAIR:
			#parent.play_animation("FAIR")
			parent.state_label.text = str("FAIR")
		states.DAIR:
			#parent.play_animation("DAIR")
			parent.state_label.text = str("DAIR")
		#states.AIRDASH:
			#parent.play_animation("AIRDASH")
			#parent.state_label.text = str("AIRDASH")
			#parent.dash_timer = parent.airdash_duration  # Initialize dash timer
			#parent.dash_momentum = parent.velocity

func exit_state(old_state, new_state):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func state_includes(state_array):
	for each_state in state_array:
		if state == each_state:
			return true
	return false

func AIRMOVEMENT():
	if parent.velocity.y < parent.FALLINGSPEED:
		parent.velocity.y += parent.FALLSPEED
	if Input.is_action_pressed("down_" + str(id)) and parent.velocity.y > -150 and not parent.fastfall: #and parent.down_buffer == 1
		parent.velocity.y = parent.MAXFALLSPEED
		parent.fastfall = true
	if parent.fastfall:
		parent.set_collision_mask_value(3, false)
		parent.velocity.y = parent.MAXFALLSPEED
	
	# Clamp vertical velocity to prevent excessive speed
	#parent.velocity.y = clampf(parent.velocity.y, -parent.MAX_JUMPFORCE, parent.MAXFALLSPEED)
	
	# Horizontal air movement
	if abs(parent.velocity.x) >= abs(parent.MAXAIRSPEED):
		if parent.velocity.x > 0:
			if Input.is_action_pressed("left_" + str(id)):
				parent.velocity.x += -parent.AIR_ACCEL
			elif Input.is_action_pressed("right_" + str(id)):
				parent.velocity.x = parent.velocity.x
		if parent.velocity.x < 0:
			if Input.is_action_pressed("left_" + str(id)):
				parent.velocity.x = parent.velocity.x
			elif Input.is_action_pressed("right_" + str(id)):
				parent.velocity.x += parent.AIR_ACCEL

	elif abs(parent.velocity.x) < abs(parent.MAXAIRSPEED):
		if Input.is_action_pressed("left_" + str(id)):
			parent.velocity.x += -parent.AIR_ACCEL
		elif Input.is_action_pressed("right_" + str(id)):
			parent.velocity.x += parent.AIR_ACCEL
	
	# Apply air friction if no horizontal input
	if not Input.is_action_pressed("left_" + str(id)) and not Input.is_action_pressed("right_" + str(id)):
		if parent.velocity.x < 0:
			parent.velocity.x += parent.AIR_ACCEL / 5
		elif parent.velocity.x > 0:
			parent.velocity.x += -parent.AIR_ACCEL / 5

func LANDING():
	#if state == states.AIRDASH:
		#return false

	if state_includes([states.AIR, states.NAIR, states.BAIR, states.FAIR, states.UAIR, states.DAIR]):
		if parent.GroundL.is_colliding() or parent.GroundR.is_colliding() and parent.velocity.y >= 0:
			var collider = parent.GroundL.get_collider()
			parent.frame = 0
			if parent.velocity.y > 0:
				parent.velocity.y = 0
			parent.fastfall = false
			return true
		if parent.GroundR.is_colliding() and parent.velocity.y > 0:
			var collider = parent.GroundR.get_collider()
			parent.frame = 0
			if parent.velocity.y > 0:
				parent.velocity.y = 0
			parent.fastfall = false
			return true
		
		# Only transition to LANDING if the player is moving downward (velocity.y >= 0)
		#if (parent.GroundL.is_colliding() or parent.GroundR.is_colliding()) and parent.velocity.y >= 0:
			#print("Landing detected. Resetting velocity.y.")
			#parent.velocity.y = 0
			#parent.fastfall = false
			#return true
	#return false
	#if state_includes([states.AIR]):
		#if (parent.GroundL.is_colliding()) and parent.velocity.y > 0:
			#var collider = parent.GroundL.get_collider()
			#parent.frame = 0
			#if parent.velocity.y > 0:
				#parent.velocity.y = 0
			#parent.fastfall = false
			#return true
			#
		#elif parent.GroundR.is_colliding() and parent.velocity.y > 0:
			#var collider2 = parent.GroundR.get_collider()
			#parent.frame = 0
			#if parent.velocity.y > 0:
				#parent.velocity.y = 0
			#parent.fastfall = false
			#return true

func FALLING():
	#if state_includes([states.RUN, states.WALK, states.STAND, states.CROUCH, states.DASH, states.LANDING, states.TURN, states.JUMP_SQUAT, states.MOONWALK, states.ROLL_RIGHT, states.ROLL_LEFT, states.PARRY]):
	if state_includes([states.STAND, states.DASH, states.RUN, states.WALK, states.CROUCH, states.MOONWALK]):
		if not parent.GroundL.is_colliding() and not parent.GroundR.is_colliding():
			return true
			
func Ledge():
	if state_includes([states.AIR]):
		if (parent.Ledge_Grab_F.is_colliding()):
			var collider = parent.Ledge_Grab_F.get_collider()
			if collider.get_node('Label').text == 'Ledge_L' and !Input.get_action_strength('down_' + str(id)) > 0.6 and parent.regrab == 0 && !collider.is_grabbed:
				if state_includes([states.AIR]):
					if parent.velocity.y < 0:
						return false
				parent.frame = 0
				parent.velocity.x = 0
				parent.velocity.y = 0
				self.parent.position.x = collider.position.x + 20
				self.parent.position.y = collider.position.y + 1
				parent.turn(false)
				parent.reset_Jumps()
				parent.fastfall = false
				collider.is_grabbed = true
				parent.last_ledge = collider
				return true
				
			if collider.get_node('Label').text == 'Ledge_R' and !Input.get_action_strength('down_' + str(id)) > 0.6 and parent.regrab == 0 && !collider.is_grabbed:
				if state_includes([states.AIR]):
					if parent.velocity.y < 0:
						return false
				parent.frame = 0
				parent.velocity.x = 0
				parent.velocity.y = 0
				self.parent.position.x = collider.position.x + 20
				self.parent.position.y = collider.position.y + 1
				parent.turn(true)
				parent.reset_Jumps()
				parent.fastfall = false
				collider.is_grabbed = true
				parent.last_ledge = collider
				return true
				
		if (parent.Ledge_Grab_B.is_colliding()):
			var collider = parent.Ledge_Grab_B.get_collider()
			if collider.get_node('Label').text == 'Ledge_L' and !Input.get_action_strength('down_' + str(id)) > 0.6 and parent.regrab == 0 && !collider.is_grabbed:
				if state_includes([states.AIR]):
					if parent.velocity.y < 0:
						return false
				parent.frame = 0
				parent.velocity.x = 0
				parent.velocity.y = 0
				self.parent.position.x = collider.position.x - 20
				self.parent.position.y = collider.position.y - 1
				parent.turn(false)
				parent.reset_Jumps()
				parent.fastfall = false
				collider.is_grabbed = true
				parent.last_ledge = collider
				return true
				
			if collider.get_node('Label').text == 'Ledge_R' and !Input.get_action_strength('down_' + str(id)) > 0.6 and parent.regrab == 0 && !collider.is_grabbed:
				if state_includes([states.AIR]):
					if parent.velocity.y < 0:
						return false
				parent.frame = 0
				parent.velocity.x = 0
				parent.velocity.y = 0
				self.parent.position.x = collider.position.x - 20
				self.parent.position.y = collider.position.y - 1
				parent.turn(true)
				parent.reset_Jumps()
				parent.fastfall = false
				collider.is_grabbed = true
				parent.last_ledge = collider
				return true

func TILT():
	if state_includes([states.RUN, states.WALK, states.STAND, states.CROUCH, states.DASH, states.MOONWALK]):
		return true
			

func AIREAL():
	if state_includes([states.AIR, states.DAIR, states.NAIR]):
		if !(parent.GroundL.is_colliding() and parent.GroundR.is_colliding()):
			return true
		else:
			return false

var kbx
var kby
var hd
var vd
var pos

func _hitFreeze(duration, knockback):
	pos = parent.get_position()
	parent.freezeFrames = duration
	kbx = knockback[0]
	kby = knockback[1]
	hd = knockback[2]
	vd = knockback[3]
