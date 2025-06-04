@tool
extends EditorScript

func _run():
	var scenes = []
	var dir = Directory.new()
	dir.open("res://")
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tscn"):
			scenes.append("res://" + file_name)
		file_name = dir.get_next()

	for scene_path in scenes:
		var scene = ResourceLoader.load(scene_path)
		if scene:
			print("Checking scene:", scene_path)
			check_node_recursive(scene, scene_path)

func check_node_recursive(node: Node, scene_path: String):
	if node is PhysicsBody2D or node is Area2D:
		var layers = node.collision_layer
		var masks = node.collision_mask
		var used_layers = get_active_layers(layers)
		var used_masks = get_active_layers(masks)
		if used_layers.any(lambda l: l > 5) or used_masks.any(lambda l: l > 5):
			print("- Node:", node.name, "in", scene_path)
			print("  → Layers:", used_layers)
			print("  → Masks:", used_masks)
	for child in node.get_children():
		if child is Node:
			check_node_recursive(child, scene_path)

func get_active_layers(bits: int) -> Array:
	var layers := []
	for i in 20:
		if bits & (1 << i):
			layers.append(i + 1)
	return layers
