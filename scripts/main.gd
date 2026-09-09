extends Node3D
## المشهد الرئيسي: توصيل الإدخال وتهيئة مظهر العالم.

@onready var player: CharacterBody3D = $Player
@onready var joystick: Control = $TouchControls/VirtualJoystick
@onready var world_environment: WorldEnvironment = $WorldEnvironment

func _ready() -> void:
	if not joystick.joystick_input.is_connected(_on_joystick_input):
		joystick.joystick_input.connect(_on_joystick_input)
	_configure_world_presentation()

func _on_joystick_input(vector: Vector2) -> void:
	player.set_joystick_input(vector)

func _configure_world_presentation() -> void:
	if world_environment == null or world_environment.environment == null:
		return
	world_environment.environment.ambient_light_energy = 0.72
	world_environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
