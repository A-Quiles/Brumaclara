extends SceneTree
## Dev tool: a screenshot of the inventory (docs/screenshots/26_inventario.png) with a few items.
## Needs a display: xvfb-run godot --path . --script res://tools/capture/inventory_tour.gd


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var progress: Node = root.get_node("Progress")
	progress.save_enabled = false
	progress.new_game()
	progress.add_item(&"cristal", 4)
	progress.add_item(&"monedas", 135)
	change_scene_to_file("res://scenes/levels/brumaclara.tscn")
	for i in 60:
		await process_frame
	current_scene.get_node("HUD").open_inventory()
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/26_inventario.png")
	quit()
