extends CanvasLayer
## واجهة Phase 3: موارد، حالة الهدف، البناء، وتغذية راجعة واضحة للموبايل.

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

var player: Node = null
var building_manager: Node = null
var current_target: Node = null

func _ready() -> void:
	gather_button.visible = false
	placement_status.visible = false
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

func _connect_to_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("UI: player group not found")
		return
	player.resources_changed.connect(_on_resources_changed)
	player.gather_target_changed.connect(_on_gather_target_changed)
	_on_resources_changed(player.wood_count, player.stone_count)

func _connect_to_building_manager() -> void:
	building_manager = get_tree().get_first_node_in_group("building_manager")
	if building_manager == null:
		push_warning("UI: building_manager group not found")
		return
	building_manager.placement_started.connect(_on_placement_started)
	building_manager.placement_ended.connect(_on_placement_ended)
	building_manager.placement_validity_changed.connect(_on_placement_validity_changed)

func _on_resources_changed(wood: int, stone: int) -> void:
	wood_label.text = "🪵  %d" % wood
	stone_label.text = "🪨  %d" % stone
	_update_build_buttons()

func _on_gather_target_changed(target: Node) -> void:
	current_target = target
	gather_button.visible = target != null
	if target == null:
		target_label.text = "اقترب من شجرة أو صخرة"
		return
	var resource_name := target.get_resource_name() if target.has_method("get_resource_name") else "مورد"
	var remaining := target.get_remaining_amount() if target.has_method("get_remaining_amount") else 0
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
	open_build_menu_button.visible = false
	placement_status.visible = true
	placement_status.text = "حرّك المعاينة ثم أكد البناء"
	placement_status.modulate = Color(0.9, 0.95, 1.0, 1.0)
	placement_status.set_meta("building_id", building_id)

func _on_placement_validity_changed(is_valid: bool) -> void:
	if not placement_status.visible:
		return
	placement_status.text = "✓ مكان صالح — اضغط تأكيد" if is_valid else "✗ المكان غير صالح أو الموارد غير كافية"
	placement_status.modulate = Color(0.65, 1.0, 0.7, 1.0) if is_valid else Color(1.0, 0.55, 0.5, 1.0)

func _on_placement_ended() -> void:
	confirm_button.visible = false
	cancel_button.visible = false
	placement_status.visible = false
	open_build_menu_button.visible = true

func _update_build_buttons() -> void:
	if player == null or building_manager == null:
		return
	var wall_cost: Dictionary = building_manager.get_cost("wall")
	var tower_cost: Dictionary = building_manager.get_cost("tower")
	wall_button.disabled = player.wood_count < int(wall_cost.get("wood", 0)) or player.stone_count < int(wall_cost.get("stone", 0))
	tower_button.disabled = player.wood_count < int(tower_cost.get("wood", 0)) or player.stone_count < int(tower_cost.get("stone", 0))
