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
	add_state('AIRDASH')
	add_state('AIRDASH_TRAVEL')
	add_state('GROUNDDASH')
	add_state('GROUNDDASH_TRAVEL')
	add_state('GROUNDDASH_JUMP')
	add_state('SWING')
	add_state('HITSTUN')
	add_state('HITFREEZE')
	add_state('DYING')
	
	call_deferred("set_state", states.STAND)

func state_logic(delta):
	parent.update_frames(delta)
	parent._physics_process(delta)
	parent._hit_pause(delta)
	
	if parent.dash_jump_window > 0:
		parent.dash_jump_window -= 1

func get_transition(delta):
	parent.set_up_direction(Vector2.UP)
	parent.move_and_slide()

	if LANDING():
		parent._frame()
		return states.LANDING
		
	if FALLING():
		return states.AIR

	if Input.is_action_just_pressed("dash_" + str(id)):
		if parent.is_on_floor():
			return states.GROUNDDASH
		else:
			return states.AIRDASH

	#if Input.is_action_just_pressed("attack_" + str(id)):
		#parent._frame()
		##parent.sword.swing() #parent.direction()
		#return states.SWING
		
	if Input.is_action_just_pressed("attack_" + str(id)):
		parent._frame()
		parent.trigger_sword_attack()
	
	if Input.is_action_just_released("attack_" + str(id)):
		parent._frame()
		parent.release_sword_attack()
		
	#if Input.is_action_pressed("down_" + str(id)) and parent.is_on_floor():
		## Start dropping through platform
		#parent.dropping_through_platforms = true
		#parent.platform_drop_timer = 0.3  # Duration you ignore the platform
		#parent.set_collision_mask_value(3, false)  # Temporarily ignore platform layer
		#
		#parent.position.y += 50
#
	match state:
		states.STAND:
			parent.reset_Jumps()
			if Input.is_action_just_pressed("jump_" + str(id)):
				parent._frame()
				return states.JUMP_SQUAT
			if Input.is_action_pressed("down_" + str(id)):  # Ensure you're checking the input properly
				if parent.is_on_floor():
					if parent.is_on_platform():  # Check if you're on a platform
						parent.dropping_through_platforms = true
						parent.platform_drop_timer = .2  # Reset the drop timer
						#parent.set_collision_mask_value(3, false)
						parent.set_collision_mask_value(2, false)
						parent.GroundL.enabled = false
						parent.GroundR.enabled = false

				# Now check if we're crouching
				if Input.is_action_pressed("down_" + str(id)):
					parent._frame()
					return states.CROUCH
			if Input.get_action_strength("right_" + str(id)):
				parent.velocity.x = -parent.RUNSPEED
				parent._frame()
				parent.turn(false)
				return states.DASH  # Transition to DASH state
			elif Input.get_action_strength("left_" + str(id)):
				parent.velocity.x = parent.RUNSPEED
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
					parent.turn(false)
					return states.DASH
				else:
					parent.turn(false)
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
					parent.turn(true)
					return states.DASH
				else:
					parent.turn(true)
					parent._frame()
					return states.RUN
			else:
				if parent.frame >= parent.dash_duration - 1:
					#for state in states:
					if state != states.JUMP_SQUAT:
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
			if parent.is_on_floor():
				if parent.is_on_platform():  # Check if you're on a platform
					parent.dropping_through_platforms = true
					parent.platform_drop_timer = .2  # Reset the drop timer
					#parent.set_collision_mask_value(3, false)
					parent.set_collision_mask_value(2, false)
					parent.GroundL.enabled = false
					parent.GroundR.enabled = false

			if Input.is_action_just_pressed("jump_" + str(id)):
				parent._frame()
				return states.JUMP_SQUAT
			if Input.is_action_just_released("down_" + str(id)):
				parent._frame()
				return states.STAND
			elif parent.velocity.x > 0 and not parent.dropping_through_platforms:
				if parent.velocity.x > parent.RUNSPEED:
					parent.velocity.x += -(parent.TRACTION * 4)
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				else:
					parent.velocity.x += -(parent.TRACTION / 2)
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
			elif parent.velocity.x < 0 and not parent.dropping_through_platforms:
				if abs(parent.velocity.x) > parent.RUNSPEED:
					parent.velocity.x += (parent.TRACTION * 4)
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				else:
					parent.velocity.x += (parent.TRACTION / 2)
					parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
	
		states.RUN:
			if Input.is_action_just_pressed("jump_%d" % id) and parent.dash_jump_window > 0:
				parent.dash_jump_window = 0     # consume buffer
				# — Perform the "dash jump" even from the ground —
				parent.fastfall = false
				parent.velocity = parent.dash_momentum.normalized() * parent.AIRDASH_SPEED
				parent.velocity.y = -parent.JUMPFORCE
				return states.AIR

			# ——————————————————————
			# 4) Otherwise your normal RUN logic…
			if Input.is_action_just_pressed("jump_%d" % id):
				parent._frame()
				return states.JUMP_SQUAT
			if Input.is_action_just_pressed("down_%d" % id):
				parent._frame()
				return states.CROUCH

			# … (rest of your RUN left/right/stand code unchanged) …
			if Input.get_action_strength("left_%d" % id):
				if parent.velocity.x <= 0:
					parent.velocity.x = -parent.RUNSPEED
					parent.turn(false)
				else:
					parent._frame()
					return states.TURN

			elif Input.get_action_strength("right_%d" % id):
				if parent.velocity.x >= 0:
					parent.velocity.x = parent.RUNSPEED
					parent.turn(true)
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
					#for state in states:
					if state != states.JUMP_SQUAT:
						return states.STAND

		states.AIR:
			AIRMOVEMENT()
			
			if Input.is_action_just_pressed("jump_%d" % id) and parent.dash_jump_window == (parent.DASH_JUMP_BUFFER_FRAMES - 1):
				parent.dash_jump_window = 0   # consume buffer

				parent.fastfall = false
				if parent.is_on_wall():
					# wall‐jump + carry momentum
					var wall_dir = parent.get_wall_direction()
					var wj = Vector2(wall_dir * parent.MAXAIRSPEED,
									 -parent.DOUBLEJUMPFORCE)
					parent.velocity = wj + parent.dash_momentum
				elif parent.is_on_floor():
					# ground‐dash jump (wavedash/superjump)
					parent.velocity = parent.dash_momentum.normalized() * parent.AIRDASH_SPEED
					parent.velocity.y = -parent.JUMPFORCE
				else:
					# air double‐jump + carry momentum
					parent.velocity = parent.dash_momentum
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.airJump -= 1

				parent.dash_momentum = Vector2.ZERO
				return states.AIR
			
			var wall_jump_dir = 0
			var test_velocity = parent.velocity * delta
			var test_collision = parent.move_and_collide(test_velocity, true, true, true)

			if test_collision:
				var normal = test_collision.get_normal()
				# Check for horizontal collision
				if abs(normal.x) > 0.1:
					# Wall on the left → push right, wall on the right → push left
					wall_jump_dir = -sign(normal.x)

			if Input.is_action_just_pressed("jump_%d" % id):
				if test_collision and wall_jump_dir != 0:
					parent.fastfall = false
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.velocity.x = -wall_jump_dir * parent.MAXAIRSPEED
					# (no airJump decrement)
				elif parent.airJump > 0:
					parent.fastfall = false
					parent.velocity.x = 0
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.airJump -= 1
					if Input.is_action_pressed("left_%d" % id):
						parent.velocity.x = -parent.MAXAIRSPEED
					elif Input.is_action_pressed("right_%d" % id):
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
			if parent.ignore_knockback_frames > 0:
				parent.ignore_knockback_frames -= 1
				# zero knockback and velocity ONLY while ignoring
				parent.knockback = 0
				parent.velocity = Vector2.ZERO
				return
			if parent.knockback >= 0:
				var bounce = parent.move_and_collide(parent.velocity * delta)
				if bounce:
					# Wall collision (priority check)
					var normal = bounce.get_normal()
					if parent.is_on_wall() and bounce.get_normal() != Vector2.ZERO:
						parent.velocity.x = kbx - parent.velocity.x  # Your original x-reversal
						parent.velocity = parent.velocity.bounce(normal) * 0.8
						parent.hdecay *= -1
						parent.hitstun = round(parent.hitstun * 0.8)
					
					# Floor/ceiling collision
					elif parent.is_on_floor() and bounce.get_normal() != Vector2.ZERO:
						parent.velocity.y = kby - parent.velocity.y  # Your original y-reversal
						parent.velocity = parent.velocity.bounce(normal) * 0.8
						parent.hitstun = round(parent.hitstun * 0.8)
					
					# Generic collision fallback
					else:
						# Determine if collision is more horizontal (wall-like) or vertical (floor-like)
						if abs(normal.x) > abs(normal.y):
							# Treat as wall
							parent.velocity.x = kbx - parent.velocity.x
							parent.velocity = parent.velocity.bounce(normal) * 0.8
							parent.hdecay *= -1
							parent.hitstun = round(parent.hitstun * 0.8)
						else:
							# Treat as floor
							parent.velocity.y = kby - parent.velocity.y
							parent.velocity = parent.velocity.bounce(normal) * 0.8
							parent.hitstun = round(parent.hitstun * 0.8)
			#if parent.velocity.y < 0:
				#parent.velocity.y += parent.vdecay * 0.5 * Engine.time_scale
				#parent.velocity.y = clampf(parent.velocity.y, parent.velocity.y, 0)
			#if parent.velocity.x < 0:
				#parent.velocity.x += parent.hdecay * 0.4 * -1 * Engine.time_scale
				#parent.velocity.x = clampf(parent.velocity.x, parent.velocity.x, 0)
			#elif parent.velocity.x > 0:
				#parent.velocity.x -= parent.hdecay * 0.4 * Engine.time_scale
				#parent.velocity.x = clampf(parent.velocity.x, 0, parent.velocity.x)
				
			# 3) Smoothly decay horizontal velocity with a lerp toward 0
			# Apply vector decay instead of per-axis
			if parent.velocity.length() > 0.1:
				var decay_factor = 1.0 - delta * 3.0
				parent.velocity *= decay_factor
			
			if parent.frame >= parent.hitstun:
				if parent.knockback >= 24:
					parent.knockback = 0
					parent._frame()
					return states.AIR
				else:
					parent.knockback = 0
					parent._frame()
					return states.AIR
			elif parent.frame > 60 * 5:
				parent.knockback = 0
				return states.AIR
#
		states.LANDING:
			parent.dashMax = 1
			parent.reset_Jumps()
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
				#parent.lag_frames = 0

		states.SWING:
			if Input.is_action_just_pressed("attack_" + str(id)):
				parent.trigger_sword_attack()

			if Input.is_action_just_released("attack_" + str(id)):
				parent.release_sword_attack()

		states.AIRDASH:
			if parent.dashMax > 0:
				var direction = Vector2.ZERO
				if Input.is_action_pressed("left_" + str(id)):
					direction.x -= 1
				if Input.is_action_pressed("right_" + str(id)):
					direction.x += 1
				if Input.is_action_pressed("up_" + str(id)):
					direction.y -= 1
				if Input.is_action_pressed("down_" + str(id)):
					direction.y += 1
				
				if direction != Vector2.ZERO:
					direction = direction.normalized()
					parent.dash_momentum = direction * parent.AIRDASH_SPEED

				parent.used_dash = true
				parent.can_jump_during_dash = false  # No superdash midair

				return states.AIRDASH_TRAVEL
			else:
				return states.AIR

		states.AIRDASH_TRAVEL:
			parent.dash_timer -= 1
			parent.velocity = parent.dash_momentum
			parent.dashMax -= 1
			
			# — Detect wall collision just like in HITSTUN —
			# Detect wall nearby, not just bounce
			var wall_dir = 0
			if parent.test_move(parent.global_transform, Vector2.LEFT * 1):
				wall_dir = 1
			elif parent.test_move(parent.global_transform, Vector2.RIGHT * 1):
				wall_dir = -1
				
			# — If player hits “jump” while dashing —
			if Input.is_action_just_pressed("jump_%d" % id):
				if wall_dir != 0:
					# WALL JUMP with DASH MOMENTUM
					parent.fastfall = false
					var wj = Vector2(wall_dir * parent.MAXAIRSPEED, -parent.DOUBLEJUMPFORCE)
					parent.velocity = wj + parent.dash_momentum
					parent.dash_momentum = Vector2.ZERO
					return states.AIR

				elif parent.airJump > 0:
					# REGULAR double jump
					parent.fastfall = false
					parent.velocity.x = 0
					parent.velocity.y = -parent.DOUBLEJUMPFORCE
					parent.airJump -= 1
					parent.dash_momentum = Vector2.ZERO
					return states.AIR

			if parent.is_on_floor():
				if parent.gain_dash_on_land:
					parent.used_dash = false
				return states.STAND

			if parent.dash_timer <= 0:
				parent.dash_jump_window = parent.DASH_JUMP_BUFFER_FRAMES
				return states.AIR  # or states.RUN

		states.GROUNDDASH:
			#parent.play_animation("GROUNDDASH")
			parent.dash_timer = parent.airdash_duration  # Initialize dash timer
			#parent.dash_momentum = Vector2.ZERO

			var direction = Vector2.ZERO
			if Input.is_action_pressed("left_" + str(id)):
				direction.x -= 1
			if Input.is_action_pressed("right_" + str(id)):
				direction.x += 1
			if Input.is_action_pressed("up_" + str(id)):
				direction.y -= 1
			if Input.is_action_pressed("down_" + str(id)):
				direction.y += 1
			
			if direction == Vector2.ZERO:
				direction = Vector2.RIGHT * -parent.direction()  # default dash facing if no input

			parent.dash_momentum = direction.normalized() * parent.AIRDASH_SPEED
			parent.velocity = parent.dash_momentum

			parent.used_dash = true  # dash resource consumed
			parent.can_jump_during_dash = true  # allows for super / hyper / wavedash

			return states.GROUNDDASH_TRAVEL

		states.GROUNDDASH_TRAVEL:
			parent.dash_timer -= 1
			parent.dashMax -= 1

			# Store the original dash direction for maintaining momentum
			var original_dash_direction = sign(parent.dash_momentum.x)

			# Slowly lose dash momentum while sliding on ground (minus on par.vel.x here creates shifting effect (save for later)
			parent.velocity.x = move_toward(parent.velocity.x, 0, parent.ground_dash_friction)
			
			# If player is holding a direction, maintain momentum in that direction
			var input_direction = 0
			if Input.is_action_pressed("left_" + str(id)):
				input_direction = -1
				parent.velocity.x = move_toward(parent.velocity.x, -parent.RUNSPEED, parent.TRACTION)
			elif Input.is_action_pressed("right_" + str(id)):
				input_direction = 1
				parent.velocity.x = move_toward(parent.velocity.x, parent.RUNSPEED, parent.TRACTION)
			elif original_dash_direction != 0:  # If no input but we had a dash direction
				# Maintain some momentum in the original dash direction, but with more friction
				parent.velocity.x = move_toward(parent.velocity.x, original_dash_direction * parent.RUNSPEED * 0.5, parent.ground_dash_friction * 0.5)
			
			if Input.is_action_just_pressed("jump_" + str(id)) and parent.can_jump_during_dash:
				parent.can_jump_during_dash = false  # Only one jump
				return states.GROUNDDASH_JUMP
			
			if parent.dash_timer <= 0:
				parent.dash_jump_window = parent.DASH_JUMP_BUFFER_FRAMES
				return states.RUN if parent.is_on_floor() else states.AIR

		states.GROUNDDASH_JUMP:
			var jump_dir = parent.dash_momentum.normalized()

			if Input.is_action_pressed("left_" + str(id)) and jump_dir.x > 0:
				jump_dir.x = -jump_dir.x  # reverse super

			# Determine Jump Type
			var vertical_boost = parent.JUMPFORCE
			if jump_dir.y > 0.5:
				# Hyper or Wavedash (low jump)
				vertical_boost *= 0.6

			parent.velocity = jump_dir * parent.AIRDASH_SPEED
			parent.velocity.y = -vertical_boost  # Jump upward

			if parent.is_on_floor():
				parent.gain_dash_on_land = true  # Wavedash: regain dash if input and landing timed right

			return states.AIR

		states.DYING:
			pass

# Animations
func enter_state(new_state, _old_state):
	match new_state:
		states.STAND:
			parent.anim.frame = 0
			if parent.id == 1:
				parent.play_animation("Idle_blue")
			else:
				parent.play_animation("Idle_red")
			#parent.sprite.scale = Vector2(1.5, 1.5)
			#print("Before Idle scale:", parent.sprite.scale)
			#print("parent scale:", parent.scale)
			#print("grandparent scale:", parent.get_parent().scale)
			#print("After Idle scale:", parent.sprite.scale)
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
			parent.landingSound.play()
		states.DYING:
			parent.anim.frame = 0
			parent.sprite.scale = Vector2(0.15, 0.15)
			if parent.id == 1:
				#print("Blue is dying: " + str(parent.id))
				parent.play_animation("Death_red")
			else:
				#print("Red is dying: " + str(parent.id))
				parent.play_animation("Death_blue")
			parent.state_label.text = str("DEATH")
		states.AIRDASH:
			#parent.play_animation("AIRDASH")
			parent.state_label.text = str("AIRDASH")
			parent.dash_timer = parent.airdash_duration  # Initialize dash timer
			parent.dash_momentum = parent.velocity
			parent.dashSound.play()
		states.GROUNDDASH:
			parent.dashSound.play()

func exit_state(_old_state, _new_state):
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
	
	# Handle fastfall
	if Input.is_action_pressed("down_" + str(id)) and parent.velocity.y > -150 and not parent.fastfall: #and parent.down_buffer == 1
		parent.velocity.y = parent.MAXFALLSPEED
		#parent.fastfall = true
	
	# Ensure fastfall persists
	if parent.fastfall:
		#parent.set_collision_mask_value(3, false)
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

	if state_includes([states.AIR]):#, states.NAIR, states.BAIR, states.FAIR, states.UAIR, states.DAIR]):
		if (parent.GroundL.is_colliding() or parent.GroundR.is_colliding()) and parent.velocity.y >= 0:
			#var collider = parent.GroundL.get_collider()
			parent.frame = 0
			if parent.velocity.y > 0:
				parent.velocity.y = 0
			parent.fastfall = false
			return true
		if parent.GroundR.is_colliding() and parent.velocity.y > 0:
			#var collider = parent.GroundR.get_collider()
			parent.frame = 0
			if parent.velocity.y > 0:
				parent.velocity.y = 0
			parent.fastfall = false
			return true

func FALLING():
	#if state_includes([states.RUN, states.WALK, states.STAND, states.CROUCH, states.DASH, states.LANDING, states.TURN, states.JUMP_SQUAT, states.MOONWALK, states.ROLL_RIGHT, states.ROLL_LEFT, states.PARRY]):
	if state_includes([states.STAND, states.DASH, states.RUN, states.WALK, states.CROUCH, states.MOONWALK]):
		if not parent.GroundL.is_colliding() and not parent.GroundR.is_colliding():
			return true

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
