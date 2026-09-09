extends StaticBody3D
## سور دفاعي بسيط.
## Phase 3: منع المرور. الصحة جاهزة لمرحلة الدفاع الليلي.

@export var max_health: int = 100
var current_health: int = max_health

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		queue_free()
