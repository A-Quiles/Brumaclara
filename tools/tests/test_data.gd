extends SceneTree
## Headless checks that skills and enemies take their numbers from their data files
## (data/trees, data/enemies): change a file, the game changes.
## Run: godot --headless --path . --script res://tools/tests/test_data.gd

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var progress: Node = root.get_node("Progress")
	progress.save_enabled = false
	progress.new_game()
	progress.choose_principal(&"fuego")
	var level: Node = load("res://scenes/levels/afueras.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	var hero: Node = level.get_node("Player")
	_check(progress.equipped[0] == &"fuego.chispa" and progress.equipped[1] == &"fuego.estallido",
			"the hero starts with the first skills of the affinity chosen (Q and E)")

	# a cheaper, stronger Chispa: the cast must follow the numbers of its tree node
	var node: Dictionary = progress.nodes[&"fuego.chispa"]
	var original: Dictionary = node.skill.duplicate()
	node.skill.mana_cost = 3
	node.skill.damage = 77
	progress.learned.append(&"tronco.filo_templado")  # any change clears the cache
	progress.learned.erase(&"tronco.filo_templado")
	progress._invalidate()
	hero.mp_regen = 0.0  # so the mana spent is exact
	var mp_before: float = hero.mp
	Input.action_press("skill_1")
	await physics_frame
	Input.action_release("skill_1")
	var bolt: Hitbox = null
	for i in 30:
		await physics_frame
		for n in level.get_children():
			if n is Hitbox and n.scene_file_path.ends_with("fire_bolt.tscn"):
				bolt = n
		if bolt:
			break
	_check(is_equal_approx(mp_before - hero.mp, 3.0), "casting spends the file's mana cost (%.2f)" % (mp_before - hero.mp))
	_check(bolt != null and bolt.damage == 77, "the bolt hits for the file's damage")
	node.skill = original
	progress._invalidate()

	var wolf_data: EnemyData = load("res://data/enemies/wolf.tres").duplicate()
	wolf_data.max_hp = 123
	wolf_data.damage = 21
	var wolf: Node = load("res://scenes/characters/enemies/wolf.tscn").instantiate()
	wolf.data = wolf_data
	level.add_child(wolf)
	await physics_frame
	_check(wolf.get_node("Health").maximum == 123 and wolf.get_node("Health").current == 123, "the wolf's health comes from its file")
	_check(wolf.get_node("Bite").damage == 21, "the wolf's bite comes from its file")

	# every enemy file loads with its sheet and a sane fiche
	var count := 0
	for f in DirAccess.get_files_at("res://data/enemies"):
		if f.ends_with(".tres"):
			var d: EnemyData = load("res://data/enemies/" + f)
			count += 1
			_check(d != null and d.max_hp > 0 and d.display_name != "", "enemy file %s is complete" % f)
	_check(count >= 11, "at least 11 enemy files (%d)" % count)

	print("data checks: %s" % ("all passed" if _failures == 0 else "%d FAILED" % _failures))
	quit(1 if _failures else 0)


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failures += 1
