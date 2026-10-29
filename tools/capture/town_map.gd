extends SceneTree
## Dev tool: a top-down view of a level with a grid every 10 units (labels are x, z), to plan where
## things go. xvfb-run godot --path . --script res://tools/capture/town_map.gd -- <scene> <out.png>

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var scene: String = args[0] if args.size() > 0 else "res://scenes/levels/brumaclara.tscn"
	var out: String = args[1] if args.size() > 1 else "res://docs/screenshots/mapa.png"
	root.get_node("Progress").save_enabled = false
	change_scene_to_file(scene)
	for i in 20:
		await process_frame
	var lvl := current_scene as Node3D
	for n in ["HUD", "Backdrop"]:
		var node := lvl.get_node_or_null(n)
		if node:
			node.queue_free()
	var vp := SubViewport.new()
	vp.size = Vector2i(1400, 1400)
	vp.world_3d = lvl.get_world_3d()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 130.0
	vp.add_child(cam)
	cam.global_position = Vector3(0, 80, -9)
	cam.rotation_degrees = Vector3(-90, 0, 0)
	cam.current = true
	for x in range(-60, 61, 10):
		for z in range(-70, 51, 10):
			var l := Label3D.new()
			l.text = "%d,%d" % [x, z]
			l.font_size = 48
			l.pixel_size = 0.01
			l.modulate = Color(1, 1, 0)
			l.outline_size = 16
			l.no_depth_test = true
			l.rotation_degrees = Vector3(-90, 0, 0)
			lvl.add_child(l)
			l.global_position = Vector3(x, 30, z)
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(out)
	quit()
