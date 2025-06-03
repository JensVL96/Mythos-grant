extends Area2D


@export_enum("Left", "Right") var ledge_side: String = "Left"
@onready var label = $"Label"
@onready var collision = $"CollisionShape2D"
var is_grabbed = false

func _on_ledge_body_exited():#body
	is_grabbed = false
	
func _ready():
	match ledge_side:
		"Left":
			label.text = "Ledge_L"
		"Right":
			label.text = "Ledge_R"
