extends Node3D
## Phase 3: grid building, touch preview, collision validation, resource spending.

signal placement_started(building_id: String)
signal placement_ended()
signal placement_validity_changed(is_valid: bool)

const BUILDINGS_LAYER_MASK: int = 4
const VALID_COLOR := Color(0.15, 1.0, 0.35, 0.52)
const INVALID_COLOR := Color(1.0, 0.16, 0.12, 0.52)

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
		"wall": {"display_name": "سور", "scene": preload("res://scenes/buildings/Wall.tscn"), "wood": 10, "stone": 0},
		"tower": {"display_name": "برج دفاعي", "scene": preload("res://scenes/buildings/Tower.tscn"), "wood": 0, "stone": 10},
	}
	add_to_group("building_manager")

func _unhandled_input(event: InputEvent) -> void:
	if not is_placing or ghost == null:
		return
	var screen_pos := Vector2.ZERO
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
	snapped_position = Vector3(ground_point).snappedf(grid_size)
	snapped_position.y = 0.0
	ghost.position = snapped_position
	_update_validity()

func _set_initial_ghost_position() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var base_position := player.global_position if player else Vector3.ZERO
	snapped_position = Vector3(base_position + Vector3(grid_size, 0.0, 0.0)).snappedf(grid_size)
	snapped_position.y = 0.0
	ghost.position = snapped_position
	_update_validity()

func get_cost(building_id: String) -> Dictionary:
	if not building_defs.has(building_id):
		return {"wood": 0, "stone": 0}
	var definition: Dictionary = building_defs[building_id]
	return {"wood": int(definition.get("wood", 0)), "stone": int(definition.get("stone", 0))}

func start_placement(building_id: String) -> void:
	if not building_defs.has(building_id):
		push_warning("BuildingManager: unknown building id: %s" % building_id)
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
	var player := get_tree().get_first_node_in_group("player") as Node
	if player == null or not player.has_method("spend_resources"):
		return
	var scene_resource := current_def.get("scene") as PackedScene
	if scene_resource == null:
		return
	var wood_cost := int(current_def.get("wood", 0))
	var stone_cost := int(current_def.get("stone", 0))
	if player.wood_count < wood_cost or player.stone_count < stone_cost:
		_update_validity()
		return
	var building := scene_resource.instantiate() as Node3D
	if building == null:
		return
	if not player.spend_resources(wood_cost, stone_cost):
		building.queue_free()
		return
	buildings_container.add_child(building)
	building.position = snapped_position
	_play_build_sound(current_id)
	_end_placement()

func cancel_placement() -> void:
	_end_placement()

func _create_ghost() -> void:
	var scene_resource := current_def.get("scene") as PackedScene
	if scene_resource == null:
		return
	ghost = scene_resource.instantiate() as Node3D
	if ghost == null:
		return
	add_child(ghost)
	_disable_collisions_recursive(ghost)
	_make_transparent_recursive(ghost, INVALID_COLOR)

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
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		node.material_override = mat
	for child in node.get_children():
		_make_transparent_recursive(child, color)

func _set_ghost_color(color: Color) -> void:
	if ghost:
		_apply_color_recursive(ghost, color)

func _apply_color_recursive(node: Node, color: Color) -> void:
	if node is MeshInstance3D and node.material_override is StandardMaterial3D:
		node.material_override.albedo_color = color
	for child in node.get_children():
		_apply_color_recursive(child, color)

func _screen_to_ground(screen_pos: Vector2) -> Variant:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return null
	var ray_origin := cam.project_ray_origin(screen_pos)
	var ray_dir := cam.project_ray_normal(screen_pos)
	if absf(ray_dir.y) < 0.0001:
		return null
	var distance := -ray_origin.y / ray_dir.y
	if distance < 0.0:
		return null
	return ray_origin + ray_dir * distance

func _update_validity() -> void:
	if not is_placing:
		return
	var player := get_tree().get_first_node_in_group("player") as Node
	var wood_cost := int(current_def.get("wood", 0))
	var stone_cost := int(current_def.get("stone", 0))
	var has_enough_resources := player != null and player.wood_count >= wood_cost and player.stone_count >= stone_cost
	var overlapping := _check_overlap(snapped_position)
	var new_valid := has_enough_resources and not overlapping
	if new_valid != ghost_valid:
		ghost_valid = new_valid
		placement_validity_changed.emit(ghost_valid)
	_set_ghost_color(VALID_COLOR if ghost_valid else INVALID_COLOR)

func _check_overlap(pos: Vector3) -> bool:
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(grid_size * 0.9, 3.0, grid_size * 0.9)
	query.shape = shape
	query.transform = Transform3D(Basis(), pos + Vector3(0.0, 1.5, 0.0))
	query.collision_mask = BUILDINGS_LAYER_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var result := space_state.intersect_shape(query, 8)
	return not result.is_empty()

func _play_build_sound(building_id: String) -> void:
	var sound_player := AudioStreamPlayer.new()
	add_child(sound_player)
	if building_id == "tower":
		sound_player.stream = preload("res://assets/audio/impact/impactMining_001.ogg")
	else:
		sound_player.stream = preload("res://assets/audio/impact/impactWood_light_000.ogg")
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
