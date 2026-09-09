extends CanvasLayer
## Phase 2 mobile UI: resource counters + contextual gather button.

@onready var wood_label: Label = $TopPanel/Margin/HBox/WoodLabel
@onready var stone_label: Label = $TopPanel/Margin/HBox/StoneLabel
@onready var gather_button: Button = $GatherButton
@onready var target_label: Label = $TargetLabel

var player: Node = null
var current_target: Node = null

func _ready() -> void:
	gather_button.visible = false
	target_label.text = "اقترب من شجرة أو صخرة"
	gather_button.pressed.connect(_on_gather_button_pressed)
	call_deferred("_connect_to_player")

func _connect_to_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("MobileUI: player group not found")
		return
	if player.has_signal("resources_changed"):
		player.resources_changed.connect(_on_resources_changed)
	if player.has_signal("gather_target_changed"):
		player.gather_target_changed.connect(_on_gather_target_changed)
	_on_resources_changed(player.wood_count, player.stone_count)
	_on_gather_target_changed(player.get_nearest_resource())

func _on_resources_changed(wood: int, stone: int) -> void:
	wood_label.text = "Wood: %d" % wood
	stone_label.text = "Stone: %d" % stone

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
