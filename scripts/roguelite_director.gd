extends Node
## مدير جولة «ليلة واحدة».
## يربط دورة النهار/ليل بمولّد الموجات وبطاقات الترقية وحالة الهزيمة.

signal card_offered(cards: Array, day: int)
signal game_over(day: int, reason: String)

enum RunState { DAY, NIGHT, CARDS, OVER }

@export var cards_per_choice: int = 3

var state: int = RunState.DAY
var run_stats: RunStats = RunStats.new()
var cards_taken: Array = []
var offered_cards: Array = []

var _day_night: Node = null
var _spawner: Node = null
var _core: Node = null
var _player: Node = null
var _hud: Node = null
var _overlay: Node = null
var _core_base_health: int = 500
var _finished: bool = false

func _ready() -> void:
	add_to_group("roguelite_director")
	_day_night = get_tree().get_first_node_in_group("day_night_manager")
	_spawner = get_tree().get_first_node_in_group("wave_spawner")
	_core = get_tree().get_first_node_in_group("castle_core")
	_player = get_tree().get_first_node_in_group("player")
	_hud = get_tree().get_first_node_in_group("hud")
	_overlay = get_node_or_null("../UpgradeOverlay")
	_connect_signals()
	if _core != null:
		_core_base_health = int(_core.max_health)
	_sync_initial_state()

func _connect_signals() -> void:
	if _day_night != null:
		if _day_night.has_signal("day_started"):
			_day_night.day_started.connect(_on_day_started)
		if _day_night.has_signal("night_started"):
			_day_night.night_started.connect(_on_night_started)
		if _day_night.has_signal("night_cleared"):
			_day_night.night_cleared.connect(_on_night_cleared)
		if _day_night.has_signal("time_changed"):
			_day_night.time_changed.connect(_on_time_changed)
	if _core != null and _core.has_signal("castle_defeated"):
		_core.castle_defeated.connect(_on_castle_defeated)
	if _player != null and _player.has_signal("player_defeated"):
		_player.player_defeated.connect(_on_player_defeated)
	if _overlay != null:
		if _overlay.has_signal("upgrade_chosen"):
			_overlay.upgrade_chosen.connect(choose_upgrade)
		if _overlay.has_signal("restart_requested"):
			_overlay.restart_requested.connect(restart_run)

## DayNightManager يبث day_started داخل _ready() قبل أن نكون جاهزين، لذا نزامن الحالة يدويًا.
func _sync_initial_state() -> void:
	var day: int = current_day()
	state = RunState.NIGHT if (_day_night != null and bool(_day_night.is_night)) else RunState.DAY
	if state == RunState.DAY:
		_on_day_started(day)
	_refresh_hud()

func get_run_stats() -> RunStats:
	return run_stats

func current_day() -> int:
	if _day_night != null:
		return int(_day_night.current_day)
	return 1

func total_kills() -> int:
	if _spawner != null and is_instance_valid(_spawner) and "total_killed" in _spawner:
		return int(_spawner.total_killed)
	return 0

func _on_day_started(day: int) -> void:
	if _finished:
		return
	state = RunState.DAY
	if day > 1:
		_apply_dawn_bonuses()
	_refresh_hud()

func _on_night_started(_day: int) -> void:
	if _finished:
		return
	state = RunState.NIGHT
	_refresh_hud()

func _on_night_cleared(day: int) -> void:
	offer_cards(day)

## يعرض 3 بطاقات ويوقف العالم حتى يختار اللاعب.
func offer_cards(day: int) -> void:
	if _finished or state == RunState.OVER:
		return
	state = RunState.CARDS
	offered_cards = UpgradeDeck.roll(cards_per_choice)
	if _day_night != null and "awaiting_cards" in _day_night:
		_day_night.awaiting_cards = true
	if _overlay != null and _overlay.has_method("show_cards"):
		_overlay.show_cards(offered_cards, day)
	get_tree().paused = true
	card_offered.emit(offered_cards, day)

## يُستدعى من الشاشة (أو من الاختبار) بعد اختيار بطاقة.
func choose_upgrade(card_id: String) -> void:
	if state != RunState.CARDS:
		return
	_apply_card(card_id)
	get_tree().paused = false
	state = RunState.DAY
	if _day_night != null and _day_night.has_method("advance_to_next_day"):
		_day_night.advance_to_next_day()

func restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_castle_defeated() -> void:
	_finish_run("سقطت القلعة")

func _on_player_defeated() -> void:
	_finish_run("سقط الملك")

func _finish_run(reason: String) -> void:
	if _finished:
		return
	_finished = true
	state = RunState.OVER
	if _overlay != null and _overlay.has_method("show_game_over"):
		_overlay.show_game_over(current_day(), reason, total_kills())
	get_tree().paused = true
	game_over.emit(current_day(), reason)

func _apply_dawn_bonuses() -> void:
	if run_stats.income_per_day > 0 and _player != null and _player.has_method("add_resources"):
		_player.add_resources(run_stats.income_per_day, run_stats.income_per_day)
	if run_stats.repair_on_dawn_ratio > 0.0 and _core != null and _core.has_method("repair_ratio"):
		_core.repair_ratio(run_stats.repair_on_dawn_ratio)

func _apply_card(card_id: String) -> void:
	cards_taken.append(card_id)
	match card_id:
		"mason":
			run_stats.castle_health_mult += 0.30
			_refresh_core_health()
			if _core != null and _core.has_method("repair_ratio"):
				_core.repair_ratio(0.20)
		"sharp_steel":
			run_stats.tower_damage_mult += 0.40
		"rapid_fire":
			run_stats.tower_interval_mult *= 0.75
		"long_watch":
			run_stats.tower_range_mult += 0.30
		"royal_taxes":
			run_stats.income_per_day += 3
			if _player != null and _player.has_method("add_resources"):
				_player.add_resources(8, 8)
		"swift_crown":
			run_stats.player_speed_mult += 0.20
		"kings_wrath":
			run_stats.player_damage_bonus += 10
		"deep_pockets":
			run_stats.gather_bonus += 1
		"blessed_ground":
			run_stats.enemy_speed_mult *= 0.85
		"battle_horn":
			run_stats.repair_on_dawn_ratio += 0.20
		"gold_vein":
			run_stats.wave_reward_bonus += 4
		"fortified_gate":
			run_stats.wall_health_mult += 0.50
	_refresh_buildings()
	_refresh_hud()

func _refresh_core_health() -> void:
	if _core == null or not _core.has_method("set_max_health"):
		return
	_core.set_max_health(int(round(float(_core_base_health) * run_stats.castle_health_mult)))

func _refresh_buildings() -> void:
	for node in get_tree().get_nodes_in_group("buildings"):
		if is_instance_valid(node) and node.has_method("apply_run_stats"):
			node.apply_run_stats()

func _on_time_changed(seconds_left: float, _total_seconds: float, is_night: bool) -> void:
	if _hud == null or not is_instance_valid(_hud) or not _hud.has_method("set_phase_label"):
		return
	var phase: String = "ليل — دافع!" if is_night else "نهار — اجمع وابنِ"
	_hud.set_phase_label("اليوم %d • %s • %ds" % [current_day(), phase, int(ceil(seconds_left))])

func _refresh_hud() -> void:
	if _hud == null or not is_instance_valid(_hud):
		return
	if _hud.has_method("set_attack_enabled"):
		_hud.set_attack_enabled(state == RunState.NIGHT)
	if _hud.has_method("set_castle_health") and _core != null:
		_hud.set_castle_health(int(_core.current_health), int(_core.max_health))
	if _hud.has_method("set_player_health") and _player != null:
		_hud.set_player_health(int(_player.current_health), int(_player.max_health))
