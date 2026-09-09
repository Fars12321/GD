extends SceneTree

var frames := 0

func _init() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn") as PackedScene
	assert(main_scene != null, "Main.tscn could not be loaded")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	frames += 1
	if frames < 10:
		return
	var image: Image = root.get_viewport().get_texture().get_image()
	var err := image.save_png("artifacts/phase3.png")
	assert(err == OK, "Could not save screenshot")
	print("PHASE3_SCREENSHOT_PASS")
	quit(0)
