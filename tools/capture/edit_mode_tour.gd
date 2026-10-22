extends SceneTree
## Dev tool: screenshots of the edit mode (docs/screenshots/12_* to 14_*), driven through its own
## functions. Needs a display: xvfb-run godot --path . --script res://tools/capture/edit_mode_tour.gd

const TOWN := "res://scenes/levels/brumaclara.tscn"
const OUT := "res://docs/screenshots/"
const SCALE := 3

var _em: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var town: Node3D = load(TOWN).instantiate()
	town.get_node("LevelEdits").file = "user://tour_edits.json"
	if FileAccess.file_exists("user://tour_edits.json"):
		DirAccess.remove_absolute("user://tour_edits.json")
	root.add_child(town)
	current_scene = town
	town.get_node("Player").global_position = Vector3(-1.0, 0.5, 6.5)
	await _frames(10)
	_em = root.get_node("EditMode")
	_em.set_active(true)
	await _frames(4)
	# a bench from the palette, turned to face the street, about to be placed
	var bench: Button = _find_item("props/bench")
	if bench:
		bench.button_pressed = true
	_em._modify("turn", 1)
	_em._modify("turn", 1)
	await _hover(Vector2(362, 208))
	_em._place()
	_em._modify("turn", 1)
	await _hover(Vector2(425, 262))
	await _save("12_edicion_colocar")
	# an object picked in the world, with its frame and its line of information
	_em._drop_tool()
	var picked: String = _em._pick(Vector2(320, 172))
	_em._select(picked)
	await _hover(Vector2(255, 165))
	await _save("13_edicion_seleccion")
	# the paths brush and the help sheet
	_em._select("")
	_em._set_painting(true)
	_em._brush = 1
	await _hover(Vector2(260, 300))
	_em._begin_stroke(false)
	for x in range(260, 380, 6):
		await _hover(Vector2(x, 300 - (x - 260) * 0.4))
		_em._motion(_motion_event(Vector2(x, 300 - (x - 260) * 0.4)))
	_em._release()
	_em._panel.toggle_help()
	await _hover(Vector2(400, 320))
	await _save("14_edicion_caminos_y_ayuda")
	_em.set_active(false)
	quit()


func _find_item(group: String) -> Button:
	for button in _em._panel.find_children("*", "Button", true, false):
		if button.get_meta("group", "") == group:
			return button
	return null


func _motion_event(p: Vector2) -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.position = p
	e.relative = Vector2(6, -2.4)
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	return e


func _hover(p: Vector2) -> void:
	Input.warp_mouse(p * SCALE)
	await _frames(3)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + file_name + ".png")
	print("saved ", file_name)
