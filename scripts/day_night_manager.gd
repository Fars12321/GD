extends Node
## Phase 4: automatic 60s day / 40s night cycle with smooth lighting.

signal day_started(day: int)
signal night_started(day: int)
signal phase_changed(is_night: bool)
signal time_changed(seconds_left: float, total_seconds: float, is_night: bool)

@export var day_duration: float = 60.0
@export var night_duration: float = 40.0
@export var transition_seconds: float = 5.0

@onready var sun: DirectionalLight3D = get_parent().get_node_or_null("DirectionalLight3D")
@onready var world_environment: WorldEnvironment = get_parent().get_node_or_null("WorldEnvironment")

var current_day: int = 1
var is_night: bool = false
var phase_time: float = 0.0
var _night_clear_requested: bool = false
var _base_sun_rotation: Vector3 = Vector3(-48.0, -28.0, 0.0)
var _base_sun_energy: float = 1.05
var _base_sun_color: Color = Color(1.0, 0.92, 0.78, 1.0)
var _day_ambient_color: Color = Color(0.70, 0.76, 0.86, 1.0)
var _night_ambient_color: Color = Color(0.13, 0.18, 0.32, 1.0)
var _day_background: Color = Color(0.075, 0.11, 0.17, 1.0)
var _night_background: Color = Color(0.008, 0.015, 0.045, 1.0)

func _ready() -> void:
	if sun:
		_base_sun_rotation = sun.rotation_degrees
		_base_sun_energy = sun.light_energy
		_base_sun_color = sun.light_color
	_start_day()

func _process(delta: float) -> void:
	phase_time += delta
	if not is_night and phase_time >= day_duration:
		_start_night()
	elif is_night and phase_time >= night_duration:
		_night_clear_requested = true
		_try_finish_night()
	_update_lighting()
	time_changed.emit(maxf(0.0, (night_duration if is_night else day_duration) - phase_time), night_duration if is_night else day_duration, is_night)

func request_night_finish_when_clear() -> void:
	_night_clear_requested = true
	_try_finish_night()

func _start_day() -> void:
	is_night = false
	phase_time = 0.0
	_night_clear_requested = false
	_update_lighting(true)
	day_started.emit(current_day)
	phase_changed.emit(false)

func _start_night() -> void:
	is_night = true
	phase_time = 0.0
	_night_clear_requested = false
	_update_lighting(true)
	night_started.emit(current_day)
	phase_changed.emit(true)

func _try_finish_night() -> void:
	if not is_night or phase_time < night_duration:
		return
	if get_tree().get_nodes_in_group("enemy").is_empty():
		current_day += 1
		_start_day()

func _update_lighting(_force: bool = false) -> void:
	var total := night_duration if is_night else day_duration
	var progress := clampf(phase_time / maxf(total, 0.001), 0.0, 1.0)
	var transition := clampf(transition_seconds / maxf(total, 0.001), 0.001, 0.49)
	var night_blend := 0.0
	if is_night:
		night_blend = smoothstep(0.0, transition, progress)
	else:
		night_blend = smoothstep(1.0 - transition, 1.0, progress)
	if sun:
		var night_rotation := Vector3(-18.0, 150.0, 0.0)
		sun.rotation_degrees = _base_sun_rotation.lerp(night_rotation, night_blend)
		sun.light_energy = lerpf(_base_sun_energy, 0.08, night_blend)
		sun.light_color = _base_sun_color.lerp(Color(0.20, 0.28, 0.55, 1.0), night_blend)
	if world_environment and world_environment.environment:
		var env := world_environment.environment
		env.ambient_light_color = _day_ambient_color.lerp(_night_ambient_color, night_blend)
		env.ambient_light_energy = lerpf(0.72, 0.12, night_blend)
		env.background_color = _day_background.lerp(_night_background, night_blend)
