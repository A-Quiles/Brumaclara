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
	creator.look = HeroLook.clamp_look({"model": 0})
	creator._refresh()
	await _frames(6)
	await _save("15_creador_hombre")
	creator.look = HeroLook.clamp_look({"model": 7, "hair": 12, "skin": 6, "outfit": 9, "leather": 4, "trousers": 3})
	creator._row = 2
	creator._refresh()
	await _frames(6)
	await _save("16_creador_mujer")
	# a sheet of looks side by side, for checking the colours
	var cols := 12
	var sheet := Image.create(56 * cols, 56 * 3, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.3, 0.45, 0.3))
	for i in cols * 3:
		var look := {"model": i % 12, "hair": (i * 5) % 26, "skin": (i * 3) % 12, "outfit": (i * 7) % 19,
				"leather": (i * 3) % 10, "trousers": (i * 5) % 9}
		var frames := HeroLook.frames(look)
		var tex := frames.get_frame_texture("walk_down", 0) as AtlasTexture
		var img := tex.atlas.get_image().get_region(Rect2i(tex.region))
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(i % cols * 56, i / cols * 56))
	sheet.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
	sheet.save_png(OUT + "17_aspectos.png")
	# the heroine in the town, by the stable with the new horses
	var kept := FileAccess.get_file_as_string(HeroLook.FILE)
	HeroLook.save_look(HeroLook.clamp_look({"model": 7, "hair": 12, "skin": 6, "outfit": 9, "leather": 4, "trousers": 3}))
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
