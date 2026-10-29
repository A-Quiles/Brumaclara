extends SceneTree
## Headless checks of the interiors: the doors of the town lead inside, the hero arrives by the
## door, and walking out through the door brings it back to the town in front of the building.
## Run: godot --headless --fixed-fps 60 --path . --script res://tools/tests/test_interiors.gd

const ROOMS := {"Posada": "posada", "SedeDelFaro": "sede_faro", "TiendaDeNara": "tienda_nara", "CasaDeElia": "taller_elia"}

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.get_node("Progress").save_enabled = false
	for building in ROOMS:
		change_scene_to_file("res://scenes/levels/brumaclara.tscn")
		await _frames(5)
		var town := current_scene
		var door: Area3D = town.get_node("Buildings/%s/Puerta" % building)
		var hero: Node3D = town.get_node("Player")
		hero.global_position = door.global_position + Vector3(0, 0.3, 0)
		for i in 120:  # the hero walks in and the screen fades out first (Transition)
			await physics_frame
			if current_scene != town:
				break
		await _frames(5)
		var room := ROOMS[building] as String
		_check(current_scene != null and current_scene.scene_file_path.ends_with("/%s.tscn" % room),
				"the door of %s leads into %s" % [building, room])
		if current_scene == null or not current_scene.scene_file_path.ends_with("/%s.tscn" % room):
			continue
		hero = current_scene.get_node("Player")
		var exit: Area3D = current_scene.get_node("Exit")
		_check(hero.global_position.z < exit.global_position.z - 1.5, "the hero arrives inside by the door")
		var inside := current_scene
		Input.action_press("move_down")
		for i in 240:
			await physics_frame
			if current_scene != inside:
				break
		Input.action_release("move_down")
		await _frames(5)
		_check(current_scene.scene_file_path.ends_with("brumaclara.tscn"), "walking out of %s goes back to the town" % room)
		var back: Node3D = current_scene.get_node("Player")
		var front: Vector3 = current_scene.get_node("Buildings/%s/Puerta" % building).global_position
		_check(Vector2(back.global_position.x - front.x, back.global_position.z - front.z).length() < 3.5,
				"the hero comes out in front of %s's door" % building)
	# walking up to a door from the street is enough to go in
	change_scene_to_file("res://scenes/levels/brumaclara.tscn")
	await _frames(5)
	var street: Node = current_scene
	var hero_on_street: Node3D = street.get_node("Player")
	var inn_door: Vector3 = street.get_node("Buildings/Posada/Puerta").global_position
	hero_on_street.global_position = inn_door + Vector3(0, 0.3, 1.9)  # the street in front of the inn is narrow
	await _frames(5)
	Input.action_press("move_up")
	for i in 240:
		await physics_frame
		if current_scene != street:
			break
	Input.action_release("move_up")
	await _frames(3)
	_check(current_scene.scene_file_path.ends_with("/posada.tscn"), "walking up the street into the inn's door goes in")
	print("interior checks: %s" % ("all passed" if _failures == 0 else "%d FAILED" % _failures))
	quit(1 if _failures else 0)


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failures += 1
