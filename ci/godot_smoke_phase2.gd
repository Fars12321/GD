extends SceneTree

func _fail(message: String) -> void:
	push_error("PHASE2_SMOKE_FAIL: " + message)
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
	if not _check(player.wood_count == 0, "Phase 2 must start with zero wood"):
		return
	if not _check(player.stone_count == 0, "Phase 2 must start with zero stone"):
		return

	var tree := main.get_node("Tree_01")
	var rock := main.get_node("Rock_01")
	if not _check(tree.resource_type == 0, "Tree must be wood"):
		return
	if not _check(rock.resource_type == 1, "Rock must be stone"):
		return
	if not _check(tree.get_remaining_amount() == 5, "Tree capacity must be 5"):
		return

	player.register_nearby_resource(tree)
	player.gather_nearest()
	if not _check(player.wood_count == 1, "Gathering tree must add one wood"):
		return
	if not _check(tree.get_remaining_amount() == 4, "Tree must lose one unit"):
		return

	player.unregister_nearby_resource(tree)
	player.register_nearby_resource(rock)
	player.gather_nearest()
	if not _check(player.stone_count == 1, "Gathering rock must add one stone"):
		return
	if not _check(rock.get_remaining_amount() == 4, "Rock must lose one unit"):
		return

	print("PHASE2_SMOKE_PASS")
	quit(0)
