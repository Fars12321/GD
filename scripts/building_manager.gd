extends Node3D
## مدير نظام البناء للمرحلة 3: شبكة، معاينة شبحية، فحص موارد وتصادم، وتأكيد/إلغاء.

signal placement_started(building_id: String)
signal placement_ended()
signal placement_validity_changed(is_valid: bool)

const BUILDINGS_LAYER_MASK: int = 4
@export var grid_size: float = 2.0
var building_defs: Dictionary = {}
var is_placing: bool = false
var current_id: String = ""
var current_def: Dictionary = {}
var ghost: Node3D = null
var ghost_valid: bool = false
var snapped_position: Vector3 = Vector3.ZERO
@onready var buildings_container: Node3D = $BuildingsContainer

func _ready() -> void:
	building_defs = {
		"wall": {"display_name": "سور", "scene": preload("res://scenes/buildings/Wall.tscn"), "wood": 2, "stone": 1},
		"tower": {"display_name": "برج", "scene": preload("res://scenes/buildings/Tower.tscn"), "wood": 3, "stone": 6},
	}
	add_to_group("building_manager")

func _unhandled_input(event: InputEvent) -> void:
	if not is_placing or ghost == null:
		return
	var screen_pos: Vector2
	if event is InputEventScreenTouch:
		if not event.pressed:
			return
		screen_pos = event.position
	elif event is InputEventScreenDrag:
		screen_pos = event.position
	elif event is InputEventMouseMotion:
		screen_pos = event.position
	else:
		return
	_move_ghost_to_screen_position(screen_pos)

func _move_ghost_to_screen_position(screen_pos: Vector2) -> void:
	var ground_point: Variant = _screen_to_ground(screen_pos)
	if ground_point == null:
		return
	snapped_position = Vector3(round(ground_point.x / grid_size) * grid_size, 0.0, round(ground_point.z / grid_size) * grid_size)
	ghost.position = snapped_position
	_update_validity()

func _set_initial_ghost_position() -> void:
	var player: Node3D = get_tree().get_first_node_in_group("player")
	var base_position: Vector3 = player.global_position if player else Vector3.ZERO
	var offset_position: Vector3 = base_position + Vector3(grid_size, 0.0, 0.0)
	snapped_position = Vector3(round(offset_position.x / grid_size) * grid_size, 0.0, round(offset_position.z / grid_size) * grid_size)
	ghost.position = snapped_position
	_update_validity()

func get_cost(building_id: String) -> Dictionary:
	if not building_defs.has(building_id):
		return {"wood": 0, "stone": 0}
	var definition: Dictionary = building_defs[building_id]
	return {"wood": int(definition.get("wood", 0)), "stone": int(definition.get("stone", 0))}

func start_placement(building_id: String) -> void:
	if not building_defs.has(building_id):
		push_warning("BuildingManager: نوع مبنى غير معروف: %s" % building_id)
		return
	cancel_placement()
	current_id = building_id
	current_def = building_defs[building_id]
	is_placing = true
	_create_ghost()
	_set_initial_ghost_position()
	placement_started.emit(building_id)

func confirm_placement() -> void:
	if not is_placing or not ghost_valid:
		return
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("spend_resources"):
		return
	if not player.spend_resources(int(current_def.get("wood", 0)), int(current_def.get("stone", 0))):
		return
	var scene_resource: PackedScene = current_def.get("scene") as PackedScene
	if scene_resource == null:
		return
	var building: Node3D = scene_resource.instantiate()
	buildings_container.add_child(building)
	building.position = snapped_position
	_play_build_sound()
	_end_placement()

func cancel_placement() -> void:
	_end_placement()

func _create_ghost() -> void:
	var scene_resource: PackedScene = current_def.get("scene") as PackedScene
	if scene_resource == null:
		return
	ghost = scene_resource.instantiate()
	add_child(ghost)
	_disable_collisions_recursive(ghost)
	_make_transparent_recursive(ghost, Color(0, 1, 0, 0.5))

func _disable_collisions_recursive(node: Node) -> void:
	if node is CollisionShape3D:
		node.disabled = true
	if node is CollisionObject3D:
		node.collision_layer = 0
		node.collision_mask = 0
	for child in node.get_children():
		_disable_collisions_recursive(child)

func _make_transparent_recursive(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = color
		node.material_override = mat
	for child in node.get_children():
		_make_transparent_recursive(child, color)

func _set_ghost_color(color: Color) -> void:
	if ghost:
		_apply_color_recursive(ghost, color)

func _apply_color_recursive(node: Node, color: Color) -> void:
	if node is MeshInstance3D and node.material_override:
		node.material_override.albedo_color = color
	for child in node.get_children():
		_apply_color_recursive(child, color)

func _screen_to_ground(screen_pos: Vector2):
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return null
	var ray_origin: Vector3 = cam.project_ray_origin(screen_pos)
	var ray_dir: Vector3 = cam.project_ray_normal(screen_pos)
	if absf(ray_dir.y) < 0.0001:
		return null
	var t: float = -ray_origin.y / ray_dir.y
	if t < 0.0:
		return null
	return ray_origin + ray_dir * t

func _update_validity() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	var has_enough_resources: bool = player != null and player.wood_count >= int(current_def.get("wood", 0)) and player.stone_count >= int(current_def.get("stone", 0))
	var overlapping: bool = _check_overlap(snapped_position)
	var new_valid: bool = has_enough_resources and not overlapping
	if new_valid != ghost_valid:
		ghost_valid = new_valid
		placement_validity_changed.emit(ghost_valid)
	_set_ghost_color(Color(0, 1, 0, 0.5) if ghost_valid else Color(1, 0, 0, 0.5))

func _check_overlap(pos: Vector3) -> bool:
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(grid_size * 0.9, 3.0, grid_size * 0.9)
	query.shape = shape
	query.transform = Transform3D(Basis(), pos + Vector3(0, 1.55, 0))
	query.collision_mask = BUILDINGS_LAYER_MASK
	var result: Array[Dictionary] = space_state.intersect_shape(query, 4)
	return result.size() > 0

func _play_build_sound() -> void:
	var sound_player := AudioStreamPlayer.new()
	add_child(sound_player)
	sound_player.stream = preload("res://assets/audio/ui/switch1.ogg")
	sound_player.finished.connect(sound_player.queue_free)
	sound_player.play()

func _end_placement() -> void:
	if ghost:
		ghost.queue_free()
		ghost = null
	is_placing = false
	current_id = ""
	current_def = {}
	ghost_valid = false
	placement_ended.emit()
