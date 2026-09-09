extends Control
## عصا تحكم افتراضية للهاتف، مع دعم الفأرة للاختبار على الكمبيوتر.

signal joystick_input(vector: Vector2)
@export var joystick_radius: float = 80.0
@export var knob_radius: float = 34.0
@export var background_color: Color = Color(1, 1, 1, 0.20)
@export var knob_color: Color = Color(1, 1, 1, 0.55)

var _touch_index: int = -1
var _center: Vector2
var _knob_position: Vector2
var _player: Node = null

func _ready() -> void:
	_center = size / 2.0
	_knob_position = _center
	set_process_input(true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	call_deferred("_connect_to_player")

func _connect_to_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		push_warning("VirtualJoystick: player group not found")
		return
	if not joystick_input.is_connected(_on_joystick_input):
		joystick_input.connect(_on_joystick_input)

func _on_joystick_input(vector: Vector2) -> void:
	if _player != null and is_instance_valid(_player) and _player.has_method("set_joystick_input"):
		_player.set_joystick_input(vector)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index == -1 and get_global_rect().has_point(event.position):
				_touch_index = event.index
				_update_knob(event.position)
		elif event.index == _touch_index:
			_touch_index = -1
			_reset()
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_knob(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _touch_index == -1 and get_global_rect().has_point(event.position):
				_touch_index = 0
				_update_knob(event.position)
		else:
			if _touch_index == 0:
				_touch_index = -1
				_reset()
	elif event is InputEventMouseMotion and _touch_index == 0:
		_update_knob(event.position)

func _update_knob(global_pos: Vector2) -> void:
	var local_pos: Vector2 = global_pos - get_global_rect().position
	var offset: Vector2 = (local_pos - _center).limit_length(joystick_radius)
	_knob_position = _center + offset
	queue_redraw()
	emit_signal("joystick_input", offset / joystick_radius)

func _reset() -> void:
	_knob_position = _center
	queue_redraw()
	emit_signal("joystick_input", Vector2.ZERO)

func _draw() -> void:
	draw_circle(_center, joystick_radius, background_color)
	draw_circle(_knob_position, knob_radius, knob_color)
