extends SceneTree

func _init() -> void:
	assert(ProjectSettings.get_setting("application/config/name", "") == "Village Defense")
	assert(ProjectSettings.get_setting("application/run/main_scene", "") == "res://scenes/Main.tscn")
	for script_path in [
		"res://scripts/main.gd",
		"res://scripts/player.gd",
		"res://scripts/camera_rig.gd",
		"res://scripts/building_manager.gd",
		"res://scripts/resource_node.gd",
		"res://scripts/ui.gd",
		"res://scripts/virtual_joystick.gd",
		"res://scripts/buildings/wall.gd",
		"res://scripts/buildings/tower.gd",
	]:
		assert(load(script_path) != null, "Could not load " + script_path)
	var main_scene: PackedScene = load("res://scenes/Main.tscn") as PackedScene
	assert(main_scene != null, "Could not load Main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	assert(main.get_node_or_null("Player") != null, "Player missing")
	assert(main.get_node_or_null("BuildingManager") != null, "BuildingManager missing")
	print("GODOT_SMOKE_PASS")
	quit(0)
