extends SceneTree
## Headless checks of the demo's combat loop (sword, Chispa, Estallido, dodge, wolf pounce, death
## rewards) and of the hidden chest. Run: godot --headless --path . --script res://tools/tests/test_combat.gd

var _failures := 0
var _hero: CharacterBody3D
var _wolf: CharacterBody3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level: Node = load("res://scenes/levels/demo_zone.tscn").instantiate()
	root.add_child(level)
	_hero = level.get_node("Player")
	var wolves := level.get_node("Enemies").get_children()
	_wolf = wolves[0]
	for other in wolves.slice(1):
		other.queue_free()
	await _frames(2)

	# Estallido spends mana and hurts a wolf standing next to the hero
	_place(Vector3(0, 0, 4), Vector3(1.6, 0, 4))
	var mp_before: float = _hero.mp
	await _press("skill_2", 40)
	_check(_hero.mp < mp_before - 20.0, "Estallido costs mana")
	_check(_wolf_hp() < 40, "Estallido hurts a wolf in range (hp %d)" % _wolf_hp())

	# Chispa flies to a wolf a few steps away
	await _frames(240)  # cooldowns and the wolf's stagger wear off
	_heal_all()
	_place(Vector3(0, 0, 4), Vector3(4.0, 0, 4))
	_hero.set("_facing", Vector2.RIGHT)
	await _press("skill_1", 30)
	_check(_wolf_hp() < 40, "Chispa reaches a wolf (hp %d)" % _wolf_hp())

	# the sword hits a wolf in front of the hero
	_heal_all()
	_place(Vector3(0, 0, 4), Vector3(1.3, 0, 4))
	_hero.set("_facing", Vector2.RIGHT)
	await _press("attack", 25)
	_check(_wolf_hp() < 40, "the sword hits (hp %d)" % _wolf_hp())

	# a wolf that reaches the hero bites; a dodge at the right time avoids it
	_heal_all()
	_place(Vector3(0, 0, 4), Vector3(3.0, 0, 4))
	var hp_before := _hero_hp()
	await _frames(90)
	_check(_hero_hp() < hp_before, "the wolf's pounce bites (hero hp %d)" % _hero_hp())
	await _frames(120)  # invulnerability after the bite wears off
	_heal_all()
	_place(Vector3(0, 0, 4), Vector3(3.0, 0, 4))
	hp_before = _hero_hp()
	for i in 120:  # dodge away the moment the wolf starts its pounce
		await physics_frame
		if _wolf.get("_state") == 3:  # POUNCE
			Input.action_press("move_left")
			await _press("dodge", 2)
			Input.action_release("move_left")
			break
	await _frames(30)
	_check(_hero_hp() == hp_before, "a dodge avoids the pounce (hero hp %d)" % _hero_hp())

	# a defeated wolf drops experience that the hero picks up
	_place(Vector3(0, 0, 4), Vector3(1.3, 0, 4))
	var xp_before: int = _hero.xp
	var level_before: int = _hero.level
	_wolf.get_node("Health").damage(_wolf_hp())
	await _frames(150)
	_hero.global_position = _wolf.global_position + Vector3(0, 0, 0.3)
	await _frames(30)
	_check(_hero.xp != xp_before or _hero.level > level_before, "the wolf's orb gives experience")

	# the hidden chest opens with the interact key and its orbs give experience
	var chest: Node3D = level.get_node("Props/Chest")
	_hero.global_position = chest.global_position + Vector3(0, 0, 1.2)
	xp_before = _hero.xp
	level_before = _hero.level
	await _frames(5)
	await _press("interact", 90)
	_check(chest.get("_opened"), "the chest opens with the interact key")
	_check(_hero.xp != xp_before or _hero.level > level_before, "the chest's orbs give experience")

	print("combat checks: %s" % ("all passed" if _failures == 0 else "%d FAILED" % _failures))
	quit(1 if _failures else 0)


func _place(hero_at: Vector3, wolf_at: Vector3) -> void:
	_hero.global_position = hero_at
	_hero.velocity = Vector3.ZERO
	_wolf.global_position = wolf_at
	_wolf.velocity = Vector3.ZERO


func _heal_all() -> void:
	_hero.get_node("Health").heal(999)
	_hero.mp = _hero.max_mp
	var health: Health = _wolf.get_node("Health")
	health.heal(health.maximum)


func _hero_hp() -> int:
	return _hero.get_node("Health").current


func _wolf_hp() -> int:
	return _wolf.get_node("Health").current


func _press(action: String, frames: int) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)
	await _frames(frames)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failures += 1
