extends SceneTree
## Dev tool: a screenshot of every interior (docs/screenshots/30_* ...).
## Needs a display: xvfb-run godot --path . --script res://tools/capture/interiors_tour.gd

const OUT := "res://docs/screenshots/"
const ROOMS := {"posada": "30_posada", "sede_faro": "31_sede_faro", "tienda_nara": "32_tienda_nara",
		"taller_elia": "33_taller_elia"}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.get_node("Progress").save_enabled = false
	for room in ROOMS:
		var level: Node3D = load("res://scenes/levels/interiors/%s.tscn" % room).instantiate()
		level.get_node("LevelEdits").file = "user://tour_edits.json"
		root.add_child(level)
		current_scene = level
		var hero: Node3D = level.get_node("Player")
		hero.global_position = Vector3(0, 0.1, 5.0)
		for i in 30:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.resize(image.get_width() * 3, image.get_height() * 3, Image.INTERPOLATE_NEAREST)
		image.save_png(OUT + ROOMS[room] + ".png")
		print("saved ", ROOMS[room])
		level.free()
		await process_frame
	quit()
