extends Node
## حفظ تقدم خفيف وآمن للهاتف: أفضل يوم، الموارد، وترقية القلعة.

const SAVE_PATH := "user://village_defense_save.json"

var best_day: int = 1
var castle_level: int = 1
var total_days_survived: int = 0
var total_enemies_defeated: int = 0

func _ready() -> void:
	load_game()

func record_day(day: int) -> void:
	best_day = maxi(best_day, day)
	total_days_survived = maxi(total_days_survived, day - 1)
	save_game()

func record_enemy_defeated() -> void:
	total_enemies_defeated += 1
	if total_enemies_defeated % 10 == 0:
		save_game()

func upgrade_castle() -> void:
	castle_level += 1
	save_game()

func save_game() -> void:
	var data := {
		"version": 1,
		"best_day": best_day,
		"castle_level": castle_level,
		"total_days_survived": total_days_survived,
		"total_enemies_defeated": total_enemies_defeated
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		best_day = maxi(1, int(parsed.get("best_day", 1)))
		castle_level = maxi(1, int(parsed.get("castle_level", 1)))
		total_days_survived = maxi(0, int(parsed.get("total_days_survived", 0)))
		total_enemies_defeated = maxi(0, int(parsed.get("total_enemies_defeated", 0)))
