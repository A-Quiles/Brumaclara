extends SceneTree
## Headless checks of the town: people answer the interact key in the dialogue box (Mara with the
## story's first job), and the west exit takes the hero to the outskirts, arriving where it should. Run: godot --headless --path . --script res://tools/tests/test_town.gd

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.get_node("Progress").save_enabled = false
	root.get_node("Progress").new_game()
	change_scene_to_file("res://scenes/levels/brumaclara.tscn")
	await _scene("brumaclara.tscn")
	await _frames(3)
	var town := current_scene
	var hero: Node3D = town.get_node("Player")
	var mara: Node3D = town.get_node("People/Mara")
	var hud: Node = town.get_node("HUD")
	hero.global_position = mara.global_position + Vector3(0, 0.3, 1.0)
	await _frames(5)
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(2)
	var box := _box(hud)
	_check(box != null and box.speaker == "Mara Venn" and box.lines[0].begins_with("¿Rango cero"),
			"Mara answers the interact key with the first job (%s)" % (box.lines[0].left(30) if box else "no box"))
	await _close(box)
	_check(root.get_node("Quests").stage() == 1, "talking to Mara starts the story (stage %d)" % root.get_node("Quests").stage())
	# the people of the story placed around the town answer too, with their first line
	for who in ["Neris", "Tovan", "Rhea"]:
		var person := town.get_node_or_null("People/" + who) as Node3D
		if person == null:
			continue
		hero.global_position = person.global_position + Vector3(0, 0.3, 1.0)
		await _frames(5)
		Input.action_press("interact")
		await _frames(2)
		Input.action_release("interact")
		await _frames(2)
		var first: String = person.get("lines")[0]
		box = _box(hud)
		_check(box != null and box.lines[0] == first, "%s answers the interact key (%s)" % [who, box.lines[0].left(40) if box else "no box"])
		await _close(box)

	hero.global_position = Vector3(-37.8, 0, 29.0)
	await _scene("afueras.tscn")
	await _frames(3)
	_check(current_scene and current_scene.scene_file_path.ends_with("afueras.tscn"), "the west exit leads to the outskirts")
	if current_scene:
		var arrived: Node3D = current_scene.get_node("Player")
		_check(arrived.global_position.distance_to(Vector3(-21.0, 0, -0.4)) < 1.0, "the hero arrives by the west road")
	print("town checks: %s" % ("all passed" if _failures == 0 else "%d FAILED" % _failures))
	quit(1 if _failures else 0)


func _box(hud: Node) -> Dialogue:
	for child in hud.get_children():
		if child is Dialogue:
			return child
	return null


## Presses F until the dialogue box is gone.
func _close(box: Dialogue) -> void:
	for i in 20:
		if box == null or not is_instance_valid(box):
			break
		box._advance()
		await _frames(1)
	await _frames(4)


## Waits (up to a few seconds) until the current scene is `file_name`.
func _scene(file_name: String) -> void:
	for i in 600:
		if current_scene and current_scene.scene_file_path.ends_with(file_name):
			return
		await process_frame


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failures += 1
