extends SceneTree
## Captures of the art validation scene (docs/plan_unificacion_artistica.md, section 5) with the
## game's camera, resolution and light: day with an effect, the dialogue box, and night.
##   xvfb-run godot --path . --script res://tools/capture/validacion_arte.gd -- <out prefix>

const SCENE := "res://scenes/dev/validacion_arte.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var prefix: String = OS.get_cmdline_user_args()[0]
	root.get_node("Progress").save_enabled = false
	change_scene_to_file(SCENE)
	for i in 600:
		if current_scene and current_scene.scene_file_path == SCENE:
			break
		await process_frame
	var day_night := root.get_node("DayNight")
	day_night.set_hour(11.0)
	for i in 80:
		await process_frame
	current_scene.call("_effect")
	for i in 7:
		await process_frame
	await _save(prefix + "_dia.png")
	var at: Vector3 = current_scene.get_node("Muestras/Efecto").global_position
	var affinities := [&"fuego", &"hielo", &"rayo", &"sombra", &"tierra", &"luz"]
	for i in affinities.size():  # the six affinities side by side, at their brightest moment
		Vfx.burst(current_scene, at + Vector3(-3.0 + i * 1.7, 0, 1.0 + (i % 2) * 1.2), affinities[i], 1.0)
	for i in 2:
		await process_frame
	await _save(prefix + "_efectos.png")
	for i in 60:
		await process_frame
	var talk := func() -> void:
		await load("res://scripts/ui/dialogue.gd").run(current_scene.get_node("Muestras/Mara"), "Mara Venn",
				PackedStringArray(["Escena de validación: todo recurso nuevo se prueba aquí antes de entrar en la ciudad."]))
	talk.call()
	for i in 150:
		await process_frame
	await _save(prefix + "_dialogo.png")
	for child in current_scene.get_node("HUD").get_children():
		if child.get_script() == load("res://scripts/ui/dialogue.gd"):
			child.queue_free()
	paused = false
	day_night.set_hour(22.0)
	for i in 40:
		await process_frame
	day_night.set_hour(22.0)
	await _save(prefix + "_noche.png")
	quit()


func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
