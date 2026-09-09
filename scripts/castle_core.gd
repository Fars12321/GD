extends StaticBody3D
## قلب القلعة: هدف رئيسي للهجوم، مع صحة ووميض ضرر وحالة هزيمة.

signal health_changed(current: int, maximum: int)
signal castle_defeated()

@export var max_health: int = 500
@export var damage_flash_seconds: float = 0.12

var current_health: int = 500
var _flash_timer: float = 0.0
var _base_modulate := Color.WHITE

func _ready() -> void:
	add_to_group("buildings")
	add_to_group("castle_core")
	current_health = max_health
	health_changed.emit(current_health, max_health)

func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_set_visual_flash(false)

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = maxi(0, current_health - maxi(0, amount))
	health_changed.emit(current_health, max_health)
	_flash_timer = damage_flash_seconds
	_set_visual_flash(true)
	if current_health <= 0:
		castle_defeated.emit()
		# Keep the scene alive for the defeat presentation; the main game can reset/restart.

func repair(amount: int) -> void:
	current_health = mini(max_health, current_health + maxi(0, amount))
	health_changed.emit(current_health, max_health)

func get_health_ratio() -> float:
	return float(current_health) / float(maxi(1, max_health))

func _set_visual_flash(active: bool) -> void:
	for child in get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).modulate = Color(1.0, 0.38, 0.32, 1.0) if active else _base_modulate
