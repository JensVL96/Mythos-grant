extends Sprite2D

#func _process(delta):
	#var time_dict = OS.get_time()
	#
	#set_clock(time_dict)
	#
	
#
#@export var rotation_speed: float = 3.0
#@export var orbit_radius: float = 100.0
#var current_angle: float = 0.0
#
#var d := 0.0
#var radius := 150.0
#var speed := 6.0
#
#func _process(delta: float) -> void:
	## Get mouse position and calculate direction
	#var mouse_pos = get_global_mouse_position()
	#var direction_to_mouse = (mouse_pos - global_position).normalized()
	#
	## Update rotation angle (point outward from center)
	#current_angle += rotation_speed * delta
	#
	## Calculate orbital position (circular motion)
	#var orbit_offset = Vector2(
		#sin(current_angle) * orbit_radius,
		#cos(current_angle) * orbit_radius
	#)
	#
	## Set position and rotation
	#position = orbit_offset
	#rotation = current_angle
