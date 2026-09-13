extends SceneTree
## اختبار الدخان الأساسي.
## ملاحظة: assert() في Godot يطبع خطأً لكنه لا يُفشل العملية، لذا نعتمد عدّادًا صريحًا وquit(1).

var _failures: int = 0

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	printerr("FAIL: " + message)

func _finish(label: String) -> void:
	if _failures == 0:
		print(label + "_PASS")
		quit(0)
	else:
		printerr(label + "_FAIL failures=%d" % _failures)
		quit(1)

func _init() -> void:
	_check(ProjectSettings.get_setting("application/config/name", "") == "Village Defense", "application/config/name mismatch")
	_check(ProjectSettings.get_setting("application/run/main_scene", "") == "res://scenes/Main.tscn", "application/run/main_scene mismatch")
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
		"res://scripts/day_night_manager.gd",
		"res://scripts/wave_spawner.gd",
		"res://scripts/castle_core.gd",
		"res://scripts/enemy.gd",
		"res://scripts/projectile.gd",
		"res://scripts/upgrade_overlay.gd",
		"res://scripts/roguelite_director.gd",
		"res://scripts/run_stats.gd",
		"res://scripts/upgrade_deck.gd",
	]:
		var script: Script = load(script_path) as Script
		_check(script != null, "Could not load " + script_path)
	var main_scene: PackedScene = load("res://scenes/Main.tscn") as PackedScene
	if main_scene == null:
		printerr("FAIL: Main.tscn could not be loaded")
		quit(1)
		return
	var main: Node = main_scene.instantiate()
	if main == null:
		printerr("FAIL: Main.tscn could not be instantiated")
		quit(1)
		return
	root.add_child(main)
	await process_frame
	for node_name in ["Player", "BuildingManager", "RogueliteDirector", "DayNightManager", "WaveSpawner", "UpgradeOverlay", "CastleCore", "NavigationRegion3D"]:
		_check(main.get_node_or_null(node_name) != null, node_name + " missing in Main.tscn")
	_finish("GODOT_SMOKE")
