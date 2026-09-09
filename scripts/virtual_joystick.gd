class_name GDKJoystick
extends Control
## ============================================================
## عصا تحكم افتراضية (Virtual Joystick) لمس الشاشة — للهواتف.
## ------------------------------------------------------------
## * تُرسَم بالكامل برمجياً عبر _draw() (بدون صور خارجية).
## * تدعم اللمس المتعدد: الإصبع الأول الذي يلمس الشاشة يمسك العصا
##   (اللمس الثاني محجوز مستقبلاً لتدوير الكاميرا مثلاً).
## * عند الاختبار على الحاسوب: تفعيل إعداد
##   emulate_touch_from_mouse يحوّل الفأرة إلى أحداث لمس، كما
##   تدعم الكود أحداث الفأرة مباشرة كخطة بديلة.
## * الناتج: متجه داخل دائرة الوحدة — x موجب لليمين،
##   y موجب للأسفل (نفس اتجاه إحداثيات الشاشة) — بعد نطاق ميت
##   (Dead Zone) يمنع الانجراف غير المقصود.
## ============================================================

signal vector_changed(output: Vector2)
signal activated
signal deactivated

@export_group("Appearance")
## نصف قطر قاعدة العصا (بكسل).
@export var radius: float = 80.0
## لون القاعدة.
@export var base_color: Color = Color(1, 1, 1, 0.18)
## لون إطار القاعدة.
@export var ring_color: Color = Color(1, 1, 1, 0.45)
## لون المقبض (القرص المتحرك).
@export var knob_color: Color = Color(1, 1, 1, 0.55)
## لون المقبض أثناء السحب.
@export var knob_active_color: Color = Color(0.95, 0.85, 0.45, 0.75)
## سُمك الإطار.
@export var ring_width: float = 5.0

## مجموعة عناصر الواجهة التي "تحتجز" اللمس (أزرار...) — لا تبدأ
## العصا فوقها حتى لا تتعارض اللمستان (زر الجمع + عصا الحركة).
const BLOCKER_GROUP := &"ui_blockers"

@export_group("Behavior")
## النطاق الميت: أقل من هذه النسبة تُعتبر قيمة الصفر.
@export_range(0.0, 0.5, 0.01) var deadzone: float = 0.12
## وضعية العصا: إذا كانت Dynamic تتكوّن مكان لمسة الإصبع مباشرة،
## وإن كانت false تبقى مثبتة أسفل يسار الشاشة.
@export var dynamic: bool = true
## نقطة الارتكاز الثابتة (نسبة من حجم الشاشة) عندما dynamic = false.
@export var fixed_anchor_ratio: Vector2 = Vector2(0.18, 0.78)

var output: Vector2 = Vector2.ZERO:
	set(value):
		if not value.is_equal_approx(output):
			output = value
			vector_changed.emit(output)

var is_active: bool = false

var _touch_index: int = -1
var _using_touch: bool = false
var _base_global: Vector2 = Vector2.ZERO
var _knob_global: Vector2 = Vector2.ZERO
var _dragging: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	resized.connect(queue_redraw)
	queue_redraw()


## ============================================================
## معالجة أحداث اللمس (و/أو الفأرة في الاختبار المكتبي).
## ============================================================
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	# دعم الفأرة مباشرةً (في حال تعطّل محاكاة اللمس).
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_mouse(event)
	elif event is InputEventMouseMotion and _dragging and not _using_touch:
		_update_knob(event.position)


## ----- أحداث اللمس الحقيقية أو المُحاكاة من الفأرة -----
func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# الإصبع الأول فقط يمسك العصا.
		if is_active:
			return
		# لا نبدأ عصا فوق زر/عنصر واجهة يلتقط اللمسة (مثل زر الجمع).
		if _is_pointer_over_blocker(event.position):
			return
		_start(event.position, event.index)
	else:
		if is_active and event.index == _touch_index:
			_release()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if is_active and event.index == _touch_index:
		_update_knob(event.position)


## ----- أحداث الفأرة (اختبار مكتبي عندما لا تصل أحداث لمس) -----
func _handle_mouse(event: InputEventMouseButton) -> void:
	if event.pressed:
		if is_active:
			return
		if _is_pointer_over_blocker(event.position):
			return
		_using_touch = false
		_start(event.position, -1)
	else:
		if is_active and not _using_touch:
			_release()


## هل النقطة فوق أي عنصر واجهة مسجّل في مجموعة "ui_blockers"؟
func _is_pointer_over_blocker(pos_global: Vector2) -> bool:
	for blocker in get_tree().get_nodes_in_group(BLOCKER_GROUP):
		var control := blocker as Control
		if control != null and control.is_visible_in_tree():
			if control.get_global_rect().has_point(pos_global):
				return true
	return false


func _start(pos_global: Vector2, index: int) -> void:
	_touch_index = index
	# على الهاتف: لمس حقيقي. على الحاسوب: أحداث مُحاكاة من الفأرة،
	# لذا نتعامل معها كفأرة لنستقبل تحديثات السحب (MouseMotion).
	_using_touch = OS.has_feature("touch")
	is_active = true

	# Dynamic: نقطة الارتكاز = موضع اللمسة. ثابتة: نسبة محددة من الشاشة.
	if dynamic:
		_base_global = pos_global
	else:
		_base_global = Vector2(
			size.x * fixed_anchor_ratio.x,
			size.y * fixed_anchor_ratio.y
		) + global_position

	_knob_global = _base_global
	output = Vector2.ZERO
	activated.emit()
	queue_redraw()


func _update_knob(pos_global: Vector2) -> void:
	var delta := pos_global - _base_global
	var clamped: Vector2 = delta.limit_length(radius)
	_knob_global = _base_global + clamped

	# قيمة معيارية (0..1) مع النطاق الميت.
	var raw := delta / radius
	var len_sq := raw.length_squared()
	if len_sq <= deadzone * deadzone:
		output = Vector2.ZERO
	else:
		output = raw.limit_length(1.0)
	queue_redraw()


func _release() -> void:
	_touch_index = -1
	is_active = false
	output = Vector2.ZERO
	deactivated.emit()
	queue_redraw()


## ============================================================
## الرسم البرمجي للعصا.
## ============================================================
func _draw() -> void:
	if _base_global == Vector2.ZERO and not is_active:
		# عند الوضع الثابت نعرض قاعدة خافتة لتلميح مكانها.
		if not dynamic:
			var hint := Vector2(
				size.x * fixed_anchor_ratio.x,
				size.y * fixed_anchor_ratio.y
			)
			_draw_joystick(hint, hint, false)
		return

	var base_local := to_local(_base_global)
	var knob_local := to_local(_knob_global) if is_active else base_local
	_draw_joystick(base_local, knob_local, is_active)


func _draw_joystick(base_local: Vector2, knob_local: Vector2, dragging: bool) -> void:
	# القاعدة الممتلئة شبه الشفافة + الإطار.
	draw_circle(base_local, radius, base_color)
	draw_arc(base_local, radius, 0.0, TAU, 48, ring_color, ring_width, true)
	# المقبض.
	var knob_rad: float = radius * 0.42
	draw_circle(knob_local, knob_rad, knob_active_color if dragging else knob_color)
	draw_arc(knob_local, knob_rad, 0.0, TAU, 32, Color(1, 1, 1, 0.5), 2.0, true)
