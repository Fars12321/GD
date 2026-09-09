extends CharacterBody3D
## Phase 4 skeleton enemy: target buildings first, otherwise the king.

@export var max_health: int = 60
@export var move_speed: float = 2.4
@export var acceleration: float = 8.0
@export var attack_range: float = 1.55
@export var attack_damage: int = 12
@export var attack_interval: float = 1.25
@export var target_refresh_interval: float = 0.35

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var body_mesh: MeshInstance3D = $Body
@onready var head_mesh: MeshInstance3D = $Head

var current_health: int = max_health
var target: Node3D = null
var _attack_cooldown: float = 0.0
var _target_refresh: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	current_health = max_health
	navigation_agent.path_desired_distance = 0.8
	navigation_agent.target_desired_distance = attack_range * 0.85
	navigation_agent.radius = 0.45
	navigation_agent.avoidance_enabled = true
	navigation_agent.neighbor_distance = 2.5
	navigation_agent.max_neighbors = 8
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_target_refresh -= delta
	if _target_refresh <= 0.0 or not is_instance_valid(target):
		_target_refresh = target_refresh_interval
		target = _choose_target()
	if target == null:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		move_and_slide()
		return
	var distance := global_position.distance_to(target.global_position)
	if distance <= attack_range:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		_attack_target()
	else:
		navigation_agent.target_position = target.global_position
		var next_position := navigation_agent.get_next_path_position()
		if next_position == Vector3.ZERO or not navigation_agent.is_navigation_finished():
			var direction := global_position.direction_to(next_position if next_position != Vector3.ZERO else target.global_position)
			direction.y = 0.0
			if direction.length() > 0.05:
				direction = direction.normalized()
				var desired := direction * move_speed
				velocity.x = move_toward(velocity.x, desired.x, acceleration * delta)
				velocity.z = move_toward(velocity.z, desired.z, acceleration * delta)
				look_at(global_position + Vector3(direction.x, 0.0, direction.z), Vector3.UP)
		move_and_slide()
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0

func _choose_target() -> Node3D:
	var candidates: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group("buildings"):
		if is_instance_valid(node) and node is Node3D and node.has_method("take_damage"):
			candidates.append(node)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		candidates.append(player)
	var best: Node3D = null
	var best_distance := INF
	for candidate in candidates:
		var d := global_position.distance_squared_to(candidate.global_position)
		if d < best_distance:
			best_distance = d
			best = candidate
	return best

func _attack_target() -> void:
	if _attack_cooldown > 0.0 or not is_instance_valid(target):
		return
	_attack_cooldown = attack_interval
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)

func take_damage(amount: int) -> void:
	current_health -= maxi(0, amount)
	_flash_damage()
	if current_health <= 0:
		die()

func die() -> void:
	remove_from_group("enemy")
	queue_free()

func _flash_damage() -> void:
	if body_mesh == null:
		return
	var mat := body_mesh.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		body_mesh.material_override = mat
	mat.albedo_color = Color(1.0, 0.28, 0.22, 1.0)
	var timer := get_tree().create_timer(0.08)
	timer.timeout.connect(_restore_color.bind(mat))

func _restore_color(mat: StandardMaterial3D) -> void:
	if is_instance_valid(mat):
		mat.albedo_color = Color(0.78, 0.80, 0.84, 1.0)
