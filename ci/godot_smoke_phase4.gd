extends SceneTree

func _fail(message: String) -> void:
	push_error("PHASE4_SMOKE_FAIL: " + message)
	quit(1)

func _check(condition: bool, message: String) -> bool:
	if not condition:
		_fail(message)
		return false
	return true

func _init() -> void:
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if not _check(main_scene != null, "Main.tscn failed to load"):
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame

	var player := main.get_node("Player")
	var manager := main.get_node("BuildingManager")
	var day_night := main.get_node("DayNightManager")
	var spawner := main.get_node("WaveSpawner")
	var director := main.get_node_or_null("GameplayDirector")
	var castle_controller := main.get_node_or_null("CastleCore/CastleController")
	if not _check(player != null and manager != null and day_night != null and spawner != null and director != null, "Phase 4 managers missing"):
		return
	if not _check(day_night.is_night == false and day_night.current_day == 1, "Game must start during day 1"):
		return
	if not _check(is_equal_approx(day_night.day_duration, 60.0) and is_equal_approx(day_night.night_duration, 40.0), "Cycle durations must be 60s day and 40s night"):
		return
	if not _check(castle_controller != null and castle_controller.has_method("get_health_ratio"), "Castle controller missing"):
		return

	var enemy_scene := load("res://scenes/enemy.tscn") as PackedScene
	var projectile_scene := load("res://scenes/projectile.tscn") as PackedScene
	if not _check(enemy_scene != null and projectile_scene != null, "Enemy or projectile scene missing"):
		return
	if not _check(load("res://assets/characters/Skeleton_Warrior.glb") != null, "Premium KayKit skeleton asset missing"):
		return

	var enemy := enemy_scene.instantiate()
	if not _check(enemy.get_node_or_null("NavigationAgent3D") != null, "Enemy NavigationAgent3D missing"):
		return
	main.add_child(enemy)
	enemy.global_position = Vector3(5.0, 0.9, 0.0)
	await process_frame
	await process_frame
	if not _check(enemy.is_in_group("enemy"), "Enemy group registration missing"):
		return
	if not _check(enemy.get_node_or_null("PremiumSkeleton") != null, "Premium enemy visual was not attached"):
		return

	# King combat: put enemy in melee range and let the polish director strike it.
	enemy.max_health = 32
	enemy.current_health = 32
	enemy.global_position = player.global_position + Vector3(1.2, 0.0, 0.0)
	director._on_attack_pressed()
	await process_frame
	if not _check(not is_instance_valid(enemy) or enemy.current_health < 32, "King attack must damage a nearby enemy"):
		return

	# Tower combat: place a tower in range and use a low-health enemy for a deterministic hit.
	if is_instance_valid(enemy):
		enemy.queue_free()
	var tower_scene := load("res://scenes/buildings/Tower.tscn") as PackedScene
	var tower := tower_scene.instantiate()
	main.get_node("BuildingManager/BuildingsContainer").add_child(tower)
	tower.global_position = Vector3(0.0, 0.0, 0.0)
	var tower_enemy := enemy_scene.instantiate()
	main.add_child(tower_enemy)
	tower_enemy.global_position = Vector3(4.0, 0.9, 0.0)
	tower_enemy.max_health = 18
	tower_enemy.current_health = 18
	await process_frame
	await create_timer(0.5).timeout
	if not _check(not is_instance_valid(tower_enemy) or tower_enemy.current_health < 18, "Tower must damage an enemy with a projectile"):
		return

	if is_instance_valid(tower_enemy):
		tower_enemy.queue_free()
	# Castle health pipeline.
	var castle_before: int = castle_controller.current_health
	castle_controller.take_damage(25)
	if not _check(castle_controller.current_health == castle_before - 25, "Castle must take damage"):
		return

	# Deterministic cycle/wave check with shortened timers for CI.
	day_night.day_duration = 0.05
	day_night.night_duration = 0.05
	spawner.base_enemies = 1
	spawner.enemies_per_day = 0
	spawner.spawn_interval = 0.01
	await create_timer(0.15).timeout
	if not _check(day_night.is_night, "Night must start automatically after day duration"):
		return
	await create_timer(0.15).timeout
	var enemies := get_nodes_in_group("enemy")
	if not _check(not enemies.is_empty(), "Wave spawner must create an enemy at night"):
		return
	for e in enemies:
		if is_instance_valid(e):
			e.take_damage(999)
	await create_timer(0.22).timeout
	if not _check(day_night.current_day >= 2 and not day_night.is_night, "Night must end and advance to day 2 after enemies are cleared"):
		return

	print("PHASE4_SMOKE_PASS")
	quit(0)
