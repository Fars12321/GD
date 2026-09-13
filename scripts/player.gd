extends CharacterBody3D
## الملك: حركة لمس/لوحة مفاتيح، جمع موارد، بناء، وهجوم قريب في الليل.

signal resources_changed(wood: int, stone: int)
signal gather_target_changed(target: Node)
signal health_changed(current: int, maximum: int)
signal player_defeated()

@export var speed: float = 5.0
@export var acceleration: float = 12.0
@export var rotation_speed: float = 10.0
@export var gravity: float = 20.0
@export var starting_wood: int = 6
@export var starting_stone: int = 8
@export var max_health: int = 100
@export var attack_damage: int = 25
@export var attack_range: float = 2.4
@export var attack_cooldown_time: float = 0.55

var joystick_vector: Vector2 = Vector2.ZERO
var wood_count: int = 0
var stone_count: int = 0
var current_health: int = 100
var nearby_resources: Array = []

var _attack_cooldown: float = 0.0
var _director: Node = null

@onready var mesh: Node3D = $MeshInstance3D

func _ready() -> void:
	add_to_group("player")
	wood_count = starting_wood
	stone_count = starting_stone
	current_health = max_health
	_director = get_tree().get_first_node_in_group("roguelite_director")

func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	var input_vector: Vector2 = joystick_vector
	if input_vector.length() < 0.05:
		input_vector = Vector2(
			Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		)
	input_vector = input_vector.limit_length(1.0)
	var direction: Vector3 = Vector3(input_vector.x, 0.0, input_vector.y)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	var effective_speed: float = _current_speed()
	var target_velocity: Vector3 = direction * effective_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta * effective_speed)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta * effective_speed)
	move_and_slide()
	if direction.length() > 0.1:
		var target_angle: float = atan2(direction.x, direction.z)
		mesh.rotation.y = lerp_angle(mesh.rotation.y, target_angle, rotation_speed * delta)

func set_joystick_input(vector: Vector2) -> void:
	joystick_vector = vector

func add_resources(wood_amount: int, stone_amount: int) -> void:
	wood_count += maxi(0, wood_amount)
	stone_count += maxi(0, stone_amount)
	resources_changed.emit(wood_count, stone_count)

func take_damage(amount: int) -> void:
	current_health = maxi(0, current_health - maxi(0, amount))
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		player_defeated.emit()

func can_attack() -> bool:
	return _attack_cooldown <= 0.0

## يهاجم أقرب عدو داخل المدى. يُستدعى من زر الهجوم في الواجهة.
func attack_nearest() -> bool:
	if _attack_cooldown > 0.0:
		return false
	var nearest: Node3D = null
	var best_distance: float = attack_range * attack_range
	for node in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(node) or not node is Node3D:
			continue
		var enemy: Node3D = node as Node3D
		var distance: float = global_position.distance_squared_to(enemy.global_position)
		if distance <= best_distance:
			best_distance = distance
			nearest = enemy
	if nearest == null:
		return false
	_attack_cooldown = attack_cooldown_time
	if nearest.has_method("take_damage"):
		nearest.take_damage(_current_attack_damage())
	return true

func get_health_ratio() -> float:
	return float(maxi(0, current_health)) / float(maxi(1, max_health))

func _current_speed() -> float:
	var stats: RunStats = _stats()
	if stats == null:
		return speed
	return stats.scaled_player_speed(speed)

func _current_attack_damage() -> int:
	var stats: RunStats = _stats()
	if stats == null:
		return attack_damage
	return stats.scaled_player_damage(attack_damage)

func _stats() -> RunStats:
	if _director == null or not is_instance_valid(_director):
		_director = get_tree().get_first_node_in_group("roguelite_director")
	if _director == null or not _director.has_method("get_run_stats"):
		return null
	return _director.get_run_stats() as RunStats

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
	var min_dist: float = INF
	for resource_node in nearby_resources:
		if not is_instance_valid(resource_node):
			continue
		var dist: float = global_position.distance_to(resource_node.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = resource_node
	return nearest

func gather_nearest() -> void:
	var target: Node = get_nearest_resource()
	if target and target.has_method("gather"):
		target.gather()

func spend_resources(wood_cost: int, stone_cost: int) -> bool:
	if wood_count < wood_cost or stone_count < stone_cost:
		return false
	wood_count -= wood_cost
	stone_count -= stone_cost
	resources_changed.emit(wood_count, stone_count)
	return true

func _on_resource_collected(type: int, amount: int) -> void:
	var bonus: int = 0
	var stats: RunStats = _stats()
	if stats != null:
		bonus = stats.gather_bonus
	match type:
		0:
			wood_count += amount + bonus
		1:
			stone_count += amount + bonus
	resources_changed.emit(wood_count, stone_count)
