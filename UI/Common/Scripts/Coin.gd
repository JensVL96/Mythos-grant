extends Area2D

signal picked_up

func _ready():
	$Coin.play("Coins")
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	print("collecting coins")
	if body.is_in_group("players"):
		emit_signal("picked_up", body)
		queue_free()
