extends CharacterBody3D
## عدو «ليلة واحدة»: هيكل عظمي يستهدف أقرب مبنى (أو الملك) ويهاجمه.

signal died(enemy: Node3D)

@export var max_health: int = 60
@export var move_speed: float = 2.4
@export var acceleration: float = 8.0
# المدى يجب أن يتجاوز نصف عرض القلعة (1.5) + نصف قطر كبسولة العدو (0.42) + فرق الارتفاع،
# وإلا توقف العدو عند سطح التصادم دون أن يصل إلى هدفه أبدًا.
@export var attack_range: float = 2.6
@export var attack_damage: int = 12
@export var attack_interval: float = 1.25
@export var target_refresh_interval: float = 0.35
@export var gravity: float = 20.0
@export var reward_wood: int = 1
@export var reward_stone: int = 1

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var body_mesh: MeshInstance3D = $Body

var current_health: int = 60
var target: Node3D = null

var _attack_cooldown: float = 0.0
var _target_refresh: float = 0.0
var _dead: bool = false

func _ready() -> void:
	add_to_group("enemy")
	current_health = max_health
	if navigation_agent != null:
		navigation_agent.path_desired_distance = 0.8
		navigation_agent.target_desired_distance = attack_range * 0.85
		navigation_agent.radius = 0.45

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_target_refresh -= delta
	if _target_refresh <= 0.0 or not is_instance_valid(target):
		_target_refresh = target_refresh_interval
		target = _choose_target()
	if target == null:
		_decelerate(delta)
		_apply_gravity(delta)
		move_and_slide()
		return
	var distance: float = global_position.distance_to(target.global_position)
	if distance <= attack_range:
		_decelerate(delta)
		_attack_target()
	else:
		_move_toward_target(delta)
	_apply_gravity(delta)
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

func _decelerate(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

func _move_toward_target(delta: float) -> void:
	var desired_position: Vector3 = target.global_position
	if navigation_agent != null:
		navigation_agent.target_position = target.global_position
		var next_position: Vector3 = navigation_agent.get_next_path_position()
		if next_position != Vector3.ZERO:
			desired_position = next_position
	var direction: Vector3 = global_position.direction_to(desired_position)
	direction.y = 0.0
	if direction.length() <= 0.05:
		_decelerate(delta)
		return
	direction = direction.normalized()
	var desired: Vector3 = direction * move_speed
	velocity.x = move_toward(velocity.x, desired.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired.z, acceleration * delta)
	var look_target: Vector3 = global_position + Vector3(direction.x, 0.0, direction.z)
	if look_target.distance_squared_to(global_position) > 0.0001:
		look_at(look_target, Vector3.UP)

func _choose_target() -> Node3D:
	var best: Node3D = null
	var best_distance: float = INF
	for node in get_tree().get_nodes_in_group("buildings"):
		if not is_instance_valid(node) or not node is Node3D:
			continue
		if not node.has_method("take_damage"):
			continue
		var building: Node3D = node as Node3D
		var building_distance: float = global_position.distance_squared_to(building.global_position)
		if building_distance < best_distance:
			best_distance = building_distance
			best = building
	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if player != null and player.has_method("take_damage"):
		var player_distance: float = global_position.distance_squared_to(player.global_position)
		if player_distance < best_distance:
			best = player
	return best

func _attack_target() -> void:
	if _attack_cooldown > 0.0 or not is_instance_valid(target):
		return
	_attack_cooldown = attack_interval
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)

func take_damage(amount: int) -> void:
	if _dead:
		return
	current_health -= maxi(0, amount)
	_flash_damage()
	if current_health <= 0:
		die()

func get_health_ratio() -> float:
	return float(maxi(0, current_health)) / float(maxi(1, max_health))

func die() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("enemy")
	died.emit(self)
	queue_free()

func _flash_damage() -> void:
	if body_mesh == null:
		return
	var material: StandardMaterial3D = body_mesh.material_override as StandardMaterial3D
	if material == null:
		material = StandardMaterial3D.new()
		body_mesh.material_override = material
	material.albedo_color = Color(1.0, 0.28, 0.22, 1.0)
	var timer: SceneTreeTimer = get_tree().create_timer(0.08)
	timer.timeout.connect(_restore_color.bind(material))

func _restore_color(material: StandardMaterial3D) -> void:
	if is_instance_valid(material):
		material.albedo_color = Color(0.78, 0.80, 0.84, 1.0)
