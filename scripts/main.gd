extends Node3D
## المشهد الرئيسي: توصيل الإدخال + تهيئة مظهر العالم في Phase 3.

@onready var player: CharacterBody3D = $Player
@onready var joystick: Control = $TouchControls/VirtualJoystick
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment

func _ready() -> void:
	joystick.joystick_input.connect(_on_joystick_input)
	_configure_world_presentation()

func _process(delta: float) -> void:
	# حركة ضوء خفيفة جدًا تمنح العالم عمقًا بصريًا دون تكلفة ظلال.
	if sun:
		sun.rotation_degrees.y = -28.0 + sin(Time.get_ticks_msec() * 0.00005) * 2.0

func _on_joystick_input(vector: Vector2) -> void:
	player.set_joystick_input(vector)

func _configure_world_presentation() -> void:
	if world_environment == null or world_environment.environment == null:
		return
	world_environment.environment.ambient_light_energy = 0.72
	world_environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
