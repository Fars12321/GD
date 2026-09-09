extends CharacterBody3D
## Phase 2 player: movement + nearby resource detection + resource inventory.

@export var speed: float = 5.0
@export var acceleration: float = 12.0
@export var rotation_speed: float = 10.0
@export var gravity: float = 20.0
@export var starting_wood: int = 0
@export var starting_stone: int = 0

var joystick_vector: Vector2 = Vector2.ZERO
var wood_count: int = 0
var stone_count: int = 0
var nearby_resources: Array[Node] = []

@onready var mesh: Node3D = $MeshInstance3D

signal resources_changed(wood: int, stone: int)
signal gather_target_changed(target: Node)

func _ready() -> void:
	add_to_group("player")
	wood_count = starting_wood
	stone_count = starting_stone
	resources_changed.emit(wood_count, stone_count)

func _physics_process(delta: float) -> void:
	var input_vector := joystick_vector
	if input_vector.length() < 0.05:
		input_vector = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)
	input_vector = input_vector.limit_length(1.0)
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var target_velocity := direction * speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta * speed)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta * speed)
	move_and_slide()

	if direction.length() > 0.1:
		var target_angle := atan2(direction.x, direction.z)
		mesh.rotation.y = lerp_angle(mesh.rotation.y, target_angle, rotation_speed * delta)

func set_joystick_input(vector: Vector2) -> void:
	joystick_vector = vector

func register_nearby_resource(resource_node: Node) -> void:
	if resource_node in nearby_resources:
		return
	nearby_resources.append(resource_node)
	if resource_node.has_signal("resource_collected"):
		resource_node.resource_collected.connect(_on_resource_collected)
	gather_target_changed.emit(get_nearest_resource())

func unregister_nearby_resource(resource_node: Node) -> void:
	if resource_node in nearby_resources:
		nearby_resources.erase(resource_node)
	if is_instance_valid(resource_node) and resource_node.has_signal("resource_collected"):
		if resource_node.resource_collected.is_connected(_on_resource_collected):
			resource_node.resource_collected.disconnect(_on_resource_collected)
	gather_target_changed.emit(get_nearest_resource())

func get_nearest_resource() -> Node:
	var nearest: Node = null
	var min_dist := INF
	for resource_node in nearby_resources:
		if not is_instance_valid(resource_node):
			continue
		var dist := global_position.distance_to(resource_node.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = resource_node
	return nearest

func gather_nearest() -> void:
	var target := get_nearest_resource()
	if target and target.has_method("gather"):
		target.gather()

func _on_resource_collected(type: int, amount: int) -> void:
	match type:
		0:
			wood_count += amount
		1:
			stone_count += amount
	resources_changed.emit(wood_count, stone_count)
