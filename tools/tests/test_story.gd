extends SceneTree
## Headless run through chapter 1 (scripts/systems/quests.gd): every stage in order, talking to the
## right people (the first choice in every question), the Madre de la manada waiting at the rift and
## the rift's plaque when she falls, Caldus showing up only for the remains, and the chapter's end.
## Also a merchant's shop and the Patio de pruebas calling creatures.
##   godot --headless --path . --script res://tools/tests/test_story.gd

var _failures := 0
var _quests: Node
var _progress: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_progress = root.get_node("Progress")
	_quests = root.get_node("Quests")
	_progress.save_enabled = false
	_progress.new_game()
	await _load("res://scenes/levels/brumaclara.tscn")
	var town := current_scene
	_check(not town.get_node("People/Caldus").visible, "Caldus is not in town before the remains")
	await _talk("Mara")
	_check(_quests.stage() == 1, "Mara gives the first job")
	await _talk("Carter")
	_check(_quests.stage() == 2 and _progress.count(&"caja") == 1, "the carter hands over the box")
	await _talk("Elia")  # first choice: she looks at it
	_check(_quests.flag("elia_inspected", false), "Elia can look at the box")
	var coins: int = _progress.count(&"monedas")
	await _talk("Tovan")
	_check(_quests.stage() == 3 and _progress.count(&"caja") == 0 and _progress.count(&"monedas") > coins,
			"Tovan takes the box and pays (%s)" % _quests.flag("supply_box_choice"))
	await _talk("Mara")
	_check(_quests.stage() == 4, "Mara sends the hero to the rift")

	await _load("res://scenes/levels/afueras.tscn")
	var mother: Node = current_scene.get_node_or_null("Enemies/MadreDeLaManada")
	_check(mother != null, "the Madre de la manada waits at the rift")
	if mother:
		mother.get_node("Health").current = 1
		mother.get_node("Health").damage(5)
		for i in 10:
			await physics_frame
	_check(_quests.stage() == 5 and _progress.count(&"placa") == 1, "her fall leaves the plaque (stage %d)" % _quests.stage())

	await _load("res://scenes/levels/brumaclara.tscn")
	await _talk("Mara")
	_check(_quests.stage() == 6, "Mara sends the hero to Iven")
	await _talk("Iven")
	_check(_quests.stage() == 7 and _quests.flag("iven_relationship") == "respect", "Iven's welcome")
	_check(current_scene.get_node("People/Caldus").visible, "Caldus comes for the remains")
	await _talk("Caldus")
	for i in 120:  # the closing: the bell, Mara's last lines
		await process_frame
		_close_boxes()
	_check(_quests.stage() == 8 and _progress.count(&"insignia") == 1, "the chapter ends with rank zero (stage %d)" % _quests.stage())
	_check(root.get_node("DayNight").night() > 0.9, "night falls on the town at the end")

	# a merchant
	_progress.add_item(&"monedas", 100)
	var shop: Control = load("res://scripts/ui/shop_menu.gd").new()  # (the class needs the autoloads: loaded late)
	shop.seller = "Lio"
	shop.goods = {"pocion": 15}
	current_scene.get_node("HUD").add_child(shop)
	var potions: int = _progress.count(&"pocion")
	coins = _progress.count(&"monedas")
	_check(shop.buy() and _progress.count(&"pocion") == potions + 1 and _progress.count(&"monedas") == coins - 15, "buying a potion")
	shop.queue_free()
	paused = false

	# the arena
	await _load("res://scenes/levels/arena.tscn")
	var arena := current_scene
	var groups: Array = arena.roster()
	_check(groups.size() >= 4, "the arena's board lists the bestiary by zone")
	arena.call_enemy(load("res://data/enemies/roedor_bruma.tres"), 3)
	await _frames(5)
	_check(arena.get_node("Enemies").get_children().filter(func(n: Node) -> bool: return n is CharacterBody3D).size() == 3,
			"choosing a creature brings three of them")
	arena.clear_enemies()
	await _frames(3)
	_check(arena.get_node("Enemies").get_children().filter(func(n: Node) -> bool: return n is CharacterBody3D).is_empty(),
			"the arena can be cleared")

	print("story checks: %s" % ("all passed" if _failures == 0 else "%d FAILED" % _failures))
	quit(1 if _failures else 0)


## Talks to a person of the current scene and answers every box with its first option.
func _talk(who: String) -> void:
	var npc: Node = current_scene.get_node("People/" + who)
	var done := [false]
	var talk := func() -> void:
		await _quests.talk(who, npc)
		done[0] = true
	talk.call()
	for i in 400:
		if done[0]:
			break
		_close_boxes()
		await process_frame
	await _frames(2)


func _close_boxes() -> void:
	var hud := current_scene.get_node_or_null("HUD") if current_scene else null
	if hud == null:
		return
	for child in hud.get_children():
		if child is Dialogue and not child.is_queued_for_deletion():
			child._shown = 9999.0
			child._advance()


func _load(path: String) -> void:
	change_scene_to_file(path)
	for i in 600:
		if current_scene and current_scene.scene_file_path == path:
			break
		await process_frame
	await _frames(4)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failures += 1
