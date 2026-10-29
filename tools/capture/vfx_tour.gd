extends SceneTree
## Dev tool: the six affinities' explosions side by side in the Patio de pruebas, caught mid-burst, at
## night so their light shows: docs/screenshots/41_poderes.png.
##   xvfb-run godot --path . --script res://tools/capture/vfx_tour.gd

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.get_node("Progress").save_enabled = false
	change_scene_to_file("res://scenes/levels/arena.tscn")
	for i in 600:
		if current_scene and current_scene.scene_file_path.ends_with("arena.tscn"):
			break
		await process_frame
	for i in 3:
		await physics_frame
	var hero: Node3D = current_scene.get_node("Player")
	hero.global_position = Vector3(0, 0.3, 4)
	root.get_node("DayNight").set_hour(22.5)
	for i in 30:
		await process_frame
	var affinities := ["fuego", "hielo", "rayo", "sombra", "tierra", "luz"]
	for k in affinities.size():
		var at := Vector3(-7.5 + k * 3.0, 0.0, -1.0)
		load("res://scripts/combat/skill_caster.gd").explosion(hero, at, 0, StringName(affinities[k]), 1.3)  # (loaded late: it needs the autoloads)
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/41_poderes.png")
	quit()
