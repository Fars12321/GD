extends SceneTree

func _fail(message: String) -> void:
	push_error("PHASE3_SMOKE_FAIL: " + message)
	quit(1)

func _check(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true

func _init() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if not _check(main_scene != null, "Main.tscn failed to load"):
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var player := main.get_node("Player")
	var manager := main.get_node("BuildingManager")
	if not _check(player != null and manager != null and manager.get_script() != null, "Player or BuildingManager missing"):
		return
	if not _check(is_equal_approx(manager.grid_size, 2.0), "Grid size must be 2m"):
		return
	var wall_cost: Dictionary = manager.get_cost("wall")
	var tower_cost: Dictionary = manager.get_cost("tower")
	if not _check(int(wall_cost.get("wood", -1)) == 10 and int(wall_cost.get("stone", -1)) == 0, "Wall cost must be 10 wood"):
		return
	if not _check(int(tower_cost.get("wood", -1)) == 0 and int(tower_cost.get("stone", -1)) == 10, "Tower cost must be 10 stone"):
		return

	player.wood_count = 10
	player.stone_count = 10
	manager.start_placement("wall")
	await process_frame
	if not _check(manager.is_placing and manager.ghost != null, "Wall preview must be created"):
		return
	if not _check(manager.snapped_position == manager.snapped_position.snappedf(2.0), "Wall preview must snap to 2m grid"):
		return
	if not _check(manager.ghost_valid, "Wall preview should be valid with 10 wood"):
		return
	manager.confirm_placement()
	await process_frame
	if not _check(main.get_node("BuildingManager/BuildingsContainer").get_child_count() == 1, "Wall must be placed"):
		return
	if not _check(player.wood_count == 0 and player.stone_count == 10, "Wall must spend 10 wood"):
		return

	manager.start_placement("wall")
	await process_frame
	if not _check(not manager.ghost_valid, "Wall must be invalid without enough wood"):
		return
	manager.cancel_placement()

	player.wood_count = 10
	player.stone_count = 10
	manager.start_placement("tower")
	await process_frame
	manager.snapped_position = Vector3(6.0, 0.0, 6.0)
	manager.ghost.position = manager.snapped_position
	manager._update_validity()
	if not _check(manager.ghost_valid, "Tower should be valid at a free grid cell"):
		return
	manager.confirm_placement()
	await process_frame
	if not _check(main.get_node("BuildingManager/BuildingsContainer").get_child_count() == 2, "Tower must be placed"):
		return
	if not _check(player.stone_count == 0, "Tower must spend 10 stone"):
		return

	manager.start_placement("tower")
	await process_frame
	manager.snapped_position = Vector3(6.0, 0.0, 6.0)
	manager.ghost.position = manager.snapped_position
	manager._update_validity()
	if not _check(not manager.ghost_valid, "Existing building cell must be invalid"):
		return
	manager.cancel_placement()

	print("PHASE3_SMOKE_PASS")
	quit(0)
