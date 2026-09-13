extends StaticBody3D
## قلب القلعة: الهدف الرئيسي للأعداء. سقوطه = نهاية الجولة.

signal health_changed(current: int, maximum: int)
signal castle_defeated()

@export var max_health: int = 500
@export var pulse_seconds: float = 0.14

var current_health: int = 500
var is_defeated: bool = false

var _pulse_tweens: Array = []

func _ready() -> void:
	add_to_group("buildings")
	add_to_group("castle_core")
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
	if is_defeated:
		return
	current_health = maxi(0, current_health - maxi(0, amount))
	health_changed.emit(current_health, max_health)
	_pulse()
	if current_health <= 0:
		is_defeated = true
		castle_defeated.emit()

func repair(amount: int) -> void:
	if is_defeated:
		return
	current_health = mini(max_health, current_health + maxi(0, amount))
	health_changed.emit(current_health, max_health)

func repair_ratio(ratio: float) -> void:
	repair(int(round(float(max_health) * clampf(ratio, 0.0, 1.0))))

func set_max_health(value: int) -> void:
	max_health = maxi(1, value)
	current_health = mini(current_health, max_health)
	health_changed.emit(current_health, max_health)

func get_health_ratio() -> float:
	return float(current_health) / float(maxi(1, max_health))

func _pulse() -> void:
	for tween in _pulse_tweens:
		if is_instance_valid(tween):
			tween.kill()
	_pulse_tweens.clear()
	for child in get_children():
		if child is MeshInstance3D:
			var mesh: MeshInstance3D = child as MeshInstance3D
			var original_scale: Vector3 = mesh.scale
			var tween: Tween = create_tween()
			tween.tween_property(mesh, "scale", original_scale * 1.07, pulse_seconds * 0.4)
			tween.tween_property(mesh, "scale", original_scale, pulse_seconds * 0.6)
			_pulse_tweens.append(tween)
