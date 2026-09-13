extends Node
## دورة النهار/ليل لنمط «ليلة واحدة»: نهار للجمع والبناء، ليل للدفاع.
## الليل لا ينتهي إلا بعد سقوط كل الأعداء، ثم يُصدر night_cleared ليعرض المدير البطاقات.

signal day_started(day: int)
signal night_started(day: int)
signal night_cleared(day: int)
signal phase_changed(is_night: bool)
signal time_changed(seconds_left: float, total_seconds: float, is_night: bool)

@export var day_duration: float = 40.0
@export var night_duration: float = 60.0
@export var transition_seconds: float = 4.0

var current_day: int = 1
var is_night: bool = false
var awaiting_cards: bool = false
var phase_time: float = 0.0

var _night_clear_requested: bool = false
var _sun: DirectionalLight3D = null
var _world_environment: WorldEnvironment = null
var _base_sun_rotation: Vector3 = Vector3(-48.0, -28.0, 0.0)
var _base_sun_energy: float = 1.05
var _base_sun_color: Color = Color(1.0, 0.92, 0.78, 1.0)
var _day_ambient_color: Color = Color(0.70, 0.76, 0.86, 1.0)
var _night_ambient_color: Color = Color(0.13, 0.18, 0.32, 1.0)
var _day_background: Color = Color(0.075, 0.11, 0.17, 1.0)
var _night_background: Color = Color(0.008, 0.015, 0.045, 1.0)

func _ready() -> void:
	add_to_group("day_night_manager")
	var parent: Node = get_parent()
	if parent != null:
		_sun = parent.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
		_world_environment = parent.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if _sun != null:
		_base_sun_rotation = _sun.rotation_degrees
		_base_sun_energy = _sun.light_energy
		_base_sun_color = _sun.light_color
	_start_day()

func _process(delta: float) -> void:
	if awaiting_cards:
		return
	phase_time += delta
	if not is_night and phase_time >= day_duration:
		_start_night()
	elif is_night and phase_time >= night_duration:
		_night_clear_requested = true
		_try_finish_night()
	if awaiting_cards:
		return
	_update_lighting()
	var total: float = night_duration if is_night else day_duration
	time_changed.emit(maxf(0.0, total - phase_time), total, is_night)

func get_seconds_left() -> float:
	var total: float = night_duration if is_night else day_duration
	return maxf(0.0, total - phase_time)

func request_night_finish_when_clear() -> void:
	_night_clear_requested = true
	_try_finish_night()

## يُستدعى بعد اختيار اللاعب بطاقة: ينتقل إلى اليوم التالي.
func advance_to_next_day() -> void:
	if not awaiting_cards:
		return
	current_day += 1
	_start_day()

## أدوات اختبار/تصحيح: فرض الطور فورًا.
func force_night() -> void:
	if is_night or awaiting_cards:
		return
	_start_night()

func force_day() -> void:
	if awaiting_cards:
		return
	_start_day()

func _start_day() -> void:
	is_night = false
	phase_time = 0.0
	awaiting_cards = false
	_night_clear_requested = false
	_update_lighting()
	day_started.emit(current_day)
	phase_changed.emit(false)

func _start_night() -> void:
	is_night = true
	phase_time = 0.0
	_night_clear_requested = false
	_update_lighting()
	night_started.emit(current_day)
	phase_changed.emit(true)

func _try_finish_night() -> void:
	if not is_night or awaiting_cards:
		return
	if phase_time < night_duration and not _night_clear_requested:
		return
	if not get_tree().get_nodes_in_group("enemy").is_empty():
		return
	awaiting_cards = true
	night_cleared.emit(current_day)

func _update_lighting() -> void:
	var total: float = night_duration if is_night else day_duration
	var progress: float = clampf(phase_time / maxf(total, 0.001), 0.0, 1.0)
	var transition: float = clampf(transition_seconds / maxf(total, 0.001), 0.001, 0.49)
	var night_blend: float = 0.0
	if is_night:
		night_blend = smoothstep(0.0, transition, progress)
	else:
		night_blend = smoothstep(1.0 - transition, 1.0, progress)
	if _sun != null:
		var night_rotation: Vector3 = Vector3(-18.0, 150.0, 0.0)
		_sun.rotation_degrees = _base_sun_rotation.lerp(night_rotation, night_blend)
		_sun.light_energy = lerpf(_base_sun_energy, 0.08, night_blend)
		_sun.light_color = _base_sun_color.lerp(Color(0.20, 0.28, 0.55, 1.0), night_blend)
	if _world_environment != null and _world_environment.environment != null:
		var environment: Environment = _world_environment.environment
		environment.ambient_light_color = _day_ambient_color.lerp(_night_ambient_color, night_blend)
		environment.ambient_light_energy = lerpf(0.72, 0.12, night_blend)
		environment.background_color = _day_background.lerp(_night_background, night_blend)
