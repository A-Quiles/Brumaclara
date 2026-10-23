extends SceneTree
## Dev tool: screenshots of the character creator (docs/screenshots/15_* and 16_*), and one of the
## chosen heroine in the town. Needs a display: xvfb-run godot --path . --script res://tools/capture/creator_tour.gd

const OUT := "res://docs/screenshots/"
const SCALE := 3


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var creator: Control = load("res://scenes/ui/character_creator.tscn").instantiate()
	root.add_child(creator)
	current_scene = creator
	creator.look = {"model": 0, "hair": 0, "skin": 0, "outfit": 0}
	creator._refresh()
	await _frames(6)
	await _save("15_creador_hombre")
	creator.look = {"model": 1, "hair": 4, "skin": 2, "outfit": 1}
	creator._row = 2
	creator._refresh()
	await _frames(6)
	await _save("16_creador_mujer")
	# a sheet of looks side by side, for checking the colours
	var sheet := Image.create(56 * 8, 56 * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.3, 0.45, 0.3))
	var looks := [[0, 0, 0, 0], [0, 1, 3, 4], [0, 5, 1, 5], [0, 3, 4, 2], [1, 0, 0, 0], [1, 2, 4, 3],
			[1, 7, 1, 6], [1, 9, 3, 7], [0, 6, 2, 1], [1, 1, 2, 4], [0, 8, 4, 7], [1, 5, 1, 2],
			[0, 4, 3, 6], [1, 3, 0, 5], [0, 2, 2, 3], [1, 8, 4, 1]]
	for i in looks.size():
		var l: Array = looks[i]
		var frames := HeroLook.frames({"model": l[0], "hair": l[1], "skin": l[2], "outfit": l[3]})
		var tex := frames.get_frame_texture("walk_down", 0) as AtlasTexture
		var img := tex.atlas.get_image().get_region(Rect2i(tex.region))
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(i % 8 * 56, i / 8 * 56))
	sheet.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
	sheet.save_png(OUT + "17_aspectos.png")
	# the heroine in the town, by the stable with the new horses
	var kept := FileAccess.get_file_as_string(HeroLook.FILE)
	HeroLook.save_look({"model": 1, "hair": 4, "skin": 2, "outfit": 1})
	creator.free()
	var town: Node3D = load("res://scenes/levels/brumaclara.tscn").instantiate()
	town.get_node("LevelEdits").file = "user://tour_edits.json"
	root.add_child(town)
	current_scene = town
	town.get_node("Player").global_position = Vector3(-12.0, 0.5, 27.0)
	await _frames(20)
	await _save("18_heroina_establo")
	if kept != "":
		FileAccess.open(HeroLook.FILE, FileAccess.WRITE).store_string(kept)
	else:
		DirAccess.remove_absolute(HeroLook.FILE)
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
