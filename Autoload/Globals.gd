extends Node

var round_started = false

func hitstun(mod, duration):
	Engine.time_scale = mod/100
	print(str(mod))
	await get_tree().create_timer(duration * Engine.time_scale).timeout
	Engine.time_scale = 1
