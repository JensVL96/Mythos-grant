extends Camera2D

@onready var player1 = get_parent().get_node("PROF")
@onready var player2 = get_parent().get_node("PROF2")

# Configuration
@export var base_position: Vector2 = Vector2(42, 25)  # Your stage center offset
@export var base_zoom: Vector2 = Vector2.ONE
@export var max_zoom_out: float = 1.5
@export var edge_threshold: float = 0.6
@export var tracking_speed: float = 3.0

var default_midpoint: Vector2
var is_tracking: bool = false

func _ready():
	default_midpoint = (player1.position + player2.position) / 2
	position = default_midpoint + base_position
	zoom = base_zoom

func _process(delta):
	var viewport = get_viewport_rect().size
	var screen_center = get_viewport_transform().origin + viewport/2
	
	# Convert player positions to screen space
	var p1_screen = (player1.position - position) * zoom.x + screen_center
	var p2_screen = (player2.position - position) * zoom.x + screen_center
	
	# Check if any player exceeds threshold
	var threshold_pixels = viewport.x * edge_threshold
	var p1_at_edge = abs(p1_screen.x - screen_center.x) > threshold_pixels
	var p2_at_edge = abs(p2_screen.x - screen_center.x) > threshold_pixels
	
	# State management
	if p1_at_edge or p2_at_edge:
		is_tracking = true
	elif not p1_at_edge and not p2_at_edge:
		is_tracking = false
	
	# Position logic
	if is_tracking:
		# Dynamic tracking - follow midpoint
		var current_midpoint = (player1.position + player2.position) / 2
		position = position.lerp(current_midpoint + base_position, tracking_speed * delta)
		
		# Calculate required zoom
		var required_zoom = max(
			abs(p1_screen.x - screen_center.x) / threshold_pixels,
			abs(p2_screen.x - screen_center.x) / threshold_pixels
		)
		required_zoom = clamp(required_zoom, 1.0, max_zoom_out)
		zoom = Vector2(required_zoom, required_zoom)
	else:
		# Return to default position
		position = default_midpoint + base_position
		zoom = base_zoom

func shake(duration := 0.2, intensity := 5) -> void:
	var timer := 0.0
	while timer < duration:
		position = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		await get_tree().create_timer(0.01).timeout
		timer += 0.01
	position = Vector2.ZERO
