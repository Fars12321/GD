extends SceneTree
## اختبار «ليلة واحدة» بلا رأس (headless).
## يغطّي: الدورة، الموجات، مكافأة القتل، البطاقات، الإيقاف المؤقت، صحة القلعة، وحالة الهزيمة.
## التشغيل: godot --headless --path . --script ci/godot_smoke_roguelite.gd

var _main: Node = null
var _director: Node = null
var _day_night: Node = null
var _core: Node = null
var _player: Node = null
var _spawner: Node = null
var _checks: int = 0

# مرآة لترتيب enum RunState في roguelite_director.gd (نتجنّب الوصول إلى enum عبر متغيّر من نوع Node).
const STATE_DAY: int = 0
const STATE_NIGHT: int = 1
const STATE_CARDS: int = 2
const STATE_OVER: int = 3

func _check(condition: bool, message: String) -> void:
	assert(condition, message)
	if condition:
		_checks += 1

func _init() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn") as PackedScene
	assert(main_scene != null, "Main.tscn could not be loaded")
	_main = main_scene.instantiate()
	root.add_child(_main)
	_director = get_first_node_in_group("roguelite_director")
	_day_night = get_first_node_in_group("day_night_manager")
	_core = get_first_node_in_group("castle_core")
	_player = get_first_node_in_group("player")
	_spawner = get_first_node_in_group("wave_spawner")

	_check(_director != null, "RogueliteDirector missing")
	_check(_day_night != null, "DayNightManager missing")
	_check(_core != null, "CastleCore missing")
	_check(_player != null, "Player missing")
	_check(_spawner != null, "WaveSpawner missing")
	_check(_main.get_node_or_null("Player") != null, "Player node missing in Main.tscn")
	_check(_main.get_node_or_null("BuildingManager") != null, "BuildingManager missing in Main.tscn")
	_check(_main.get_node_or_null("NavigationRegion3D") != null, "NavigationRegion3D missing in Main.tscn")
	_check(_main.get_node_or_null("UpgradeOverlay") != null, "UpgradeOverlay missing in Main.tscn")
	_check(_director.state == STATE_DAY, "Run should start in DAY state")
	_check(_day_night.current_day == 1, "Run should start on day 1")

	# 1) فرض الليل ثم تأكيد تولّد الأعداء.
	_day_night.force_night()
	_check(bool(_day_night.is_night), "force_night() did not start the night")
	_check(_director.state == STATE_NIGHT, "Director should switch to NIGHT")

	await _settle(30)
	var spawned: Array = get_nodes_in_group("enemy")
	_check(spawned.size() > 0, "No enemies spawned during the night")

	# 2) قتل عدو يمنح موارد ويسقطه من المجموعة.
	var enemies_before: int = get_nodes_in_group("enemy").size()
	var wood_before: int = int(_player.wood_count)
	var victim: Node = get_nodes_in_group("enemy")[0]
	victim.take_damage(99999)
	_check(get_nodes_in_group("enemy").size() == enemies_before - 1, "Enemy was not removed from the enemy group")
	_check(int(_player.wood_count) > wood_before, "Killing an enemy did not reward resources")
	_check(int(_spawner.total_killed) >= 1, "Spawner did not count the kill")

	# 3) مجموعة البطاقات: 3 بطاقات فريدة ومعروفة.
	var cards: Array = UpgradeDeck.roll(3)
	_check(cards.size() == 3, "UpgradeDeck.roll(3) should return 3 cards")
	var seen: Array = []
	for card in cards:
		var card_id: String = String(card["id"])
		_check(not seen.has(card_id), "Rolled duplicate card: " + card_id)
		_check(UpgradeDeck.get_card(card_id).size() > 0, "Unknown card id: " + card_id)
		seen.append(card_id)

	# 4) عرض البطاقات يوقف العالم، والاختيار يستأنفه ويقدّم اليوم.
	_director.offer_cards(1)
	_check(_director.state == STATE_CARDS, "Director should be in CARDS state")
	_check(paused, "World should be paused while choosing a card")
	_director.choose_upgrade("sharp_steel")
	_check(not paused, "World should resume after choosing a card")
	_check(_director.state == STATE_DAY, "Director should return to DAY after the choice")
	_check(int(_day_night.current_day) == 2, "Day counter should advance to 2")
	_check(is_equal_approx(_director.get_run_stats().tower_damage_mult, 1.4), "sharp_steel should raise tower damage to 1.4x")

	# 5) بطاقة mason ترفع صحة القلعة القصوى.
	var health_before: int = int(_core.max_health)
	_director.offer_cards(2)
	_director.choose_upgrade("mason")
	_check(int(_core.max_health) > health_before, "mason should raise the castle max health")

	# 6) الضرر على القلعة ثم حالة الهزيمة.
	var current_before: int = int(_core.current_health)
	_core.take_damage(50)
	_check(int(_core.current_health) == current_before - 50, "Castle core did not register damage")
	_core.take_damage(99999)
	_check(_director.state == STATE_OVER, "Director should be in OVER state after the castle falls")
	_check(paused, "World should be paused on game over")
	paused = false

	print("ROGUELITE_SMOKE_PASS checks=%d" % _checks)
	quit(0)

func _settle(frames: int) -> void:
	for index in frames:
		await process_frame
