extends Node3D
## Phase 4: escalating skeleton waves during the night.

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var spawn_interval: float = 3.0
@export var base_enemies: int = 3
@export var enemies_per_day: int = 2
@export var map_radius: float = 17.0
@export var reward_wood: int = 5
@export var reward_stone: int = 5

@onready var day_night_manager: Node = get_parent().get_node_or_null("DayNightManager")
@onready var player: Node = get_tree().get_first_node_in_group("player")

var _remaining_to_spawn: int = 0
var _spawn_timer: float = 0.0
var _active_night: bool = false
var _rewarded_day: int = 1

func _ready() -> void:
	if day_night_manager:
		day_night_manager.night_started.connect(_on_night_started)
		day_night_manager.day_started.connect(_on_day_started)
		_active_night = day_night_manager.is_night
		_rewarded_day = day_night_manager.current_day

func _process(delta: float) -> void:
	if not _active_night:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _remaining_to_spawn > 0:
		_spawn_one()
		_spawn_timer = spawn_interval
	if _remaining_to_spawn <= 0 and get_tree().get_nodes_in_group("enemy").is_empty():
		if day_night_manager:
			day_night_manager.request_night_finish_when_clear()

func _on_night_started(day: int) -> void:
	_active_night = true
	_remaining_to_spawn = base_enemies + maxi(0, day - 1) * enemies_per_day
	_spawn_timer = 0.1

func _on_day_started(day: int) -> void:
	_active_night = false
	_remaining_to_spawn = 0
	_spawn_timer = 0.0
	if day <= 1 or day == _rewarded_day:
		return
	_rewarded_day = day
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_resources"):
		player.add_resources(reward_wood, reward_stone)

func _spawn_one() -> void:
	if enemy_scene == null:
		_remaining_to_spawn = 0
		return
	var enemy := enemy_scene.instantiate() as Node3D
	if enemy == null:
		_remaining_to_spawn = 0
		return
	get_parent().add_child(enemy)
	enemy.global_position = _get_spawn_position()
	_remaining_to_spawn -= 1

func _get_spawn_position() -> Vector3:
	var angle := randf_range(0.0, TAU)
	var radius := randf_range(map_radius - 2.0, map_radius)
	return Vector3(cos(angle) * radius, 0.9, sin(angle) * radius)
