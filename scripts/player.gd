class_name Player
extends CharacterBody3D
## ============================================================
## الملك — شخصية قابلة للتحكم (CharacterBody3D).
## ------------------------------------------------------------
## المسؤوليات في Phase 1:
##  1) حركة سلسة (تسارع/تباطؤ أُسّي بدل الحركة اللحظية).
##  2) دوران تلقائي سلس لمواجهة اتجاه الحركة.
##  3) واجهة set_move_direction() يستدعيها المشرف (main.gd)
##     بالقيمة الاتجاهية المحسوبة من الكاميرا وعصا التحكم.
##
## ملاحظة: مجسّمات KayKit (glTF) تتجه نحو +Z، لذلك يُحسب
## الدوران على أساس atan2(dir.x, dir.z) لمواءمة مقدّم الشخصية.
## ============================================================

signal direction_changed(dir_3d: Vector3)
signal idle_changed(is_idle: bool)

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

@export_group("References")
## المسار إلى جذر المجسّم المرئي (يُدار بدلاً من الجسم فيزيائياً).
@export var visual_root_path: NodePath = ^"Visual"

var _visual_root: Node3D
var _move_dir: Vector3 = Vector3.ZERO
var _target_yaw: float = 0.0
var _is_idle: bool = true

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


## يساعد على قراءة اتجاه الحركة الحالي (للمراحل القادمة/الاختبار).
func get_move_direction() -> Vector3:
	return _move_dir
