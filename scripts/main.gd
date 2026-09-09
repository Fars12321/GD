extends Node3D
## سكربت المشهد الرئيسي Main.tscn
## مهمته الوحيدة في هذه المرحلة (Phase 1): وصل إشارة عصا التحكم بحركة اللاعب.

@onready var player: CharacterBody3D = $Player
@onready var joystick: Control = $TouchControls/VirtualJoystick

func _ready() -> void:
	joystick.joystick_input.connect(_on_joystick_input)

func _on_joystick_input(vector: Vector2) -> void:
	player.set_joystick_input(vector)
