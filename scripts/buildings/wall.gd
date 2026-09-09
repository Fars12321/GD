extends StaticBody3D
## سور دفاعي قابل للتدمير في Phase 4.

@export var max_health: int = 100
var current_health: int = max_health

func _ready() -> void:
	add_to_group("buildings")
	current_health = max_health

func take_damage(amount: int) -> void:
	current_health -= maxi(0, amount)
	if current_health <= 0:
		queue_free()
