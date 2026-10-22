extends SceneTree
## Headless checks of the town: people answer the interact key, and the west exit takes the hero to
## the outskirts, arriving where it should. Run: godot --headless --path . --script res://tools/tests/test_town.gd

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file("res://scenes/levels/brumaclara.tscn")
	await _frames(3)
	var town := current_scene
	var hero: Node3D = town.get_node("Player")
	var mara: Node3D = town.get_node("People/Mara")
	var message: Label = town.get_node("HUD").get_node("%Message")
	hero.global_position = mara.global_position + Vector3(0, 0.3, 1.0)
	await _frames(5)
	Input.action_press("interact")
	await _frames(2)
	Input.action_release("interact")
	await _frames(2)
	_check(message.text.begins_with("Soy Mara Venn"), "Mara answers the interact key (%s)" % message.text)

	hero.global_position = Vector3(-37.8, 0, 29.0)
	await _frames(20)
	_check(current_scene and current_scene.scene_file_path.ends_with("demo_zone.tscn"), "the west exit leads to the outskirts")
	if current_scene:
		var arrived: Node3D = current_scene.get_node("Player")
		_check(arrived.global_position.distance_to(Vector3(-21.0, 0, -0.4)) < 1.0, "the hero arrives by the west road")
	print("town checks: %s" % ("all passed" if _failures == 0 else "%d FAILED" % _failures))
	quit(1 if _failures else 0)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failures += 1
