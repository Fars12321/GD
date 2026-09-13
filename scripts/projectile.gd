extends Node3D
## مقذوف برج خفيف: يتجه للهدف ويطبّق الضرر عند الوصول.

@export var speed: float = 9.0
@export var damage: int = 18
@export var hit_distance: float = 0.45
@export var lifetime: float = 4.0

var target: Node3D = null

func setup(target_node: Node3D, damage_amount: int, projectile_speed: float) -> void:
	target = target_node
	damage = damage_amount
	speed = maxf(0.5, projectile_speed)

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if not is_instance_valid(target):
		queue_free()
		return
	var target_position: Vector3 = target.global_position + Vector3.UP * 0.9
	var offset: Vector3 = target_position - global_position
	var distance: float = offset.length()
	if distance <= hit_distance:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
		return
	global_position += (offset / distance) * speed * delta
	var flat_offset: Vector3 = Vector3(offset.x, 0.0, offset.z)
	if flat_offset.length_squared() > 0.0001:
		look_at(global_position + flat_offset, Vector3.UP)
