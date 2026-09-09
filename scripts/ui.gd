extends CanvasLayer
## واجهة الموارد والبناء للمرحلة 3.

@onready var wood_label: Label = $TopPanel/HBoxContainer/WoodLabel
@onready var stone_label: Label = $TopPanel/HBoxContainer/StoneLabel
@onready var gather_button: Button = $GatherButton
@onready var open_build_menu_button: Button = $OpenBuildMenuButton
@onready var build_menu: PanelContainer = $BuildMenu
@onready var wall_button: Button = $BuildMenu/VBoxContainer/WallButton
@onready var tower_button: Button = $BuildMenu/VBoxContainer/TowerButton
@onready var close_menu_button: Button = $BuildMenu/VBoxContainer/CloseMenuButton
@onready var confirm_button: Button = $ConfirmButton
@onready var cancel_button: Button = $CancelButton

var player: Node = null
var building_manager: Node = null

func _ready() -> void:
	gather_button.visible = false
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

func _on_resources_changed(wood: int, stone: int) -> void:
	wood_label.text = "خشب: %d" % wood
	stone_label.text = "حجر: %d" % stone

func _on_gather_target_changed(target: Node) -> void:
	gather_button.visible = target != null

func _on_gather_button_pressed() -> void:
	if player:
		player.gather_nearest()

func _on_open_build_menu_pressed() -> void:
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

func _on_placement_started(_building_id: String) -> void:
	confirm_button.visible = true
	cancel_button.visible = true
	open_build_menu_button.visible = false

func _on_placement_ended() -> void:
	confirm_button.visible = false
	cancel_button.visible = false
	open_build_menu_button.visible = true
