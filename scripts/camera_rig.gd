extends Camera3D
## كاميرا استراتيجية سلسة مع حدود حركة وزوم للمس/الفأرة.

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0, 12, 8)
@export var follow_speed: float = 5.0
@export var look_down_angle: float = -55.0
@export var min_height: float = 8.0
@export var max_height: float = 18.0
@export var map_limit: float = 17.5
@export var zoom_speed: float = 0.025

var target: Node3D
var _pinch_distance: float = 0.0
var _touches: Dictionary = {}

func _ready() -> void:
	if target_path != NodePath(""):
		target = get_node(target_path)
	rotation_degrees.x = look_down_angle
	set_process_input(true)

func _process(delta: float) -> void:
	if target == null:
		return
	var desired_position: Vector3 = target.global_position + offset
	desired_position.x = clampf(desired_position.x, -map_limit, map_limit)
	desired_position.z = clampf(desired_position.z, -map_limit, map_limit)
	var smoothing: float = 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired_position, smoothing)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom(-1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom(1.0)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
			_pinch_distance = 0.0
	elif event is InputEventScreenDrag:
		if _touches.has(event.index):
			_touches[event.index] = event.position
		if _touches.size() == 2:
			var points := _touches.values()
			var distance := (points[0] as Vector2).distance_to(points[1] as Vector2)
			if _pinch_distance > 0.0:
				_zoom(clampf((_pinch_distance - distance) * zoom_speed, -1.0, 1.0))
			_pinch_distance = distance

func _zoom(direction: float) -> void:
	var height := clampf(offset.y + direction * 0.9, min_height, max_height)
	var ratio := height / maxf(0.001, offset.y)
	offset.y = height
	offset.z = clampf(offset.z * ratio, 5.0, 12.0)
