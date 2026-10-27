extends SceneTree
## Headless checks of the enemies' attack kinds: a lunge (the wolf's), a slam around itself (burst) and
## a fan of shots (volley) all reach the hero after their warning.
## Run: godot --headless --fixed-fps 60 --path . --script res://tools/tests/test_enemy_attacks.gd

var _failures := 0
var _hero: CharacterBody3D
var _level: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var progress: Node = root.get_node("Progress")
	progress.save_enabled = false
	progress.new_game()
	_level = load("res://scenes/levels/afueras.tscn").instantiate()
	root.add_child(_level)
	_hero = _level.get_node("Player")
	var enemies := _level.get_node("Enemies").get_children()
	for e in enemies:
		if e.data.resource_path.get_file() not in ["guardian_raices.tres", "sporineo.tres"]:
			e.queue_free()
	await _frames(2)
	for e in _level.get_node("Enemies").get_children():
		e.set_physics_process(false)
	for kind_file in [["burst", "guardian_raices.tres", 1.8], ["volley", "sporineo.tres", 4.5]]:
		var enemy: Node3D = null
		for e in _level.get_node("Enemies").get_children():
			if not e.is_queued_for_deletion() and e.data.resource_path.get_file() == kind_file[1]:
				enemy = e
				break
		_check(enemy != null and enemy.data.attack_kind == kind_file[0], "%s has the %s attack" % [kind_file[1], kind_file[0]])
		if enemy == null:
			continue
		_hero.get_node("Health").heal(9999)
		_hero.global_position = Vector3(0, 0.1, 4)
		enemy.global_position = Vector3(kind_file[2], 0.1, 4)
		enemy.set("_home", enemy.global_position)
		enemy.set_physics_process(true)
		var before: int = _hero.get_node("Health").current
		var hit := false
		for i in 240:
			await physics_frame
			if _hero.get_node("Health").current < before:
				hit = true
				break
		_check(hit, "the %s reaches the hero (hp %d -> %d)" % [kind_file[0], before, _hero.get_node("Health").current])
		enemy.set_physics_process(false)
		enemy.global_position = Vector3(40, 0.1, 40)
		await _frames(90)  # the hero's invulnerability wears off
	print("enemy attack checks: %s" % ("all passed" if _failures == 0 else "%d FAILED" % _failures))
	quit(1 if _failures else 0)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failures += 1
