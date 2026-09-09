extends Node3D
## ============================================================
## المشهد الرئيسي — مشغّل Phase 1.
## ------------------------------------------------------------
## يجمع المدخلات (عصا لمس افتراضية + لوحة مفاتيح) ويحوّلها عبر
## الكاميرا إلى اتجاه عالمي، ثم يمررها للملك. كما يجهّز الأرضية
## وعلامات اختبار بصرية وإضاءة للتحقق من سلاسة التتبع.
## ============================================================

@onready var king: GDKPlayer = $King
@onready var camera_rig: GDKCameraRig = $CameraRig
@onready var joystick: GDKJoystick = $UI/Joystick

## الحدود المربعة لمنطقة التجول (نصف الضلع). الأرضية 160 وحدة.
@export var world_half_extent: float = 78.0
## هل ننشئ علامات اختبار (أعمدة ملونة) لتوضيح حركة الكاميرا؟
@export var spawn_test_markers: bool = true

func _ready() -> void:
	# إضاءة الشمس بزاوية لطيفة (تُضبط هنا لأن project.godot لا يخزّن دوالاً).
	var sun := $World/Sun as DirectionalLight3D
	sun.rotation_degrees = Vector3(-55.0, -40.0, 0.0)

	if spawn_test_markers:
		_spawn_test_markers()

	# كاميرا الهدف/التبعية.
	if king != null and camera_rig != null:
		camera_rig.target = king
		# بدء الكاميرا فوق الملك مباشرة (بدون اندفاع عند التشغيل).
		camera_rig.global_position = king.global_position


func _physics_process(_delta: float) -> void:
	# --- 1) تجميع المدخلات: عصا اللمس + أسهم/أزرار لوحة المفاتيح. ---
	var joystick_vec: Vector2 = joystick.output if joystick != null else Vector2.ZERO
	var keyboard_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# limit_length يمنع أن تتجاوز قيمة المتجه 1 عند دمج مصدري إدخال.
	var axis := (joystick_vec + keyboard_vec).limit_length(1.0)

	# --- 2) تحويل المدخلات إلى اتجاه عالمي نسبةً لاتجاه الكاميرا. ---
	var world_dir: Vector3 = camera_rig.world_dir_from_axis(axis)

	# --- 3) تمرير الحركة للملك. ---
	if king != null:
		king.set_move_direction(world_dir)

		# إبقاء الملك داخل حدود منطقة الاختبار.
		var p := king.global_position
		king.global_position = Vector3(
			clampf(p.x, -world_half_extent, world_half_extent),
			p.y,
			clampf(p.z, -world_half_extent, world_half_extent)
		)


## ============================================================
## علامات اختبار: أعمدة ملونة موزّعة حول القرية ليتضح التتبع
## والمنظور ثلاثي الأبعاد أثناء تحريك الملك. (تُستبدل لاحقاً
## بمباني اللعبة الحقيقية من أصول Kenney/KayKit)
## ============================================================
func _spawn_test_markers() -> void:
	var holder := Node3D.new()
	holder.name = "TestMarkers"
	$World.add_child(holder)

	var palette := [
		Color(0.78, 0.32, 0.22), # طوبي
		Color(0.42, 0.55, 0.78), # أزرق
		Color(0.86, 0.76, 0.45), # ذهبي
	]
	var palette_index := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260909

	# مصفوفة دائرية من الأعمدة على بعد مختلف.
	for i in range(28):
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(6.0, world_half_extent - 2.0)
		# ارتفاع عشوائي لكن محدود ليبقى المشهد واضحاً.
		var h := rng.randf_range(0.6, 3.2)

		var mesh_instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.5, h, 0.5)
		mesh_instance.mesh = box

		var mat := StandardMaterial3D.new()
		mat.albedo_color = palette[palette_index % palette.size()]
		mat.roughness = 0.9
		mesh_instance.material_override = mat
		palette_index += 1

		holder.add_child(mesh_instance)
		mesh_instance.position = Vector3(
			cos(angle) * dist,
			h * 0.5,
			sin(angle) * dist
		)
