extends SceneTree
## Casts every skill of every tree (alone, then with every passive learned) in front of an enemy and
## checks that nothing breaks and that the damaging ones do hurt. Run:
## godot --headless --path . --script res://tools/tests/test_skills.gd   (look for SCRIPT ERROR too)

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var p: Node = root.get_node("Progress")
	p.save_enabled = false
	p.new_game()
	p.gain_xp(100000)
	p.choose_principal(&"fuego")
	var level: Node = load("res://scenes/levels/afueras.tscn").instantiate()
	root.add_child(level)
	var hero: CharacterBody3D = level.get_node("Player")
	var wolves := level.get_node("Enemies").get_children()
	var wolf: CharacterBody3D = wolves[0]
	for other in wolves.slice(1):
		other.queue_free()
	wolf.data = wolf.data.duplicate()
	wolf.data.max_hp = 100000
	wolf.get_node("Health").maximum = 100000
	wolf.get_node("Health").heal(100000)
	wolf.set_physics_process(false)  # a punching bag
	await _frames(3)

	var cast := 0
	var hurt := 0
	var silent: Array[String] = []
	for round in 2:
		if round == 1:  # every passive learned: the stat code runs too
			for id in p.nodes:
				if id not in p.learned and p.nodes[id].get("implemented", true) != false:
					p.learned.append(id)
			p._invalidate()
			p.changed.emit()
		for id: StringName in p.nodes:
			var n: Dictionary = p.nodes[id]
			if n.type not in ["activa", "definitiva"] or n.get("implemented", true) == false:
				continue
			if round == 0:
				if id not in p.learned:
					p.learned.append(id)
				p._invalidate()
			hero.global_position = Vector3(0, 0, 4)
			hero.velocity = Vector3.ZERO
			wolf.global_position = hero.global_position + View.RIGHT * 2.2
			hero.set("_facing", Vector2.RIGHT)
			hero.set("_state", 0)
			hero.mp = 999.0
			hero.get("_cooldowns").clear()
			var health: Health = wolf.get_node("Health")
			health.heal(100000)
			wolf.get_node("Status")._active.clear()
			for mark in [&"marca_sombra", &"marca_electrica", &"fisura"]:  # some skills need a mark (none burns it)
				wolf.get_node("Status")._active[mark] = {"stacks": 1, "left": 9.0}
			var before := health.current
			hero.call("_try_cast", id)
			await _frames(70 + int(p.skill(id).delay * 60.0))
			cast += 1
			if health.current < before:
				hurt += 1
			elif p.skill(id).damage > 0:
				silent.append(String(id))
			elif p.skill(id).damage == 0:
				hurt += 1  # support skills (buffs, shields, heals) have nothing to hurt
			hero.get("_health").heal(9999)
	_check(cast >= 90, "%d skills cast without breaking the game" % cast)
	_check(hurt >= cast * 0.7, "%d of %d skills hurt the dummy" % [hurt, cast])
	print("  (did not hurt it: %s)" % ", ".join(silent))
	print("skill checks: %s" % ("all passed" if _failures == 0 else "%d FAILED" % _failures))
	quit(1 if _failures else 0)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failures += 1
