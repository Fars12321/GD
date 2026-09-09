class_name GDKResourceNode
extends Area3D
## ============================================================
## عقدة مورد — شجرة (خشب) أو صخرة (حجر) قابلة للجمع.
## ------------------------------------------------------------
## * جذرها Area3D + CollisionShape3D (كرة) لتحديد منطقة التفاعل.
## * المجسّم يُستورد من أصول KayKit (Assets/gltf) عبر export
##   model_scene، أو يُنشأ مكعب مؤقت عند غيابه (للاختبار).
## * الجمع: gather() يخصم كمية، يشغّل صوت Kenney المناسب
##   (impactMining للحجر / impactWood للخشب)، ويحرّك المجسّم
##   بتأثير Tween (نقرة نزول + عند النفاد انكماش ثم queue_free).
## * يبث resource_collected(type, amount) لكل مستمع (الملك).
## ============================================================

signal resource_collected(resource_type: int, amount: int)
signal depleted(node: GDKResourceNode)

## أنواع الموارد.
enum ResourceType { WOOD, STONE }

## الأصوات الافتراضية من أصول Kenney (تُستبدل من المحرر إن رغبت).
const SOUND_WOOD := preload("res://assets/kenney_impact_sounds/impactWood_medium_000.ogg")
const SOUND_STONE := preload("res://assets/kenney_impact_sounds/impactMining_000.ogg")

@export_group("Resource")
## نوع المورد (شجرة=خشب / صخرة=حجر).
@export var resource_type: ResourceType = ResourceType.WOOD
## الكمية الكلية للمورد قبل النفاد.
@export_range(5, 500, 1) var max_amount: int = 50
## الكمية المقتطعة في كل عملية جمع.
@export_range(1, 50, 1) var gather_amount: int = 10
## مهلة بين عمليتي جمع (يحدّ من السبام السريع).
@export_range(0.0, 2.0, 0.05) var gather_cooldown: float = 0.4

@export_group("Interaction")
## نصف قطر منطقة التفاعل — يدخل الملك ضمنها ليتاح الجمع.
@export_range(1.0, 8.0, 0.1) var interact_radius: float = 3.0

@export_group("Visual")
## مجسّم المورد (شجرة/صخرة KayKit .gltf/.glb). يُترك فارغاً
## فيُنشأ مكعب مؤقت بلون حسب النوع.
@export var model_scene: PackedScene
## مقياس المجسّم (الصخور صغيرة أصلاً فنكبّرها).
@export var visual_scale: float = 1.0

@export_group("Audio")
## صوت جمع الخشب (اختياري، له افتراضي).
@export var sound_wood: AudioStream = SOUND_WOOD
## صوت جمع الحجر (اختياري، له افتراضي).
@export var sound_stone: AudioStream = SOUND_STONE

## الكمية المتبقية حالياً.
var current_amount: int = 0
## هل ما يزال المورد قابلاً للجمع (يبقى صحيحاً حتى النفاد)؟
var can_gather: bool = true

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _visual: Node3D = $Visual
@onready var _sfx: AudioStreamPlayer3D = $Sfx

var _last_gather_time: float = -INF
var _anim_tween: Tween

func _ready() -> void:
	add_to_group("resource_nodes")
	current_amount = max_amount

	# كرة تفاعل خاصة بهذه العقدة (لا نشاركها بين العقد لاختلاف الأنصاف).
	var sphere := SphereShape3D.new()
	sphere.radius = interact_radius
	_collision_shape.shape = sphere

	# تحميل المجسّم (أو مكعب مؤقت).
	var model: Node3D
	if model_scene != null:
		model = model_scene.instantiate()
	else:
		model = _make_fallback_mesh()

	model.name = "Model"
	_visual.add_child(model)
	_visual.scale = Vector3.ONE * visual_scale


## ============================================================
## محاولة جمع كمية من المورد.
## تُرجع الكمية المجموعة فعلياً (0 = فشل: نفد/مهلة).
## ============================================================
func gather() -> int:
	if not can_gather or current_amount <= 0:
		return 0

	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_gather_time < gather_cooldown:
		return 0
	_last_gather_time = now

	var taken: int = mini(gather_amount, current_amount)
	current_amount -= taken

	_play_gather_sound()
	_play_hit_anim()

	resource_collected.emit(resource_type, taken)

	if current_amount <= 0:
		_deplete()

	return taken


## كمية المتبقي — للمنطق/الواجهة.
func get_remaining_amount() -> int:
	return current_amount


## هل مورد من نوع الخشب؟
func is_wood() -> bool:
	return resource_type == ResourceType.WOOD


## اسم وصفي للمورد (للواجهة).
func get_display_name() -> String:
	return "Tree" if is_wood() else "Rock"


## ============================================================
## نفاد المورد: يُمنع الجمع، يُشغَّل تأثير اختفاء (انكماش)
## ثم تُحذف العقدة من المشهد (queue_free).
## ============================================================
func _deplete() -> void:
	can_gather = false
	_collision_shape.set_deferred("disabled", true)
	depleted.emit(self)

	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	_anim_tween = create_tween()
	_anim_tween.tween_property(_visual, "position:y", -0.25, 0.12) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_anim_tween.tween_property(_visual, "scale", Vector3.ZERO, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_anim_tween.tween_callback(queue_free)


## تشغيل الصوت المناسب لنوع المورد مع تباين طبقة صوت بسيط.
func _play_gather_sound() -> void:
	var stream: AudioStream = sound_wood if is_wood() else sound_stone
	if stream == null:
		return
	_sfx.stream = stream
	_sfx.pitch_scale = randf_range(0.92, 1.12)
	_sfx.play()


## تأثير ضربة الجمع: نزول سريع ثم عودة (وكأن الفأس ضربت).
func _play_hit_anim() -> void:
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	_anim_tween = create_tween()
	_anim_tween.tween_property(_visual, "position:y", -0.3, 0.07) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(_visual, "position:y", 0.0, 0.14) \
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## مكعب مؤقت عند غياب مجسّم خارجي (اختبار بدون أصول).
func _make_fallback_mesh() -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 1.8, 0.9) if is_wood() else Vector3(1.1, 1.0, 1.1)
	var mat := StandardMaterial3D.new()
	# بني داكن للخشب / رمادي للحجر.
	mat.albedo_color = Color(0.42, 0.28, 0.16) if is_wood() else Color(0.55, 0.55, 0.58)
	mat.roughness = 0.95
	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.material_override = mat
	mi.position.y = box.size.y * 0.5  # القاعدة على الأرض
	return mi
