class_name UpgradeDeck
extends RefCounted
## مجموعة بطاقات الترقية: يُسحب منها 3 بطاقات فريدة بين كل ليلة والتي تليها.
## البطاقات هي «خطّاف الإدمان» في نمط ليلة واحدة: لا جولتان متشابهتان.

const CARDS: Array = [
	{"id": "mason", "title": "بناء متين", "desc": "صحة القلعة +30٪ وإصلاح فوري 20٪"},
	{"id": "sharp_steel", "title": "فولاذ حاد", "desc": "ضرر الأبراج +40٪"},
	{"id": "rapid_fire", "title": "رماة مدرّبون", "desc": "الأبراج تطلق أسرع 25٪"},
	{"id": "long_watch", "title": "أبراج مراقبة", "desc": "مدى الأبراج +30٪"},
	{"id": "royal_taxes", "title": "ضرائب ملكية", "desc": "+8 خشب وحجر الآن، و+3 كل فجر"},
	{"id": "swift_crown", "title": "تاج خفيف", "desc": "سرعة الملك +20٪"},
	{"id": "kings_wrath", "title": "غضب الملك", "desc": "ضرر هجوم الملك +10"},
	{"id": "deep_pockets", "title": "أيادٍ عاملة", "desc": "+1 مورد لكل ضربة جمع"},
	{"id": "blessed_ground", "title": "أرض مباركة", "desc": "الأعداء أبطأ 15٪"},
	{"id": "battle_horn", "title": "بوق المعركة", "desc": "القلعة تُصلح 20٪ عند كل فجر"},
	{"id": "gold_vein", "title": "عرق ذهب", "desc": "مكافأة نهاية الموجة +4"},
	{"id": "fortified_gate", "title": "بوابة محصّنة", "desc": "صحة الأسوار +50٪"},
]

static func roll(count: int, excluded: Array = []) -> Array:
	var pool: Array = []
	for card in CARDS:
		if not excluded.has(card["id"]):
			pool.append(card)
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))

static func get_card(card_id: String) -> Dictionary:
	for card in CARDS:
		if String(card["id"]) == card_id:
			return card
	return {}

static func all_ids() -> Array:
	var ids: Array = []
	for card in CARDS:
		ids.append(card["id"])
	return ids
