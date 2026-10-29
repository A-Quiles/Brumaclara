extends SceneTree
## Dev tool: one screenshot of a level with the hero at a spot and the clock at an hour.
##   xvfb-run godot --path . --script res://tools/capture/shot.gd -- <scene> <x> <y> <z> <hour> <out.png> [wait frames]

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var a := OS.get_cmdline_user_args()
	root.get_node("Progress").save_enabled = false
	change_scene_to_file(a[0])
	for i in 600:
		if current_scene and current_scene.scene_file_path == a[0]:
			break
		await process_frame
	for i in 3:
		await physics_frame
	(current_scene.get_node("Player") as Node3D).global_position = Vector3(float(a[1]), float(a[2]), float(a[3]))
	root.get_node("DayNight").set_hour(float(a[4]))
	var wait := int(a[6]) if a.size() > 6 else 90
	for i in wait:
		await process_frame
	root.get_node("DayNight").set_hour(float(a[4]))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(a[5])
	quit()
