extends SceneTree
## Headless checks that skills and enemies take their numbers from their data files
## (data/skills, data/enemies): change a file, the game changes.
## Run: godot --headless --path . --script res://tools/tests/test_data.gd

var _failures := 0


func _initialize() -> void:
	var level: Node = load("res://scenes/levels/afueras.tscn").instantiate()
	root.add_child(level)
	await physics_frame
	var hero: Node = level.get_node("Player")
	var chispa: SkillData = load("res://data/skills/chispa.tres")
	_check(hero.skills.size() == 2 and hero.skills[0] == chispa, "the hero carries Chispa (Q) and Estallido (E)")

	# a cheaper, stronger copy of Chispa: the cast must follow the copy's numbers
	var test_skill: SkillData = chispa.duplicate()
	test_skill.mana_cost = 3.0
	test_skill.damage = 77
	hero.skills[0] = test_skill
	hero.mp_regen = 0.0  # so the mana spent is exact
	var mp_before: float = hero.mp
	Input.action_press("skill_1")
	await physics_frame
	Input.action_release("skill_1")
	var bolt: Hitbox = null
	for i in 20:
		await physics_frame
		for node in level.get_children():
			if node is Hitbox and node.scene_file_path.ends_with("fire_bolt.tscn"):
				bolt = node
		if bolt:
			break
	_check(is_equal_approx(mp_before - hero.mp, 3.0), "casting spends the file's mana cost (%.2f)" % (mp_before - hero.mp))
	_check(bolt != null and bolt.damage == 77, "the bolt hits for the file's damage")

	var wolf_data: EnemyData = load("res://data/enemies/wolf.tres").duplicate()
	wolf_data.max_hp = 123
	wolf_data.damage = 21
	var wolf: Node = load("res://scenes/characters/enemies/wolf.tscn").instantiate()
	wolf.data = wolf_data
	level.add_child(wolf)
	await physics_frame
	_check(wolf.get_node("Health").maximum == 123 and wolf.get_node("Health").current == 123, "the wolf's health comes from its file")
	_check(wolf.get_node("Bite").damage == 21, "the wolf's bite comes from its file")

	print("data checks: %s" % ("all passed" if _failures == 0 else "%d FAILED" % _failures))
	quit(1 if _failures else 0)


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failures += 1
