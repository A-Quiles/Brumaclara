extends SceneTree
## Dev tool: the hero behind a horse (partly hidden: no see-through) and behind the inn (wholly hidden:
## the inn fades and the hero's silhouette shows), docs/screenshots/27_* and 28_*.
## Needs a display: xvfb-run godot --path . --script res://tools/capture/occlusion_tour.gd


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.get_node("Progress").save_enabled = false
	change_scene_to_file("res://scenes/levels/brumaclara.tscn")
	for i in 30:
		await process_frame
	var hero: Node3D = current_scene.get_node("Player")
	var horse: Node3D = current_scene.get_node("Props/Horse")
	hero.global_position = horse.global_position + Vector3(0.3, 0.2, -1.2)  # just behind it
	await _shot("res://docs/screenshots/27_detras_del_caballo.png")
	var inn: Node3D = current_scene.get_node("Buildings/Posada")
	var box := AABB()
	for v in inn.find_children("*", "VisualInstance3D", true, false):
		var b: AABB = v.global_transform * v.get_aabb()
		box = b if box.size == Vector3.ZERO else box.merge(b)
	var behind := Vector3(box.get_center().x, 0, box.position.z - 0.6)
	var ground: Dictionary = (current_scene as Node3D).get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(behind + Vector3(0, 40, 0), behind - Vector3(0, 40, 0), 1))
	hero.global_position = (ground.position if ground else behind) + Vector3(0, 0.1, 0)
	await _shot("res://docs/screenshots/28_detras_de_la_posada.png")
	quit()


func _shot(path: String) -> void:
	for i in 40:
		await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
