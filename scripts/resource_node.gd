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
var _visual_root: Node3D

func _ready() -> void:
	_remaining = total_amount
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if model_override:
		_visual_root = model_override.instantiate()
		add_child(_visual_root)
		mesh_instance.visible = false
	else:
		_visual_root = mesh_instance
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

func get_resource_name() -> String:
	return "خشب" if resource_type == ResourceType.WOOD else "حجر"

func get_remaining_amount() -> int:
	return _remaining

func _play_gather_sound() -> void:
	if gather_sound.stream:
		gather_sound.play()

func _play_shake_effect() -> void:
	if _visual_root == null:
		return
	var original_scale: Vector3 = _visual_root.scale
	var tween := create_tween()
	tween.tween_property(_visual_root, "scale", original_scale * 1.08, 0.06)
	tween.tween_property(_visual_root, "scale", original_scale, 0.10)

func _play_depletion_and_free() -> void:
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	for body in _bodies_in_range.duplicate():
		if is_instance_valid(body) and body.has_method("unregister_nearby_resource"):
			body.unregister_nearby_resource(self)
	_bodies_in_range.clear()
	if _visual_root:
		var tween := create_tween()
		tween.tween_property(_visual_root, "scale", Vector3.ZERO, 0.35)
		tween.tween_callback(queue_free)
	else:
		queue_free()
