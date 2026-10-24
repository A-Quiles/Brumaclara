extends SceneTree
## Headless checks of the character creator's looks: every model has the hero's animations, a colour
## choice repaints only its own group, and the chosen look is saved and read back.
## Run: godot --headless --path . --script res://tools/tests/test_hero_look.gd

var _failures := 0


func _initialize() -> void:
	var names := (load("res://assets/characters/hero/hero_frames.tres") as SpriteFrames).get_animation_names()
	for m in HeroLook.MODELS.size():
		var frames := HeroLook.frames({"model": m, "hair": 0, "skin": 0, "outfit": 0})
		_check(frames.get_animation_names() == names, "model %s has every animation" % HeroLook.MODELS[m].set)
	for set_name: String in HeroLook.MODELS.map(func(m: Dictionary) -> String: return m.set):
		var plain: Image = HeroLook.paint(set_name, {1: null, 2: null, 3: null, 4: null})
		var red: Image = HeroLook.paint(set_name, {1: Color("c2482a"), 2: null, 3: null, 4: null})
		var mask: Image = load("res://assets/characters/hero/%s_mask.png" % set_name).get_image()
		var hair_changed := 0
		var others_changed := 0
		for y in range(0, plain.get_height()):
			for x in range(0, plain.get_width()):
				if plain.get_pixel(x, y) != red.get_pixel(x, y):
					if mask.get_pixel(x, y).r8 == 50:
						hair_changed += 1
					else:
						others_changed += 1
		_check(hair_changed > 500 and others_changed == 0, "%s: red hair repaints the hair only (%d, %d)" % [set_name, hair_changed, others_changed])
	var kept := FileAccess.get_file_as_string(HeroLook.FILE)  # the developer's own look is put back
	var look := {"model": 1, "hair": 3, "skin": 2, "outfit": 4}
	HeroLook.save_look(look)
	_check(HeroLook.load_look() == look, "the chosen look is saved")
	DirAccess.remove_absolute(HeroLook.FILE)
	_check(HeroLook.load_look() == HeroLook.default_look(), "no saved look gives the drawn hero")
	if kept != "":
		FileAccess.open(HeroLook.FILE, FileAccess.WRITE).store_string(kept)
	print("hero look checks: %s" % ("all passed" if _failures == 0 else "%d FAILED" % _failures))
	quit(1 if _failures else 0)


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failures += 1
