extends StaticBody3D
## سور دفاعي قابل للتدمير. يقرأ مضاعف الصحة من ترقيات الجولة.

@export var max_health: int = 100

var current_health: int = 100

var _base_max_health: int = 100
var _director: Node = null

func _ready() -> void:
	add_to_group("buildings")
	_base_max_health = max_health
	_director = get_tree().get_first_node_in_group("roguelite_director")
	apply_run_stats()
	current_health = max_health

func apply_run_stats() -> void:
	if _director == null or not is_instance_valid(_director):
		_director = get_tree().get_first_node_in_group("roguelite_director")
	if _director == null or not _director.has_method("get_run_stats"):
		return
	var stats: RunStats = _director.get_run_stats() as RunStats
	if stats == null:
		return
	max_health = stats.scaled_wall_health(_base_max_health)
	current_health = mini(current_health, max_health)

func take_damage(amount: int) -> void:
	current_health -= maxi(0, amount)
	if current_health <= 0:
		queue_free()

func get_health_ratio() -> float:
	return float(maxi(0, current_health)) / float(maxi(1, max_health))
