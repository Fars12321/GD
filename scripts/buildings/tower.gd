extends StaticBody3D
## برج دفاعي: يبحث عن أقرب عدو ويطلق مقذوفات تلقائيًا.
## يقرأ مضاعفات الجولة (ترقيات البطاقات) من roguelite_director.

@export var max_health: int = 150
@export var attack_range: float = 7.5
@export var attack_damage: int = 18
@export var attack_interval: float = 1.5
@export var projectile_speed: float = 9.0

var current_health: int = 150

var _attack_cooldown: float = 0.0
var _base_max_health: int = 150
var _director: Node = null
var _projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")

func _ready() -> void:
	add_to_group("buildings")
	_base_max_health = max_health
	_director = get_tree().get_first_node_in_group("roguelite_director")
	apply_run_stats()
	current_health = max_health

func _process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_try_attack_nearest_enemy()

func apply_run_stats() -> void:
	var stats: RunStats = _stats()
	if stats == null:
		return
	max_health = stats.scaled_wall_health(_base_max_health)
	current_health = mini(current_health, max_health)

func take_damage(amount: int) -> void:
	current_health -= maxi(0, amount)
	if current_health <= 0:
		queue_free()

func get_health_ratio() -> float:
	return float(maxi(0, current_health)) / float(maxi(1, max_health))

func _stats() -> RunStats:
	if _director == null or not is_instance_valid(_director):
		_director = get_tree().get_first_node_in_group("roguelite_director")
	if _director == null or not _director.has_method("get_run_stats"):
		return null
	return _director.get_run_stats() as RunStats

func _try_attack_nearest_enemy() -> void:
	if _attack_cooldown > 0.0:
		return
	var enemy: Node3D = _get_nearest_enemy()
	if enemy == null:
		return
	if _projectile_scene == null:
		return
	var projectile: Node3D = _projectile_scene.instantiate() as Node3D
	if projectile == null:
		return
	_attack_cooldown = _current_interval()
	get_tree().root.add_child(projectile)
	projectile.global_position = global_position + Vector3(0.0, 3.1, 0.0)
	if projectile.has_method("setup"):
		projectile.setup(enemy, _current_damage(), projectile_speed)

func _current_damage() -> int:
	var stats: RunStats = _stats()
	if stats == null:
		return attack_damage
	return stats.scaled_tower_damage(attack_damage)

func _current_interval() -> float:
	var stats: RunStats = _stats()
	if stats == null:
		return attack_interval
	return stats.scaled_tower_interval(attack_interval)

func _current_range() -> float:
	var stats: RunStats = _stats()
	if stats == null:
		return attack_range
	return stats.scaled_tower_range(attack_range)

func _get_nearest_enemy() -> Node3D:
	var nearest: Node3D = null
	var best_distance: float = _current_range() * _current_range()
	for node in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(node) or not node is Node3D:
			continue
		var enemy: Node3D = node as Node3D
		var distance: float = global_position.distance_squared_to(enemy.global_position)
		if distance <= best_distance:
			best_distance = distance
			nearest = enemy
	return nearest
