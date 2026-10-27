extends SceneTree
## Dev tool: the new monsters in the outskirts (docs/screenshots/24_monstruos.png).
## Needs a display: xvfb-run godot --path . --script res://tools/capture/monsters_tour.gd


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.get_node("Progress").save_enabled = false
	var level: Node3D = load("res://scenes/levels/afueras.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	var names := ["hongo0", "murcielago0", "esqueleto0", "golem0", "espectro0"]
	var enemies := level.get_node("Enemies")
	var hero: Node3D = level.get_node("Player")
	var x := 0.0
	for n in names:
		var m: Node3D = enemies.get_node("Monster_" + n)
		m.global_position = Vector3(x, 0.0, 0.0)
		x += 3.0
	hero.global_position = Vector3(6.0, 0.5, 6.0)
	for i in 45:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://docs/screenshots/24_monstruos.png")
	print("saved")
	quit()
