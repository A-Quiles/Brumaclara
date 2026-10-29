extends SceneTree
## Checks the see-through buildings in the town: a building fades while it hides the hero completely
## (hero just behind its middle) and stays opaque while it hides only part of the hero (hero at its
## side edge, half in view).
##   godot --headless --path . --script res://tools/tests/test_occlusion.gd

var _failed := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.get_node("Progress").save_enabled = false
	change_scene_to_file("res://scenes/levels/brumaclara.tscn")
	for i in 600:
		if current_scene and current_scene.scene_file_path.ends_with("brumaclara.tscn"):
			break
		await process_frame
	for i in 3:
		await physics_frame
	var hero: Node3D = current_scene.get_node("Player")
	var fader: Node = hero.get_node("Camera")
	var behind := 0
	var edge_faded := 0
	var count := 0
	for b in get_nodes_in_group("occluder"):
		var box := _box(b)
		if box.size.x < 3.0:
			continue
		count += 1
		var mid_x := box.position.x + box.size.x / 2.0
		hero.global_position = _ground(Vector3(mid_x, 0, box.position.z - 0.6))
		for i in 10:
			await physics_frame
		if fader._faded.has(b):
			behind += 1
		else:
			print("  stays opaque: ", b.name)
		hero.global_position = _ground(Vector3(box.end.x, 0, box.position.z - 0.6))
		for i in 3:
			await physics_frame
		if fader._faded.has(b):
			edge_faded += 1
	print("buildings: %d · fade with the hero hidden behind: %d · fade with the hero half in view: %d" % [count, behind, edge_faded])
	_check(count > 0, "the town has buildings")
	_check(behind * 2 >= count, "most buildings fade while they hide the hero")
	_check(edge_faded == 0, "no building fades while the hero is half in view")
	print("occlusion checks: " + ("FAILED" if _failed else "all passed"))
	quit(1 if _failed else 0)


## The top of whatever stands at this spot (the hero is dropped there).
func _ground(at: Vector3) -> Vector3:
	var space: PhysicsDirectSpaceState3D = (current_scene as Node3D).get_world_3d().direct_space_state
	var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3(0, 40, 0), at - Vector3(0, 40, 0), 1))
	return (hit.position if hit else at) + Vector3(0, 0.1, 0)


func _box(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for v in node.find_children("*", "VisualInstance3D", true, false):
		var b: AABB = v.global_transform * v.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed = true
		print("FAIL: " + what)
