extends Node3D
## Main scene wiring and presentation.

@onready var player: CharacterBody3D = $Player
@onready var joystick: Control = $TouchControls/VirtualJoystick
@onready var world_environment: WorldEnvironment = $WorldEnvironment

func _ready() -> void:
	if not joystick.joystick_input.is_connected(_on_joystick_input):
		joystick.joystick_input.connect(_on_joystick_input)
	_setup_castle_controller()
	_configure_world_presentation()

func _on_joystick_input(vector: Vector2) -> void:
	player.set_joystick_input(vector)

func _setup_castle_controller() -> void:
	var castle := get_node_or_null("CastleCore")
	if castle == null or castle.get_node_or_null("CastleController") != null:
		return
	var script := load("res://scripts/castle_controller.gd") as Script
	if script == null:
		return
	var controller := Node.new()
	controller.name = "CastleController"
	controller.set_script(script)
	castle.add_child(controller)

func _configure_world_presentation() -> void:
	if world_environment == null or world_environment.environment == null:
		return
	world_environment.environment.ambient_light_energy = 0.72
	world_environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
