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

func _ready():
	sword.show()
	last_mouse_pos = get_viewport().get_mouse_position() # global_position

func _physics_process(delta: float) -> void:
	var current_mouse_pos = get_viewport().get_mouse_position() # global_position
	pivot_point = current_mouse_pos
	var pivot_velocity = (current_mouse_pos - last_mouse_pos) / delta if delta > 0 else Vector2.ZERO
	last_mouse_pos = current_mouse_pos

	# Add angular velocity from mouse movement
	var arm_vector = end_position - pivot_point
	if arm_vector.length() > 0.01:
		var perpendicular = Vector2(-arm_vector.y, arm_vector.x).normalized()
		var tangential_speed = pivot_velocity.dot(perpendicular)
		var angular_force = tangential_speed / arm_length
		angular_velocity += angular_force * input_sensitivity

	# Pendulum physics
	angular_acceleration = ((-gravity * delta) / arm_length) * sin(angle)
	angular_velocity += angular_acceleration
	angular_velocity *= damping
	angle += angular_velocity

	# Update end position and sword placement
	end_position = pivot_point + Vector2(arm_length * sin(angle), arm_length * cos(angle))
	sword.global_position = end_position

	# Rotate sword so the blade points away from pivot
	var direction = (end_position - pivot_point).normalized()
	sword.rotation = direction.angle() + PI/2


#extends Node2D
#
#@export var orbit_radius := 100.0
#@export var angular_speed := 1.0  # Radians per second
#
#@onready var sword: Sprite2D = $Sword
#var angle := 0.0
#
#func _ready():
	#sword.show()
#
#func _process(delta):
	## Increase angle to move clockwise
	#angle += angular_speed * delta
#
	## Get mouse position
	#var mouse_pos = get_viewport().get_mouse_position()
#
	## Compute orbiting position
	#var orbit_offset = Vector2(cos(angle), sin(angle)) * orbit_radius
	#sword.position = mouse_pos + orbit_offset
#
	## Tangent vector = derivative of position (rotate by 90°)
	#var tangent_direction = Vector2(-sin(angle), cos(angle)).normalized()
#
	## Angle so that the left side of the sword points to the mouse
	#sword.rotation = tangent_direction.angle()
