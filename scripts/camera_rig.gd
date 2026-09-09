extends Camera3D
## سكربت الكاميرا: يُلحق مباشرة على عقدة Camera3D في مشهد Main.
## يجعل الكاميرا تتبع اللاعب بسلاسة من زاوية Top-Down/Isometric ثابتة.

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0, 12, 8)
@export var follow_speed: float = 5.0
@export var look_down_angle: float = -55.0

var target: Node3D

func _ready() -> void:
	if target_path != NodePath(""):
		target = get_node(target_path)
	rotation_degrees.x = look_down_angle

func _process(delta: float) -> void:
	if target == null:
		return
	var desired_position: Vector3 = target.global_position + offset
	var smoothing: float = 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired_position, smoothing)
