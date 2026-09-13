extends Node3D
## مولّد موجات «ليلة واحدة»: أعداء متزايدون مع كل ليلة، ومكافأة موارد لكل هيكل يسقط.

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var spawn_interval: float = 2.6
@export var min_spawn_interval: float = 0.9
@export var base_enemies: int = 4
@export var enemies_per_day: int = 2
@export var max_enemies: int = 26
@export var map_radius: float = 17.0
@export var base_enemy_health: int = 60
@export var health_growth_per_day: float = 0.18
@export var base_enemy_speed: float = 2.4
@export var speed_growth_per_day: float = 0.03
@export var max_enemy_speed: float = 3.7
@export var reward_wood: int = 4
@export var reward_stone: int = 4

var enemies_killed_this_night: int = 0
var total_killed: int = 0

var _day_night: Node = null
var _player: Node = null
var _remaining_to_spawn: int = 0
var _spawn_timer: float = 0.0
var _active_night: bool = false
var _rewarded_day: int = 1

func _ready() -> void:
	add_to_group("wave_spawner")
	var parent: Node = get_parent()
	if parent != null:
		_day_night = parent.get_node_or_null("DayNightManager")
	if _day_night != null:
		if _day_night.has_signal("night_started"):
			_day_night.night_started.connect(_on_night_started)
		if _day_night.has_signal("day_started"):
			_day_night.day_started.connect(_on_day_started)
		_active_night = bool(_day_night.is_night)
		_rewarded_day = int(_day_night.current_day)

func _process(delta: float) -> void:
	if not _active_night:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _remaining_to_spawn > 0:
		_spawn_one()
		_spawn_timer = _current_spawn_interval()
	if _remaining_to_spawn <= 0 and get_tree().get_nodes_in_group("enemy").is_empty():
		if _day_night != null and _day_night.has_method("request_night_finish_when_clear"):
			_day_night.request_night_finish_when_clear()

func _current_spawn_interval() -> float:
	var day: int = _current_day()
	return maxf(min_spawn_interval, spawn_interval - 0.08 * float(maxi(0, day - 1)))

func _current_day() -> int:
	if _day_night != null:
		return int(_day_night.current_day)
	return 1

func _on_night_started(day: int) -> void:
	_active_night = true
	enemies_killed_this_night = 0
	_remaining_to_spawn = mini(max_enemies, base_enemies + maxi(0, day - 1) * enemies_per_day)
	_spawn_timer = 0.1

func _on_day_started(day: int) -> void:
	_active_night = false
	_remaining_to_spawn = 0
	_spawn_timer = 0.0
	if day <= 1 or day == _rewarded_day:
		return
	_rewarded_day = day
	_grant_dawn_reward(day)

func _grant_dawn_reward(day: int) -> void:
	_player = _resolve_player()
	if _player == null or not _player.has_method("add_resources"):
		return
	var bonus: int = _reward_bonus()
	_player.add_resources(reward_wood + bonus, reward_stone + bonus)

func _reward_bonus() -> int:
	var director: Node = get_tree().get_first_node_in_group("roguelite_director")
	if director != null and director.has_method("get_run_stats"):
		return int(director.get_run_stats().wave_reward_bonus)
	return 0

func _resolve_player() -> Node:
	if _player != null and is_instance_valid(_player):
		return _player
	return get_tree().get_first_node_in_group("player")

func _spawn_one() -> void:
	if enemy_scene == null:
		_remaining_to_spawn = 0
		return
	var enemy: Node3D = enemy_scene.instantiate() as Node3D
	if enemy == null:
		_remaining_to_spawn = 0
		return
	var parent: Node = get_parent()
	if parent == null:
		enemy.queue_free()
		_remaining_to_spawn = 0
		return
	parent.add_child(enemy)
	enemy.global_position = _get_spawn_position()
	_configure_enemy(enemy)
	_remaining_to_spawn -= 1

func _configure_enemy(enemy: Node3D) -> void:
	var day: int = _current_day()
	var tier: int = maxi(0, day - 1)
	if "max_health" in enemy:
		enemy.max_health = int(round(float(base_enemy_health) * (1.0 + health_growth_per_day * float(tier))))
		enemy.current_health = enemy.max_health
	if "move_speed" in enemy:
		var speed: float = base_enemy_speed * (1.0 + speed_growth_per_day * float(tier))
		var director: Node = get_tree().get_first_node_in_group("roguelite_director")
		if director != null and director.has_method("get_run_stats"):
			speed = director.get_run_stats().scaled_enemy_speed(speed)
		enemy.move_speed = minf(max_enemy_speed, speed)
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died(_enemy: Node3D) -> void:
	enemies_killed_this_night += 1
	total_killed += 1
	_player = _resolve_player()
	if _player != null and _player.has_method("add_resources"):
		_player.add_resources(1, 1)

func _get_spawn_position() -> Vector3:
	var center: Vector3 = Vector3.ZERO
	var castle: Node3D = get_tree().get_first_node_in_group("castle_core") as Node3D
	if castle != null:
		center = castle.global_position
	var angle: float = randf_range(0.0, TAU)
	var radius: float = randf_range(map_radius - 2.0, map_radius)
	return Vector3(center.x + cos(angle) * radius, 0.9, center.z + sin(angle) * radius)
