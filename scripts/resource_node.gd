extends Area3D
class_name ResourceNode
## مورد قابل الجمع: شجرة خشب أو صخرة حجر.

enum ResourceType { WOOD, STONE }
@export var resource_type: ResourceType = ResourceType.WOOD
@export var total_amount: int = 5
@export var amount_per_gather: int = 1
@export var model_override: PackedScene

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var gather_sound: AudioStreamPlayer3D = $GatherSound

signal resource_collected(type: ResourceType, amount: int)
signal depleted
var _remaining: int
var _bodies_in_range: Array = []

func _ready() -> void:
	_remaining = total_amount
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if model_override:
		var visual := model_override.instantiate()
		add_child(visual)
		mesh_instance.visible = false
	if gather_sound.stream == null:
		match resource_type:
			ResourceType.WOOD:
				gather_sound.stream = load("res://assets/audio/impact/impactWood_medium_000.ogg")
			ResourceType.STONE:
				gather_sound.stream = load("res://assets/audio/impact/impactMining_000.ogg")

func _on_body_entered(body: Node) -> void:
	if body.has_method("register_nearby_resource"):
		_bodies_in_range.append(body)
		body.register_nearby_resource(self)

func _on_body_exited(body: Node) -> void:
	if body in _bodies_in_range:
		_bodies_in_range.erase(body)
	if body.has_method("unregister_nearby_resource"):
		body.unregister_nearby_resource(self)

func gather() -> bool:
	if _remaining <= 0:
		return false
	var amount_taken: int = min(amount_per_gather, _remaining)
	_remaining -= amount_taken
	resource_collected.emit(resource_type, amount_taken)
	_play_gather_sound()
	_play_shake_effect()
	if _remaining <= 0:
		depleted.emit()
		_play_depletion_and_free()
	return true

func _play_gather_sound() -> void:
	if gather_sound.stream:
		gather_sound.play()

func _play_shake_effect() -> void:
	var original_scale: Vector3 = mesh_instance.scale
	var tween := create_tween()
	tween.tween_property(mesh_instance, "scale", original_scale * 1.15, 0.08)
	tween.tween_property(mesh_instance, "scale", original_scale, 0.08)

func _play_depletion_and_free() -> void:
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	for body in _bodies_in_range.duplicate():
		if is_instance_valid(body) and body.has_method("unregister_nearby_resource"):
			body.unregister_nearby_resource(self)
	_bodies_in_range.clear()
	var tween := create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.35)
	tween.tween_callback(queue_free)
