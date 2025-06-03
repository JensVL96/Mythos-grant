extends Node2D

var platforms_layer : TileMapLayer
var walls_layer : TileMapLayer

func _ready():
	# Reference the layers
	platforms_layer = $Platforms_0
	walls_layer = $Walls_2
	
	# Add each TileMapLayer to a specific group for identification
	platforms_layer.add_to_group("platform_layer")
	walls_layer.add_to_group("wall_layer")
