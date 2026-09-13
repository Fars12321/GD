class_name RunStats
extends RefCounted
## إحصاءات الجولة في نمط «ليلة واحدة».
## كل بطاقة ترقية تعدّل قيمة هنا، والمكوّنات تقرأ القيم عبر roguelite_director.

var castle_health_mult: float = 1.0
var castle_repair_on_pick: float = 0.0
var repair_on_dawn_ratio: float = 0.0
var tower_damage_mult: float = 1.0
var tower_interval_mult: float = 1.0
var tower_range_mult: float = 1.0
var wall_health_mult: float = 1.0
var player_speed_mult: float = 1.0
var player_damage_bonus: int = 0
var gather_bonus: int = 0
var income_per_day: int = 0
var wave_reward_bonus: int = 0
var enemy_speed_mult: float = 1.0

func scaled_castle_health(base: int) -> int:
	return maxi(1, int(round(float(base) * castle_health_mult)))

func scaled_wall_health(base: int) -> int:
	return maxi(1, int(round(float(base) * wall_health_mult)))

func scaled_tower_damage(base: int) -> int:
	return maxi(1, int(round(float(base) * tower_damage_mult)))

func scaled_tower_interval(base: float) -> float:
	return maxf(0.15, base * tower_interval_mult)

func scaled_tower_range(base: float) -> float:
	return maxf(1.0, base * tower_range_mult)

func scaled_player_speed(base: float) -> float:
	return maxf(1.0, base * player_speed_mult)

func scaled_player_damage(base: int) -> int:
	return maxi(1, base + player_damage_bonus)

func scaled_enemy_speed(base: float) -> float:
	return maxf(0.5, base * enemy_speed_mult)

func scaled_gather(base: int) -> int:
	return maxi(1, base + gather_bonus)

func to_text() -> String:
	return "castle×%.2f tower_dmg×%.2f tower_int×%.2f tower_rng×%.2f speed×%.2f" % [
		castle_health_mult, tower_damage_mult, tower_interval_mult, tower_range_mult, player_speed_mult
	]
