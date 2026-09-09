extends CanvasLayer
## واجهة قلب القلعة تُنشأ برمجيًا لتبقى متوافقة مع واجهة المشروع الحالية.

var bar: ProgressBar
var label: Label
var defeat_label: Label
var castle_controller: Node

func _ready() -> void:
	layer = 8
	_build_ui()
	call_deferred("_connect_castle")

func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 105)
	panel.size = Vector2(230, 62)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	label = Label.new()
	label.text = "🏰 قلب القلعة 500/500"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 500
	bar.value = 500
	bar.show_percentage = false
	box.add_child(bar)
	defeat_label = Label.new()
	defeat_label.visible = false
	defeat_label.position = Vector2(0, 260)
	defeat_label.size = Vector2(1280, 90)
	defeat_label.text = "سقط قلب القلعة\nانتهت المملكة"
	defeat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
defeat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	defeat_label.add_theme_font_size_override("font_size", 36)
	add_child(defeat_label)

func _connect_castle() -> void:
	var castle := get_tree().get_first_node_in_group("castle_core") as Node3D
	if castle == null:
		return
	castle_controller = castle.get_node_or_null("CastleController")
	if castle_controller == null:
		return
	if castle_controller.has_signal("health_changed"):
		castle_controller.health_changed.connect(_on_health_changed)
	if castle_controller.has_signal("defeated"):
		castle_controller.defeated.connect(_on_defeated)
	if castle_controller.has_method("get_health_ratio"):
		_on_health_changed(castle_controller.current_health, castle_controller.max_health)

func _on_health_changed(current: int, maximum: int) -> void:
	if bar:
		bar.max_value = maximum
		bar.value = current
	if label:
		label.text = "🏰 قلب القلعة %d/%d" % [current, maximum]

func _on_defeated() -> void:
	if defeat_label:
		defeat_label.visible = true
