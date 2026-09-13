extends CanvasLayer
## شاشة «اختر بطاقة من 3» + شاشة نهاية الجولة.
## تعمل أثناء إيقاف اللعبة (process_mode = ALWAYS) لأن اختيار البطاقة يوقف العالم.

signal upgrade_chosen(card_id: String)
signal restart_requested()

@onready var cards_panel: Control = $Cards
@onready var title_label: Label = $Cards/Title
@onready var subtitle_label: Label = $Cards/Subtitle
@onready var cards_row: HBoxContainer = $Cards/CardsRow
@onready var card_buttons: Array = [$Cards/CardsRow/Card0, $Cards/CardsRow/Card1, $Cards/CardsRow/Card2]
@onready var game_over_panel: Control = $GameOver
@onready var game_over_title: Label = $GameOver/GameOverTitle
@onready var game_over_text: Label = $GameOver/GameOverText
@onready var restart_button: Button = $GameOver/RestartButton

var _cards: Array = []

func _ready() -> void:
	add_to_group("upgrade_overlay")
	visible = false
	game_over_panel.visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	for index in card_buttons.size():
		var button: Button = card_buttons[index]
		button.pressed.connect(_on_card_pressed.bind(index))

func show_cards(cards: Array, day: int) -> void:
	_cards = cards
	game_over_panel.visible = false
	cards_panel.visible = true
	visible = true
	title_label.text = "صمدت حتى الليلة %d" % day
	subtitle_label.text = "اختر ترقية واحدة قبل الفجر"
	for index in card_buttons.size():
		var button: Button = card_buttons[index]
		if index < cards.size():
			var card: Dictionary = cards[index]
			button.visible = true
			button.text = "%s\n\n%s" % [String(card["title"]), String(card["desc"])]
		else:
			button.visible = false

func show_game_over(day: int, reason: String, killed: int) -> void:
	visible = true
	cards_panel.visible = false
	game_over_panel.visible = true
	game_over_title.text = "سقطت المملكة"
	game_over_text.text = "%s\n\nصمدت %d %s\nأسقطت %d هيكلًا عظميًا" % [
		reason, day, "ليلة" if day == 1 else "ليالٍ", killed
	]

func hide_overlay() -> void:
	visible = false
	game_over_panel.visible = false

func _on_card_pressed(index: int) -> void:
	if index < 0 or index >= _cards.size():
		return
	var card: Dictionary = _cards[index]
	_cards = []
	hide_overlay()
	upgrade_chosen.emit(String(card["id"]))

func _on_restart_pressed() -> void:
	hide_overlay()
	restart_requested.emit()
