extends CanvasLayer
## ============================================================
## واجهة المستخدم — Phase 2 (جمع الموارد).
## ------------------------------------------------------------
## * شريط علوي (Top Bar) يعرض عدّادي الخشب والحجر.
## * زر جمع (Harvest Button) كبير وسلس يظهر تلقائياً فقط
##   عند وجود مورد (شجرة/صخرة) في متناول الملك، ويختبئ عند
##   الابتعاد أو نفاد المورد.
## ============================================================

## مسار الملك (Player) — يُضبط من المشهد.
@export var player_path: NodePath = NodePath("../King")

var _player: Player

@onready var _wood_label: Label = %WoodLabel
@onready var _stone_label: Label = %StoneLabel
@onready var _harvest_button: Button = %HarvestButton

func _ready() -> void:
	_player = get_node_or_null(player_path) as Player
	if _player == null:
		push_warning("ui.gd: player_path غير موجود: %s" % player_path)
		return

	# ربط إشارات الملك.
	_player.resources_changed.connect(_on_resources_changed)
	_player.nearest_resource_changed.connect(_on_nearest_resource_changed)

	# زر الجمع: لا يظهر إلا عند وجود مورد قريب.
	_harvest_button.pressed.connect(_on_harvest_pressed)
	_harvest_button.hide()
	# سجّله كعنصر "يحجز" اللمسة حتى لا تبدأ العصا فوقه (لمس متعدد).
	_harvest_button.add_to_group(&"ui_blockers")

	# مزامنة أولية للواجهة مع حالة الملك.
	_on_resources_changed(_player.wood_count, _player.stone_count)
	_on_nearest_resource_changed(_player.get_nearest_resource())


## تحديث عدّادي الخشب والحجر في الشريط العلوي.
func _on_resources_changed(wood: int, stone: int) -> void:
	_wood_label.text = "Wood: %d" % wood
	_stone_label.text = "Stone: %d" % stone


## إظهار/إخفاء زر الجمع حسب وجود مورد قريب، وتحديث نصّه.
func _on_nearest_resource_changed(resource: ResourceNode) -> void:
	if resource == null:
		_harvest_button.hide()
		return

	# زر باسم المورد مع الكمية المتبقية (Tree/Rock + remaining).
	var type_name: String = resource.get_display_name()
	_harvest_button.text = "Collect %s (%d)" % [type_name, resource.get_remaining_amount()]

	if not _harvest_button.visible:
		_harvest_button.show()
		# تأثير ظهور ناعم (تكبير من 0.5 إلى 1).
		_harvest_button.scale = Vector2.ONE * 0.5
		var tw := create_tween()
		tw.tween_property(_harvest_button, "scale", Vector2.ONE, 0.22) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## عند الضغط على زر الجمع: طلب الجمع من أقرب مورد للملك.
func _on_harvest_pressed() -> void:
	if _player == null:
		return
	_player.gather_nearest()

	# بعد الجمع تحدَّث الكمية الظاهرة على الزر فوراً.
	var nearest := _player.get_nearest_resource()
	if nearest != null:
		_harvest_button.text = "Collect %s (%d)" \
				% [nearest.get_display_name(), nearest.get_remaining_amount()]
