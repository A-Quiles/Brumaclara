extends SceneTree
## Headless checks of the edit mode's data side: the sprite catalog reads views from file names and
## turns objects through them, raw images are cut out and brought to game size, and the edits of a
## level (moved, turned, removed, added, copied objects and painted paths) are saved and come back
## when the level loads again. Run: godot --headless --path . --script res://tools/tests/test_edit_mode.gd

const TOWN := "res://scenes/levels/brumaclara.tscn"
const FILE := "user://test_edits.json"

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_catalog()
	_raw_images()
	await _edits()
	await _editing()
	print("edit mode checks: %s" % ("all passed" if _failures == 0 else "%d FAILED" % _failures))
	quit(1 if _failures else 0)


func _catalog() -> void:
	SpriteCatalog.scan()
	var bench: Dictionary = SpriteCatalog.views("props/bench", "")
	_check(bench.size() == 8, "the bench can face all 8 ways (%s)" % [bench.keys()])
	_check(bench["sw"] == ["props/bench", false] and bench["ne"] == ["props/bench__nw", true],
			"the bench's own drawing faces sw, and ne is the mirrored nw")
	var seen := {}
	var view := ["props/bench", false]
	for i in 8:
		view = SpriteCatalog.turn(view[0], view[1], 1)
		seen[SpriteCatalog.label(view[0], view[1])] = true
	_check(seen.size() == 8 and view == ["props/bench", false], "turning goes round the 8 views and back")
	_check(SpriteCatalog.turn("props/well", false, 1) == ["props/well", true], "an object drawn once is mirrored when turned")
	var model: Array = SpriteCatalog.next_model("props/horse", false, 1)
	_check(model[0].begins_with("props/horse__"), "the horse has other models (%s)" % model[0])
	_check(SpriteCatalog.label("props/horse__grazing", true) == "caballo pastando · O", "labels in Spanish")
	var half := SpriteCatalog.sized("props/bench", 0.5)
	var bench_tex: Texture2D = load("res://assets/environment/props/bench.png")
	_check(absi(half.get_height() - roundi(bench_tex.get_height() * 0.5)) <= 1, "resizing redraws the image at the new size")


func _raw_images() -> void:
	# a 10 x 12 sprite enlarged 8 times on a magenta background, like a generated image
	var small := Image.create(10, 12, false, Image.FORMAT_RGBA8)
	small.fill(Color.MAGENTA)
	small.fill_rect(Rect2i(2, 1, 6, 10), Color(0.4, 0.25, 0.1))
	small.fill_rect(Rect2i(3, 2, 4, 3), Color(0.9, 0.8, 0.3))
	var raw := small.duplicate() as Image
	raw.resize(80, 96, Image.INTERPOLATE_NEAREST)
	var adapted := SpriteCatalog.adapt(raw)
	_check(adapted.native == 10, "a raw image's pixel blocks give its game size (%d px tall)" % adapted.native)
	var img := SpriteCatalog.shrink(adapted.image, adapted.native)
	_check(img.get_size() == Vector2i(6, 10), "the background is cut away (%s)" % img.get_size())
	var c := img.get_pixel(0, 0)
	_check(c.a == 1.0 and absf(c.r - 0.4) < 0.05 and c.b < 0.15, "no magenta fringe is left (%s)" % c)


func _edits() -> void:
	if FileAccess.file_exists(FILE):
		DirAccess.remove_absolute(FILE)
	var town := _load_town()
	await _frames(2)
	var edits: LevelEdits = town.get_node("LevelEdits")
	_check(edits.entries.size() > 300, "the level's objects are indexed (%d)" % edits.entries.size())
	var bench_handle := _first(edits, "props/bench")
	var tree_handle := _first(edits, "nature/tree_oak")
	var moved: Dictionary = edits.entries[bench_handle].state.duplicate()
	moved.pos += Vector3(1.5, 0, -0.5)
	moved.key = "props/bench__e"
	moved.scale = 1.5
	edits.apply(bench_handle, moved)
	edits.apply(tree_handle, null)
	var barrel := edits.add("props/barrel", {"key": "props/barrel", "pos": Vector3(2, 0.2, 10), "rot": 0.0,
			"scale": 1.0, "flip": true, "solid": true})
	var inn := "Buildings/Posada"
	var copy_state: Dictionary = edits.entries[inn].state.duplicate()
	copy_state.pos += Vector3(0, 0, 40)
	copy_state.rot = 90.0
	edits.copy(inn, copy_state)
	var paths := edits.paint_image()
	paths.set_pixel(10, 10, Color(0, 1, 0, 0))
	edits.paths_changed()
	_check(edits.save() == OK and not edits.dirty, "the edits are saved")
	var bench_node: Node3D = edits.entries[bench_handle].node
	var sprite: Sprite3D = bench_node.get_node("Sprite")
	_check(is_equal_approx(sprite.scale.x * bench_node.scale.x, 1.0), "a resized sprite keeps the game's pixel size")
	town.free()

	town = _load_town()
	await _frames(2)
	edits = town.get_node("LevelEdits")
	var bench: Node3D = edits.entries[bench_handle].node
	_check(bench.get_meta("key") == "props/bench__e" and bench.global_position.distance_to(moved.pos) < 0.01,
			"a moved and turned object comes back where it was left")
	_check(is_equal_approx(bench.scale.x, 1.5), "and with its new size")
	_check(edits.entries[tree_handle].state == null and not edits.entries[tree_handle].node.is_inside_tree(),
			"a removed object stays removed")
	var added: Node3D = town.get_node_or_null("Colocados/Barrel")
	_check(added != null and added.get_node("Sprite").flip_h, "an added object comes back, mirrored")
	var copies := town.get_node("Buildings").get_children().filter(func(n: Node) -> bool:
		return n.name.begins_with("Posada") and n.global_position.distance_to(copy_state.pos) < 0.01)
	_check(copies.size() == 1 and is_equal_approx(copies[0].rotation_degrees.y, 90.0), "a copied building comes back, turned")
	_check(edits.paths_image != null and edits.paths_image.get_pixel(10, 10).g > 0.9, "painted paths come back")
	_check(edits.to_doc().changed.size() == 2 and edits.to_doc().added.size() == 2, "nothing else changed")
	town.free()
	DirAccess.remove_absolute(FILE)
	DirAccess.remove_absolute(FILE + ".bak")
	print("  (barrel handle %s)" % barrel)


## The edit mode driven by keys and mouse like a person would: M, click a bench, drag it, turn it,
## enlarge it, delete it, undo everything, M back to playing.
func _editing() -> void:
	var town := _load_town()
	current_scene = town
	await _frames(3)
	var em: Node = root.get_node("EditMode")
	await _key(KEY_M)
	_check(em.active and paused, "M opens the edit mode and pauses the game")
	var bench := ""
	var spot := Vector2.ZERO
	for y in range(80, 340, 4):  # a bench somewhere on screen
		for x in range(180, 636, 4):
			var h: String = em._pick(Vector2(x, y))
			if h != "" and str(em.edits.entries[h].state.key).begins_with("props/bench"):
				bench = h
				spot = Vector2(x, y)
				break
		if bench != "":
			break
	_check(bench != "", "a bench can be picked by its pixels (%s)" % bench)
	if bench == "":
		town.free()
		return
	var start: Dictionary = em.edits.entries[bench].state.duplicate()
	await _click(spot, true)
	_check(em._selected == bench, "a click selects it")
	for i in 6:
		await _drag(spot + Vector2(4, 2) * (i + 1))
	await _click(spot + Vector2(24, 12), false)
	var moved: Dictionary = em.edits.entries[bench].state
	_check(moved.pos.distance_to(start.pos) > 1.0, "dragging moves it (%s -> %s)" % [start.pos, moved.pos])
	await _key(KEY_R)
	_check(em.edits.entries[bench].state.key != start.key or em.edits.entries[bench].state.flip != start.flip,
			"R turns it to its next view (%s)" % em.edits.entries[bench].state.key)
	await _key(KEY_E)
	_check(is_equal_approx(em.edits.entries[bench].state.scale, 1.1), "E enlarges it")
	await _key(KEY_DELETE)
	_check(em.edits.entries[bench].state == null and em._selected == "", "Supr deletes it")
	for i in 5:
		await _key(KEY_Z, true)
	var back: Dictionary = em.edits.entries[bench].state
	_check(back.key == start.key and back.pos.distance_to(start.pos) < 0.001 and back.scale == start.scale,
			"Ctrl+Z undoes everything")
	await _key(KEY_Y, true)
	_check(em.edits.entries[bench].state.pos.distance_to(moved.pos) < 0.001, "Ctrl+Y redoes the move")
	_check(FileAccess.file_exists(FILE), "every change is saved at once")
	await _key(KEY_M)
	_check(not em.active and not paused, "M goes back to playing")
	town.free()
	DirAccess.remove_absolute(FILE)
	DirAccess.remove_absolute(FILE + ".bak")


func _key(code: Key, ctrl := false) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.ctrl_pressed = ctrl
	e.pressed = true
	Input.parse_input_event(e)
	await process_frame
	var up := e.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


func _click(at: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = root.get_final_transform() * at  # window pixels: the game is drawn scaled up
	e.global_position = e.position
	e.pressed = pressed
	Input.parse_input_event(e)
	await process_frame


func _drag(at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = root.get_final_transform() * at
	e.global_position = e.position
	e.relative = root.get_final_transform().basis_xform(Vector2(4, 2))
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(e)
	await process_frame


func _load_town() -> Node3D:
	var town: Node3D = load(TOWN).instantiate()
	town.get_node("LevelEdits").file = FILE
	root.add_child(town)
	return town


func _first(edits: LevelEdits, key: String) -> String:
	for handle: String in edits.entries:
		if edits.entries[handle].state and edits.entries[handle].state.key == key:
			return handle
	return ""


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failures += 1
