extends SceneTree
## Dev tool: screenshots of the bestiary gallery (docs/screenshots/40_bestiario_*.png).
## Needs a display: xvfb-run godot --path . --script res://tools/capture/bestiary_tour.gd

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.get_node("Progress").save_enabled = false
	var gallery: Node3D = load("res://scenes/dev/bestiario.tscn").instantiate()
	root.add_child(gallery)
	current_scene = gallery
	var hero: Node3D = gallery.get_node("Player")
	var rows := ceili(gallery.get_node("Exhibits").get_child_count() / 2.0 / 6.0)
	var shot := 0
	for z in range(0, -rows * 6 - 1, -13):
		hero.global_position = Vector3(0, 0.1, z + 1.0)
		for i in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.resize(image.get_width() * 3, image.get_height() * 3, Image.INTERPOLATE_NEAREST)
		image.save_png("res://docs/screenshots/40_bestiario_%d.png" % shot)
		print("saved 40_bestiario_%d" % shot)
		shot += 1
	quit()
