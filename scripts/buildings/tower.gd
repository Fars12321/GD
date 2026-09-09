extends StaticBody3D
## برج دفاعي. Phase 3: عائق ثابت؛ متغيرات الهجوم جاهزة لمرحلة 4.

@export var max_health: int = 150
@export var attack_range: float = 6.0
@export var attack_damage: int = 10
@export var attack_interval: float = 1.5

var current_health: int = max_health
var _attack_cooldown: float = 0.0

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		queue_free()

func _try_attack_nearest_enemy() -> void:
	pass
