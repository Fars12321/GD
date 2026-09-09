extends Node
## يضيف نظام قلب القلعة إلى المشهد الحالي دون كسر تصميم Phase 3/4.

@export var max_health: int = 500
var current_health: int = 500
signal health_changed(current: int, maximum: int)
signal defeated()

func _ready() -> void:
	var castle := get_parent() as Node3D
	if castle == null:
		return
	castle.add_to_group("buildings")
	castle.add_to_group("castle_core")
	current_health = max_health
	health_changed.emit(current_health, max_health)
	var obstacle := NavigationObstacle3D.new()
	obstacle.radius = 2.6
	obstacle.height = 5.8
	obstacle.avoidance_enabled = true
	castle.add_child(obstacle)
	var body := castle as StaticBody3D
	if body == null:
		# Existing scene uses Node3D; the gameplay controller still supplies damage state.
		return

func take_damage(amount: int) -> void:
	current_health = maxi(0, current_health - maxi(0, amount))
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		defeated.emit()

func repair(amount: int) -> void:
	current_health = mini(max_health, current_health + maxi(0, amount))
	health_changed.emit(current_health, max_health)

func get_health_ratio() -> float:
	return float(current_health) / float(maxi(1, max_health))
