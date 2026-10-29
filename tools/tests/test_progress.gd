extends SceneTree
## Headless checks of the point system and the skill trees (docs/arbol_habilidades.md): levels give
## PA and attribute points, tiers open with the PA spent, secondary affinities stop at tier III,
## respec gives everything back, and the saved game comes back as it was.
## Run: godot --headless --path . --script res://tools/tests/test_progress.gd

var _failures := 0
var _p: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_p = root.get_node("Progress")
	_p.save_enabled = false
	_p.new_game()

	# the trees: every file loads and every node is well formed
	var types := {}
	var total := 0
	for tree in _p.TREE_IDS:
		var nodes: Array = _p.trees[tree].nodes
		total += nodes.size()
		for n: Dictionary in nodes:
			types[n.type] = true
			var ok: bool = n.has("id") and n.has("tier") and n.has("cost") and n.tier >= 1 and n.tier <= 5
			if n.type in ["activa", "definitiva"] and n.get("implemented", true):
				ok = ok and n.has("skill") and _p.skill(StringName(n.id)) != null
			if not ok:
				_check(false, "node %s is well formed" % n.get("id", "?"))
	_check(total >= 150, "the trees hold %d nodes" % total)
	_check(types.has("activa") and types.has("pasiva") and types.has("definitiva"), "all three node types exist")

	# items are counted, never go below zero and a new game empties the bag
	_p.add_item(&"pocion_bruma", 2)
	_p.add_item(&"pocion_bruma", -1)
	_check(_p.items.get(&"pocion_bruma", 0) == 1, "items are added and used up")
	_p.add_item(&"pocion_bruma", -1)
	_check(not _p.items.has(&"pocion_bruma"), "an empty stack disappears")

	# levels give points
	_check(_p.level == 1 and _p.pa == 0, "a new game starts at level 1 with no PA")
	var gained: int = _p.gain_xp(60)
	_check(gained == 1 and _p.level == 2 and _p.pa == 2 and _p.attr_points == 1, "level 2: +2 PA, +1 attribute point")
	_p.gain_xp(100000)
	_check(_p.level == _p.MAX_LEVEL, "the level stops at %d" % _p.MAX_LEVEL)
	_check(_p.pa == 2 * (_p.MAX_LEVEL - 1), "PA from levels: %d" % _p.pa)

	# the affinity comes from the shrine; the tree of another one is shut
	_check(_p.can_learn(&"fuego.chispa") != "", "nothing in an affinity tree before choosing one")
	_p.choose_principal(&"fuego")
	_check(&"fuego.chispa" in _p.learned and _p.equipped[0] == &"fuego.chispa", "the principal affinity gives its first skills")
	var shut := 0
	for n: Dictionary in _p.trees[&"hielo"].nodes:
		if _p.can_learn(StringName(n.id)) != "":
			shut += 1
	_check(shut == _p.trees[&"hielo"].nodes.size(), "every node of an unawakened affinity is locked")

	# tiers open with the PA invested in the tree: the two starting skills (4 PA) open tier II at once
	_check(_p.can_learn(&"fuego.lanza_de_fuego") == "" or _p.can_learn(&"fuego.lanza_de_fuego") == "Requiere «Chispa doble»",
			"tier II of the principal affinity is open from the start")
	_check(_p.can_learn(&"fuego.cometa").begins_with("Gasta"), "tier IV needs more PA invested first")
	var learned_any := 0
	for n: Dictionary in _p.trees[&"tronco"].nodes:
		if n.tier == 1 and _p.can_learn(StringName(n.id)) == "":
			_p.learn(StringName(n.id))
			learned_any += 1
	_check(learned_any > 0 and _p.spent_in(&"tronco") > 0, "tier I nodes of the common trunk can be learned")

	# secondary affinities need a level and stop at tier III
	_check(_p.secondary_allowed() == 2, "at level 40 both secondary affinities are allowed")
	_p.awaken(&"hielo")
	_check(_p.tree_access(&"hielo") == 3 and _p.tree_access(&"fuego") == 5, "secondary: tier III, principal: tier V")
	var capped := false
	for n: Dictionary in _p.trees[&"hielo"].nodes:
		if n.tier >= 4 and _p.can_learn(StringName(n.id)) != "":
			capped = true
	_check(capped, "tiers IV and V of a secondary affinity stay shut")

	# learn everything that can be learned in order: PA never goes negative, the ultimate needs 3 high nodes
	_p.pa += 300  # (the whole of three trees costs more than one playthrough gives)
	var guard := 0
	while guard < 400:
		guard += 1
		var progressed := false
		for tree in [&"fuego", &"tronco", &"hielo"]:
			for n: Dictionary in _p.trees[tree].nodes:
				if _p.can_learn(StringName(n.id)) == "":
					_p.learn(StringName(n.id))
					progressed = true
		if not progressed:
			break
	_check(_p.pa >= 0, "PA never goes negative (%d left)" % _p.pa)
	var ult: Array = _p.trees[&"fuego"].nodes.filter(func(n: Dictionary) -> bool: return n.type == "definitiva" and n.get("implemented", true))
	_check(ult.size() > 0 and StringName(ult[0].id) in _p.learned and _p.ultimate != &"", "the fire ultimate is learned and equipped at last")

	# attributes
	_p.add_attr("poder")
	_check(_p.attr("poder") == 1, "an attribute point goes into Poder")
	_check(_p.max_hp() > 100, "maximum health grows with the level (%d)" % _p.max_hp())

	# saving and loading
	_p.save_enabled = true
	_p.save_game()
	var before := [_p.level, _p.pa, _p.learned.size(), _p.principal, _p.awakened.size()]
	_p.level = 1
	_p.pa = 0
	_p.learned.clear()
	_p.principal = &""
	_p.awakened.clear()
	_p.load_game()
	_check([_p.level, _p.pa, _p.learned.size(), _p.principal, _p.awakened.size()] == before, "the saved game comes back as it was")

	# respec gives the PA back and keeps the starting skills
	var spent: int = _p.pa
	_p.respec()
	_check(_p.pa > spent and &"fuego.chispa" in _p.learned and _p.attr_points >= 1, "respec gives the points back and keeps the starting skills")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_p.FILE))
	_p.save_enabled = false

	print("progress checks: %s" % ("all passed" if _failures == 0 else "%d FAILED" % _failures))
	quit(1 if _failures else 0)


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failures += 1
