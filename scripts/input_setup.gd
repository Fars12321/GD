extends Node
## ============================================================
## إعداد خريطة المدخلات (Input Map) برمجياً.
## ------------------------------------------------------------
## أُضيفت الإجراءات هنا في الكود بدلاً من project.godot حتى تبقى
## متوافقة مع كل إصدارات Godot 4، ولتسهيل إضافة أزرار لمس إضافية
## في المراحل القادمة. عند الحاجة لإعادة الربط من محرر Godot
## (Project Settings > Input Map) يمكن نقلها لاحقاً.
## ============================================================

const ACTIONS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
}

func _ready() -> void:
	for action: String in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		else:
			# إزالة الأحداث الافتراضية إن وُجدت لنضيف ما نريده فقط.
			for existing in InputMap.action_get_events(action):
				InputMap.action_erase_event(action, existing)

		for keycode: Key in ACTIONS[action]:
			_add_key(action, keycode)

	# لوحة المفاتيح العددية أو عصا تحكم خارجية (اختياري).
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)


func _add_key(action: String, keycode: Key) -> void:
	## أزرار لوحة المفاتيح تعمل عبر physical_keycode حتى لا تتأثر
	## بتخطيط لوحة المفاتيح (QWERTY/AZERTY...) على الأجهزة المختلفة.
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)


func _add_joy_axis(action: String, axis: JoyAxis, axis_value: float) -> void:
	## دعم عصا التحكم الفيزيائية (Gamepad) إن وُجدت أثناء الاختبار.
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)
