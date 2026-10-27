extends SceneTree
## Dev tool: screenshots of the skill-tree screen and the HUD (docs/screenshots/20_* to 23_*).
## Needs a display: xvfb-run godot --path . --script res://tools/capture/tree_tour.gd

const OUT := "res://docs/screenshots/"
const SCALE := 3

var _p: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_p = root.get_node("Progress")
	_p.save_enabled = false
	_p.new_game()
	_p.gain_xp(4000)  # a few levels
	var town: Node3D = load("res://scenes/levels/brumaclara.tscn").instantiate()
	town.get_node("LevelEdits").file = "user://tour_edits.json"
	root.add_child(town)
	current_scene = town
	var hero: Node3D = town.get_node("Player")
	hero.global_position = Vector3(3.0, 0.5, 29.0)
	var hud = town.get_node("HUD")
	await _frames(20)
	hud.open_tree(true)
	await _frames(6)
	_p.nodes  # (the tab shows the first affinity: pick one)
	var tree = hud._tree
	tree._show_tab(&"hielo")
	await _frames(4)
	await _save("20_santuario_elegir")
	_p.choose_principal(&"hielo")
	for id in [&"hielo.esquirlas", &"hielo.frio_penetrante", &"tronco.filo_templado", &"tronco.estocada"]:
		if _p.can_learn(id) == "":
			_p.learn(id)
	tree._show_tab(&"hielo")
	await _frames(4)
	tree._selected = &"hielo.esquirlas"
	tree._refresh()
	await _frames(4)
	await _save("21_arbol_hielo")
	tree._show_tab(&"tronco")
	await _frames(4)
	await _save("22_arbol_aventurero")
	hud.close_tree()
	await _frames(10)
	await _save("23_hud_habilidades")
	quit()


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + file_name + ".png")
	print("saved ", file_name)
