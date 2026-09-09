extends SceneTree

func _init() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn") as PackedScene
	assert(main_scene != null, "Main.tscn could not be loaded")
	var main := main_scene.instantiate()	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame
	var image: Image = root.get_viewport().get_texture().get_image()
	image.save_png("artifacts/phase3.png")
	print("PHASE3_SCREENSHOT_PASS")
	quit(0)
