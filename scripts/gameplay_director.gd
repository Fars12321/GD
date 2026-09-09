extends Node3D
## Phase 4.1 polish: premium enemy visuals, adaptive difficulty and direct king combat.

@export var king_attack_damage: int = 32
@export var king_attack_range: float = 2.6
@export var king_attack_cooldown: float = 0.5
@export var base_enemy_health: int = 60
@export var base_enemy_speed: float = 2.4
@export var base_enemy_damage: int = 12

var _attack_cooldown := 0.0
var _player: Node3D = null
var _day_night: Node = null
var _ui: CanvasLayer = null
var _premium_scene: PackedScene = null

func _ready() -> void:
	add_to_group("gameplay_director")
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_day_night = get_tree().get_first_node_in_group("day_night_manager")
	_ui = get_tree().current_scene.get_node_or_null("UI") as CanvasLayer
	_premium_scene = load("res://assets/characters/Skeleton_Warrior.glb") as PackedScene
	if _day_night:
		if _day_night.has_signal("night_started"):
			_day_night.night_started.connect(_on_night_started)
		if _day_night.has_signal("day_started"):
			_day_night.day_started.connect(_on_day_started)
	call_deferred("_create_attack_button")

func _process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_update_enemies()
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D

func _on_night_started(day: int) -> void:
	_apply_day_scaling(day)

func _on_day_started(day: int) -> void:
	_apply_day_scaling(day)

func _apply_day_scaling(day: int) -> void:
	var tier := maxi(0, day - 1)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		_configure_enemy(enemy, tier)

func _update_enemies() -> void:
	var day := 1
	if _day_night != null:
		day = int(_day_night.get("current_day"))
	var tier := maxi(0, day - 1)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		_configure_enemy(enemy, tier)
		_attach_premium_visual(enemy)

func _configure_enemy(enemy: Node, tier: int) -> void:
	if bool(enemy.get_meta("phase41_scaled", false)):
		return
	if enemy.get("max_health") != null:
		enemy.set("max_health", int(round(base_enemy_health * (1.0 + tier * 0.16))))
		enemy.set("current_health", int(enemy.get("max_health")))
	if enemy.get("move_speed") != null:
		enemy.set("move_speed", minf(3.7, base_enemy_speed * (1.0 + tier * 0.028)))
	if enemy.get("attack_damage") != null:
		enemy.set("attack_damage", int(round(base_enemy_damage * (1.0 + tier * 0.10))))
	enemy.set_meta("phase41_scaled", true)

func _attach_premium_visual(enemy: Node) -> void:
	if _premium_scene == null or enemy.get_node_or_null("PremiumSkeleton") != null:
		return
	var holder := Node3D.new()
	holder.name = "PremiumSkeleton"
	enemy.add_child(holder)
	var model := _premium_scene.instantiate() as Node3D
	if model == null:
		return
	holder.add_child(model)
	model.scale = Vector3.ONE * 0.9
	model.position = Vector3(0.0, -0.78, 0.0)
	for child_name in ["Body", "Head", "EyeLeft", "EyeRight", "ArmLeft", "ArmRight"]:
		var child := enemy.get_node_or_null(child_name) as Node3D
		if child != null:
			child.visible = false

func _create_attack_button() -> void:
	if _ui == null:
		_ui = get_tree().current_scene.get_node_or_null("UI") as CanvasLayer
	if _ui == null or _ui.get_node_or_null("Phase41AttackButton") != null:
		return
	var button := Button.new()
	button.name = "Phase41AttackButton"
	button.text = "⚔ هجوم"
	button.position = Vector2(820.0, 560.0)
	button.size = Vector2(190.0, 100.0)
	button.add_theme_font_size_override("font_size", 28)
	button.pressed.connect(_on_attack_pressed)
	_ui.add_child(button)

func _on_attack_pressed() -> void:
	if _attack_cooldown > 0.0 or _player == null:
		return
	var nearest: Node3D = null
	var best_distance := king_attack_range * king_attack_range
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or not enemy is Node3D:
			continue
		var node := enemy as Node3D
		var distance := _player.global_position.distance_squared_to(node.global_position)
		if distance <= best_distance:
			best_distance = distance
			nearest = node
	if nearest != null and nearest.has_method("take_damage"):
		_attack_cooldown = king_attack_cooldown
		nearest.take_damage(king_attack_damage)
