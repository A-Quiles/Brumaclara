extends SceneTree
## Dev tool: Mara giving the first job in the dialogue box, docs/screenshots/46_dialogo.png.
##   xvfb-run godot --path . --script res://tools/capture/dialogue_tour.gd

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.get_node("Progress").save_enabled = false
	root.get_node("Progress").new_game()
	change_scene_to_file("res://scenes/levels/brumaclara.tscn")
	for i in 600:
		if current_scene and current_scene.scene_file_path.ends_with("brumaclara.tscn"):
			break
		await process_frame
	for i in 3:
		await physics_frame
	var mara: Node3D = current_scene.get_node("People/Mara")
	current_scene.get_node("Player").global_position = mara.global_position + Vector3(0.2, 0.3, 1.2)
	root.get_node("DayNight").set_hour(10.5)
	for i in 40:
		await process_frame
	root.get_node("Quests").talk("Mara", mara)
	for i in 150:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/46_dialogo.png")
	quit()
