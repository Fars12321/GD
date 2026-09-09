extends SceneTree

func _init() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	assert(main_scene != null, "Main.tscn failed to load")
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var player := main.get_node("Player")
	assert(player.wood_count == 0, "Phase 2 must start with zero wood")
	assert(player.stone_count == 0, "Phase 2 must start with zero stone")

	var tree := main.get_node("Tree_01")
	var rock := main.get_node("Rock_01")
	assert(tree.resource_type == 0, "Tree must be wood")
	assert(rock.resource_type == 1, "Rock must be stone")
	assert(tree.get_remaining_amount() == 5, "Tree capacity must be 5")

	player.register_nearby_resource(tree)
	player.gather_nearest()
	assert(player.wood_count == 1, "Gathering tree must add one wood")
	assert(tree.get_remaining_amount() == 4, "Tree must lose one unit")

	player.unregister_nearby_resource(tree)
	player.register_nearby_resource(rock)
	player.gather_nearest()
	assert(player.stone_count == 1, "Gathering rock must add one stone")
	assert(rock.get_remaining_amount() == 7, "Rock must lose one unit")

	print("PHASE2_SMOKE_PASS")
	quit(0)
