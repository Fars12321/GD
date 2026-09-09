extends StaticBody3D
## برج دفاعي: يبحث عن أقرب عدو ويطلق مقذوفات تلقائيًا.

@export var max_health: int = 150
@export var attack_range: float = 7.5
@export var attack_damage: int = 18
@export var attack_interval: float = 1.5
@export var projectile_speed: float = 9.0

var current_health: int = max_health
var _attack_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("buildings")
	current_health = max_health

func _process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_try_attack_nearest_enemy()

func take_damage(amount: int) -> void:
	current_health -= maxi(0, amount)
	if current_health <= 0:
		queue_free()

func _try_attack_nearest_enemy() -> void:
	if _attack_cooldown > 0.0:
		return
	var enemy := _get_nearest_enemy()
	if enemy == null:
		return
	_attack_cooldown = attack_interval
	var projectile_scene := preload("res://scenes/projectile.tscn") as PackedScene
	var projectile := projectile_scene.instantiate() as Node3D
	if projectile == null:
		return
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + Vector3(0.0, 3.1, 0.0)
	if projectile.has_method("setup"):
		projectile.setup(enemy, attack_damage, projectile_speed)

func _get_nearest_enemy() -> Node3D:
	var nearest: Node3D = null
	var best_distance := attack_range * attack_range
	for node in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(node) or not node is Node3D:
			continue
		var enemy := node as Node3D
		var d := global_position.distance_squared_to(enemy.global_position)
		if d <= best_distance:
			best_distance = d
			nearest = enemy
	return nearest
