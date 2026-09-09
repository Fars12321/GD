extends CanvasLayer
## Phase 4 mobile UI: resources, building, day/night timer, waves and king health.

@onready var day_label: Label = $TopPanel/Margin/HBox/DayLabel
@onready var phase_label: Label = $TopPanel/Margin/HBox/PhaseLabel
@onready var time_label: Label = $TopPanel/Margin/HBox/TimeLabel
@onready var wave_label: Label = $TopPanel/Margin/HBox/WaveLabel
@onready var health_label: Label = $TopPanel/Margin/HBox/HealthLabel
@onready var wood_label: Label = $TopPanel/Margin/HBox/WoodLabel
@onready var stone_label: Label = $TopPanel/Margin/HBox/StoneLabel
@onready var gather_button: Button = $GatherButton
@onready var target_label: Label = $TargetLabel
@onready var open_build_menu_button: Button = $OpenBuildMenuButton
@onready var build_menu: PanelContainer = $BuildMenu
@onready var wall_button: Button = $BuildMenu/Margin/VBox/WallButton
@onready var tower_button: Button = $BuildMenu/Margin/VBox/TowerButton
@onready var close_menu_button: Button = $BuildMenu/Margin/VBox/CloseMenuButton
@onready var confirm_button: Button = $ConfirmButton
@onready var cancel_button: Button = $CancelButton
@onready var placement_status: Label = $PlacementStatus
@onready var warning_label: Label = $WarningLabel

var player: Node = null
var building_manager: Node = null
var day_night_manager: Node = null
var current_target: Node = null
var _is_night: bool = false

func _ready() -> void:
	gather_button.visible = false
	placement_status.visible = false
	confirm_button.visible = false
	cancel_button.visible = false
	build_menu.visible = false
	warning_label.text = ""
	target_label.text = "اقترب من شجرة أو صخرة"
	gather_button.pressed.connect(_on_gather_button_pressed)
	open_build_menu_button.pressed.connect(_on_open_build_menu_pressed)
	close_menu_button.pressed.connect(_on_close_menu_pressed)
	wall_button.pressed.connect(_on_wall_button_pressed)
	tower_button.pressed.connect(_on_tower_button_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	call_deferred("_connect_to_player")
	call_deferred("_connect_to_building_manager")
	call_deferred("_connect_to_day_night")

func _process(_delta: float) -> void:
	wave_label.text = "☠ أعداء %d" % get_tree().get_nodes_in_group("enemy").size()

func _connect_to_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("MobileUI: player group not found")
		return
	if player.has_signal("resources_changed"):
		player.resources_changed.connect(_on_resources_changed)
	if player.has_signal("gather_target_changed"):
		player.gather_target_changed.connect(_on_gather_target_changed)
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)
	_on_resources_changed(player.wood_count, player.stone_count)
	_on_gather_target_changed(player.get_nearest_resource())
	_on_health_changed(player.current_health, player.max_health)

func _connect_to_building_manager() -> void:
	building_manager = get_tree().get_first_node_in_group("building_manager")
	if building_manager == null:
		push_warning("MobileUI: building_manager group not found")
		return
	if building_manager.has_signal("placement_started"):
		building_manager.placement_started.connect(_on_placement_started)
	if building_manager.has_signal("placement_ended"):
		building_manager.placement_ended.connect(_on_placement_ended)
	if building_manager.has_signal("placement_validity_changed"):
		building_manager.placement_validity_changed.connect(_on_placement_validity_changed)
	_update_build_buttons()

func _connect_to_day_night() -> void:
	day_night_manager = get_tree().get_first_node_in_group("day_night_manager")
	if day_night_manager == null:
		day_night_manager = get_tree().current_scene.get_node_or_null("DayNightManager")
	if day_night_manager == null:
		push_warning("MobileUI: DayNightManager not found")
		return
	if day_night_manager.has_signal("time_changed"):
		day_night_manager.time_changed.connect(_on_time_changed)
	if day_night_manager.has_signal("day_started"):
		day_night_manager.day_started.connect(_on_day_started)
	if day_night_manager.has_signal("night_started"):
		day_night_manager.night_started.connect(_on_night_started)
	_on_day_started(day_night_manager.current_day)

func _on_resources_changed(wood: int, stone: int) -> void:
	wood_label.text = "🪵  %d" % wood
	stone_label.text = "🪨  %d" % stone
	_update_build_buttons()

func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "♥ %d/%d" % [current, maximum]

func _on_day_started(day: int) -> void:
	day_label.text = "اليوم %d" % day
	phase_label.text = "☀ نهار"
	warning_label.text = ""
	phase_label.modulate = Color(0.95, 0.88, 0.58, 1.0)
	_is_night = false

func _on_night_started(day: int) -> void:
	day_label.text = "اليوم %d" % day
	phase_label.text = "☾ ليل"
	phase_label.modulate = Color(0.56, 0.68, 1.0, 1.0)
	warning_label.text = "⚠ بدأت موجة الليل — دافع عن القلعة!"
	warning_label.modulate = Color(1.0, 0.55, 0.42, 1.0)
	_is_night = true

func _on_time_changed(seconds_left: float, _total: float, is_night: bool) -> void:
	var seconds := maxi(0, int(ceil(seconds_left)))
	time_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	if not is_night and seconds <= 10:
		warning_label.text = "⚠ اقترب الليل — جهّز دفاعاتك!"
		warning_label.modulate = Color(1.0, 0.72, 0.35, 1.0)
	elif is_night:
		_is_night = true
		if get_tree().get_nodes_in_group("enemy").size() > 0:
			warning_label.text = "☠ %d عدوًا داخل المعركة" % get_tree().get_nodes_in_group("enemy").size()
			warning_label.modulate = Color(1.0, 0.45, 0.40, 1.0)

func _on_gather_target_changed(target: Node) -> void:
	current_target = target
	gather_button.visible = target != null
	if target == null:
		target_label.text = "اقترب من شجرة أو صخرة"
		return
	var resource_name: String = "مورد"
	var remaining: int = 0
	if target.has_method("get_resource_name"):
		resource_name = str(target.get_resource_name())
	if target.has_method("get_remaining_amount"):
		remaining = int(target.get_remaining_amount())
	target_label.text = "%s • متبقٍ %d" % [resource_name, remaining]
	gather_button.text = "جمع %s" % resource_name

func _on_gather_button_pressed() -> void:
	if player:
		player.gather_nearest()
	if is_instance_valid(current_target):
		_on_gather_target_changed(current_target)

func _on_open_build_menu_pressed() -> void:
	_update_build_buttons()
	build_menu.visible = true

func _on_close_menu_pressed() -> void:
	build_menu.visible = false

func _on_wall_button_pressed() -> void:
	_start_building("wall")

func _on_tower_button_pressed() -> void:
	_start_building("tower")

func _start_building(building_id: String) -> void:
	if building_manager == null:
		return
	build_menu.visible = false
	building_manager.start_placement(building_id)

func _on_confirm_button_pressed() -> void:
	if building_manager:
		building_manager.confirm_placement()

func _on_cancel_button_pressed() -> void:
	if building_manager:
		building_manager.cancel_placement()

func _on_placement_started(building_id: String) -> void:
	confirm_button.visible = true
	cancel_button.visible = true
	confirm_button.disabled = true
	open_build_menu_button.visible = false
	placement_status.visible = true
	placement_status.modulate = Color(0.9, 0.95, 1.0, 1.0)
	var display_name := "سور" if building_id == "wall" else "برج دفاعي"
	placement_status.text = "معاينة %s — حرّكها ثم أكد" % display_name

func _on_placement_validity_changed(is_valid: bool) -> void:
	if not placement_status.visible:
		return
	confirm_button.disabled = not is_valid
	placement_status.text = "✓ مكان صالح — اضغط تأكيد" if is_valid else "✗ مكان غير صالح أو الموارد غير كافية"
	placement_status.modulate = Color(0.65, 1.0, 0.7, 1.0) if is_valid else Color(1.0, 0.55, 0.5, 1.0)

func _on_placement_ended() -> void:
	confirm_button.visible = false
	cancel_button.visible = false
	confirm_button.disabled = true
	placement_status.visible = false
	open_build_menu_button.visible = true

func _update_build_buttons() -> void:
	if player == null or building_manager == null:
		return
	var wall_cost: Dictionary = building_manager.get_cost("wall")
	var tower_cost: Dictionary = building_manager.get_cost("tower")
	wall_button.disabled = player.wood_count < int(wall_cost.get("wood", 0)) or player.stone_count < int(wall_cost.get("stone", 0))
	tower_button.disabled = player.wood_count < int(tower_cost.get("wood", 0)) or player.stone_count < int(tower_cost.get("stone", 0))
	wall_button.tooltip_text = "تكلفة: 10 خشب"
	tower_button.tooltip_text = "تكلفة: 10 حجر"
