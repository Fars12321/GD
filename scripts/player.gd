class_name Player
extends CharacterBody3D
## ============================================================
## الملك — شخصية قابلة للتحكم (CharacterBody3D).
## ------------------------------------------------------------
## Phase 1: حركة سلسة + دوران تلقائي نحو اتجاه الحركة.
## Phase 2: مخزن موارد (خشب/حجر) + اكتشاف موارد القرب
##          (resource_nodes) ودعم الجمع من أقرب مورد.
##
## ملاحظة: مجسّمات KayKit (glTF) تتجه نحو +Z، لذلك يُحسب
## الدوران على أساس atan2(dir.x, dir.z) لمواءمة مقدّم الشخصية.
## ============================================================

signal direction_changed(dir_3d: Vector3)
signal idle_changed(is_idle: bool)
## تتغير عدّادات الموارد (تُطلق بعد كل جمع).
signal resources_changed(wood: int, stone: int)
## أقرب مورد في متناول اليد تغيّر (يُمرَّر null عندما لا يوجد).
signal nearest_resource_changed(resource: ResourceNode)

@export_group("Movement")
## السرعة القصوى للمشي (متر/ثانية).
@export var max_speed: float = 4.5
## معدل التسارع — كلما زاد وصلت للسرعة القصوى أسرع.
@export var acceleration: float = 14.0
## معدل سلاسة الدوران (راديان/ثانية تقريباً).
@export var rotation_smoothness: float = 14.0

@export_group("Facing")
## تعويض زاوي (بالدرجات) إذا احتاج المجسّم تدويراً يدوياً
## لمحاذاة مقدّمه. القيمة 0 تكفي لشخصيات KayKit (glTF).
@export var facing_yaw_offset_deg: float = 0.0

@export_group("Resources")
## مخزن الخشب (يُضاف إليه عند الجمع).
var wood_count: int = 0
## مخزن الحجر.
var stone_count: int = 0

@export_group("References")
## المسار إلى جذر المجسّم المرئي (يُدار بدلاً من الجسم فيزيائياً).
@export var visual_root_path: NodePath = ^"Visual"

var _visual_root: Node3D
var _move_dir: Vector3 = Vector3.ZERO
var _target_yaw: float = 0.0
var _is_idle: bool = true

## الموارد المتاحة حالياً داخل نطاق التفاعل (مرتبة: الأقرب أولاً).
var _nearby_resources: Array[ResourceNode] = []
## أقرب مورد (آخر ما بُثّ للواجهة).
var _nearest_resource: ResourceNode = null
## قاموس العقد المرتبط بإشارة resource_collected (لمنع التكرار).
var _connected_resources: Dictionary = {}

func _ready() -> void:
	_visual_root = get_node_or_null(visual_root_path) as Node3D
	_target_yaw = rotation.y
	# الملك يبدأ ساكناً في واجهة الاختبار.
	set_move_direction(Vector3.ZERO)


## ============================================================
## المدخل الرئيسي: يضبط اتجاه الحركة في الفضاء العالمي (XZ).
## (يُستدعى كل إطار فيزيائي من main.gd بعد تحويل مدخلات اللاعب)
## ============================================================
func set_move_direction(dir_3d: Vector3) -> void:
	_move_dir = dir_3d

	var moving: bool = _move_dir.length_squared() > 0.0001
	if moving:
		# yaw = atan2(x, z) يوجّه محور +Z للمجسّم نحو اتجاه الحركة
		# (اصطلاح glTF) مع إضافة أي تعويض يدوي مضبوط.
		_target_yaw = atan2(_move_dir.x, _move_dir.z) \
				+ deg_to_rad(facing_yaw_offset_deg)

	if moving != _is_idle:
		_is_idle = moving
		idle_changed.emit(_is_idle)


func _physics_process(delta: float) -> void:
	var target_velocity: Vector3 = _move_dir * max_speed

	# تسارع/تباطؤ أُسّي: حركة سلسة دون "انزلاق" مفرط.
	# 1 - exp(-acceleration * delta) ≈ نسبة الاقتراب لكل إطار.
	var weight: float = 1.0 - exp(-acceleration * delta)
	velocity = velocity.lerp(target_velocity, weight)

	# تحريك الجسم ثم معالجة التصادمات (الأرض/العوائق).
	move_and_slide()

	# دوران سلس نحو زاوية الهدف (يدور من أقصر قوس).
	var rot_weight: float = 1.0 - exp(-rotation_smoothness * delta)
	rotation.y = lerp_angle(rotation.y, _target_yaw, rot_weight)

	# محاذاة ارتفاع المجسّم المرئي (يبقى ملامساً للأرض إن تغيّر السطح).
	if _visual_root != null:
		_visual_root.position.y = 0.0

	# فحص الموارد القريبة (أقربها في متناول اليد).
	_update_nearby_resources()


## ============================================================
## جمع الموارد — Phase 2
## ============================================================

## أقرب مورد داخل نطاق التفاعل (أو null إن لم يوجد).
func get_nearest_resource() -> ResourceNode:
	return _nearest_resource


## هل يوجد مورد يمكن جمعه الآن؟
func has_resource_in_range() -> bool:
	return _nearest_resource != null and _nearest_resource.can_gather


## يجمع من أقرب مورد متاح. يرجع true عند نجاح الجمع.
func gather_nearest() -> bool:
	var node := get_nearest_resource()
	if node == null or not node.can_gather:
		return false
	return node.gather() > 0


## فحص دوري للموارد داخل نطاق كل عقدة، وترتيبها من الأقرب.
func _update_nearby_resources() -> void:
	_nearby_resources.clear()

	for node in get_tree().get_nodes_in_group("resource_nodes"):
		if not is_instance_valid(node) or not node.can_gather:
			continue
		if global_position.distance_to(node.global_position) <= node.interact_radius:
			_nearby_resources.append(node)
			_ensure_resource_connection(node)

	# ترتيب تصاعدي حسب البعد عن الملك.
	_nearby_resources.sort_custom(func(a: ResourceNode, b: ResourceNode) -> bool:
		return global_position.distance_to(a.global_position) \
				< global_position.distance_to(b.global_position))

	# تنظيف اتصالات العقد المحذوفة (نفدت واختفت).
	for key in _connected_resources.keys():
		if not is_instance_valid(key):
			_connected_resources.erase(key)

	# بث تغيّر "أقرب مورد" إن تغيّر (مرة واحدة عند الدخول/الخروج).
	var new_nearest: ResourceNode = _nearby_resources[0] \
			if not _nearby_resources.is_empty() else null
	if new_nearest != _nearest_resource:
		_nearest_resource = new_nearest
		nearest_resource_changed.emit(_nearest_resource)


## ربط إشارة الجمع مرة واحدة لكل مورد يدخل النطاق.
func _ensure_resource_connection(node: ResourceNode) -> void:
	if _connected_resources.has(node):
		return
	node.resource_collected.connect(_on_resource_collected)
	_connected_resources[node] = true


## عند جمع كمية من أي مورد: إضافتها للمخزن وبثّ التغيير.
func _on_resource_collected(resource_type: int, amount: int) -> void:
	if resource_type == ResourceNode.ResourceType.WOOD:
		wood_count += amount
	else:
		stone_count += amount
	resources_changed.emit(wood_count, stone_count)


## يساعد على قراءة اتجاه الحركة الحالي (للمراحل القادمة/الاختبار).
func get_move_direction() -> Vector3:
	return _move_dir
