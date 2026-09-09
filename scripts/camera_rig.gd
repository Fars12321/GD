class_name CameraRig
extends Node3D
## ============================================================
## ذراع الكاميرا — منظور علوي مائل يتبع الملك بسلاسة (Lerp).
## ------------------------------------------------------------
## الفكرة:
##   * CameraRig عقدة مستقلة عن الملك (وليست ابنة له) لكي نتمكن
##     من "تأخير" تتبعها قليلاً عبر Lerp أُسّي فيعطي إحساساً ناعماً.
##   * الكاميرا ابنة الذراع وتُنظر دائماً نحو مركز الهدف عبر
##     look_at_from_position() كل إطار.
##   * تُستعمل الكاميرا نفسها كمصدر اتجاه لتحويل مدخلات عصا التحكم
##     من فضاء الشاشة إلى فضاء العالم (طريقة get_planar_dir).
## ============================================================

@export_group("Follow")
## مسار عقدة الهدف (الملك).
@export var target_path: NodePath
## سرعة التتبع: أكبر = الكاميرا ألصق بالملك.
@export var follow_speed: float = 7.0

@export_group("View")
## ارتفاع الكاميرا عن الهدف.
@export var camera_height: float = 10.5
## المسافة الأفقية للخلف عن الهدف (بعد دوران الذراع).
@export var camera_distance: float = 7.5
## نقطة النظر: إزاحة رأسية عن موضع الهدف.
@export var look_height: float = 1.0
## يلفّ الذراع أفقياً (45° يعطي إحساس المنظور المائل Diablo-like).
@export_range(-180.0, 180.0) var rig_yaw_deg: float = 45.0

var target: Node3D

@onready var _camera: Camera3D = $Camera3D

func _ready() -> void:
	if target_path != NodePath(""):
		var found := get_node_or_null(target_path)
		target = found as Node3D

	# ضبط زاوية الذراع الأفقية (ميل المنظور الجمالي).
	rotation.y = deg_to_rad(rig_yaw_deg)
	set_process(target != null)


func _process(delta: float) -> void:
	if target == null:
		return

	# --- 1) تتبع سلس: Lerp أُسّي مستقل عن معدل الإطارات. ---
	var desired: Vector3 = target.global_position
	var weight: float = 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired, weight)

	# --- 2) وضع الكاميرا: إزاحة ثابتة تُدار مع ياو الذراع. ---
	# الإزاحة محلية (0, ارتفاع, مسافة) وتُدار حول المحور Y بدوران الذراع،
	# فتتوزع بين +X و +Z لتعطي زاوية ثلاثية الأبعاد (three-quarter view).
	var local_offset := Vector3(0.0, camera_height, camera_distance)
	var world_offset: Vector3 = global_transform.basis * local_offset
	_camera.global_position = global_position + world_offset

	# --- 3) توجيه النظر نحو نقطة أعلى مركز الهدف قليلاً. ---
	var look_point: Vector3 = global_position + Vector3.UP * look_height
	_camera.look_at_from_position(_camera.global_position, look_point, Vector3.UP)


## ============================================================
## تحويل مدخلات الشاشة (عصا التحكم/الأسهم) إلى اتجاه عالمي.
## ------------------------------------------------------------
## axis.x : موجب = يمين الشاشة   |  axis.y : موجب = أسفل الشاشة
## الناتج: اتجاه معياري على المستوى XZ (أو صفر إن لم يوجد مدخل).
## ============================================================
func world_dir_from_axis(axis: Vector2) -> Vector3:
	if axis.length_squared() < 0.0001:
		return Vector3.ZERO

	var planar_right: Vector3 = global_transform.basis.x
	planar_right.y = 0.0
	planar_right = planar_right.normalized()

	# "الأمام على الشاشة" = بعيداً عن الكاميرا = سالب المحور Z الأفقي.
	var planar_forward: Vector3 = -global_transform.basis.z
	planar_forward.y = 0.0
	planar_forward = planar_forward.normalized()

	# axis.y موجب للأسفل، لذا نضرب في -1 ليتحرك للأمام عند السحب لأعلى.
	var dir := planar_right * axis.x + planar_forward * (-axis.y)
	return dir.normalized() if dir.length_squared() > 0.0001 else Vector3.ZERO
