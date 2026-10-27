extends Control
## The character creator shown when the game starts: gender and hairstyle (the drawn models of
## HeroLook), hair and skin colour and outfit, with the hero walking in a preview. Arrows or WASD
## move through the options, Enter starts the game in Brumaclara with the look saved.

const FONT := preload("res://assets/fonts/pixelify_sans_medium.woff")
const BACKDROP := preload("res://assets/environment/backdrop/far_scenery.png")
const GRASS := preload("res://assets/environment/textures/grass.png")
const SHADOW := preload("res://assets/environment/textures/blob_shadow.png")
const FIRST_LEVEL := "res://scenes/levels/brumaclara.tscn"
const GOLD := Color("ffd34a")
const INK := Color("f4e9c8")
const DIM := Color(0.62, 0.66, 0.8)
const TURN := [["walk_down", false], ["walk_side", false], ["walk_up", false], ["walk_side", true]]
const OPTIONS := ["Género", "Peinado", "Pelo", "Piel", "Atuendo", "Cuero", "Pantalón"]
const ROW_RANDOM := 7
const ROW_NEW := 8
const ROW_CONTINUE := 9  # only with a saved game

var look := HeroLook.load_look()
var _rows := 9
var _row := 0
var _turn := 0
var _turn_clock := 0.0
var _hero: AnimatedSprite2D
var _values: Array[Label] = []
var _swatches: Array[ColorRect] = []
var _lines: Array[Control] = []


func _ready() -> void:
	_rows = 10 if Progress.has_save() and Progress.principal != &"" else 9
	set_anchors_preset(PRESET_FULL_RECT)
	theme = Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 11
	_build()
	_refresh()


func _process(delta: float) -> void:
	_turn_clock += delta
	if _turn_clock > 2.2:  # the preview turns round by itself
		_turn_clock = 0.0
		_turn = (_turn + 1) % TURN.size()
		_play()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("move_up"):
		_row = posmod(_row - 1, _rows)
	elif event.is_action("move_down"):
		_row = posmod(_row + 1, _rows)
	elif event.is_action("move_left"):
		_change(_row, -1)
	elif event.is_action("move_right"):
		_change(_row, 1)
	elif event.is_action("ui_accept"):
		_activate(_row)
	else:
		return
	get_viewport().set_input_as_handled()
	_refresh()


## Moves option `row` by `step` (gender jumps to the first model of the other gender).
func _change(row: int, step: int) -> void:
	match row:
		0:
			var gender: String = HeroLook.MODELS[look.model].gender
			for i in range(1, HeroLook.MODELS.size() + 1):
				var m := posmod(look.model + i * step, HeroLook.MODELS.size())
				if HeroLook.MODELS[m].gender != gender:
					look.model = m
					break
		1:
			var gender: String = HeroLook.MODELS[look.model].gender
			for i in range(1, HeroLook.MODELS.size() + 1):
				var m := posmod(look.model + i * step, HeroLook.MODELS.size())
				if HeroLook.MODELS[m].gender == gender:
					look.model = m
					break
		2:
			look.hair += step
		3:
			look.skin += step
		4:
			look.outfit += step
		5:
			look.leather += step
		6:
			look.trousers += step
		_:
			return
	HeroLook.clamp_look(look)
	_refresh()


func _activate(row: int) -> void:
	if row == ROW_RANDOM:
		look = HeroLook.clamp_look({"model": randi(), "hair": randi(), "skin": randi(), "outfit": randi(),
				"leather": randi(), "trousers": randi()})
		_refresh()
	elif row == ROW_NEW:  # a new game: level 1, no affinity, nothing learned
		HeroLook.save_look(look)
		Progress.new_game()
		get_tree().change_scene_to_file(FIRST_LEVEL)
	elif row == ROW_CONTINUE:
		HeroLook.save_look(look)
		get_tree().change_scene_to_file(FIRST_LEVEL)
	else:
		_change(row, 1)


func _refresh() -> void:
	var model: Dictionary = HeroLook.MODELS[look.model]
	var hair: Array = HeroLook.HAIR[look.hair]
	var skin: Array = HeroLook.SKIN[look.skin]
	var outfit: Array = HeroLook.OUTFITS[look.outfit]
	var leather: Array = HeroLook.LEATHER[look.leather]
	var trousers: Array = HeroLook.TROUSERS[look.trousers]
	var texts := [model.gender, model.hair, hair[0], skin[0], outfit[0], leather[0], trousers[0]]
	var colours := [null, null, hair[1], skin[1], outfit[1], leather[1], trousers[1]]
	var same_gender := HeroLook.MODELS.filter(func(m: Dictionary) -> bool: return m.gender == model.gender).size()
	for i in texts.size():
		_values[i].text = texts[i] + ("  (único)" if i == 1 and same_gender == 1 else "")
		_swatches[i].visible = colours[i] != null and colours[i] != ""
		if _swatches[i].visible:
			_swatches[i].color = Color(colours[i])
	for i in _lines.size():
		var on := i == _row
		_lines[i].modulate = Color.WHITE if on else Color(1, 1, 1, 0.72)
		(_lines[i].get_node("Mark") as Label).text = ">" if on else ""
	_hero.sprite_frames = HeroLook.frames(look)
	_play()


func _play() -> void:
	_hero.flip_h = TURN[_turn][1]
	_hero.play(TURN[_turn][0])


func _build() -> void:
	var sky := TextureRect.new()
	sky.texture = BACKDROP
	sky.set_anchors_preset(PRESET_FULL_RECT)
	sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sky.texture_filter = TEXTURE_FILTER_NEAREST
	add_child(sky)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.04, 0.1, 0.45)
	shade.set_anchors_preset(PRESET_FULL_RECT)
	add_child(shade)

	var title := Label.new()
	title.text = "CREA TU PERSONAJE"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.1))
	title.add_theme_constant_override("outline_size", 4)
	title.position = Vector2(32, 22)
	add_child(title)

	# the preview: a framed patch of grass with the hero walking on it
	var frame := ColorRect.new()
	frame.color = Color("c9a24a")
	frame.position = Vector2(71, 239)
	frame.size = Vector2(162, 50)
	add_child(frame)
	var ground := TextureRect.new()
	ground.texture = GRASS
	ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ground.stretch_mode = TextureRect.STRETCH_TILE
	ground.texture_filter = TEXTURE_FILTER_NEAREST
	ground.position = Vector2(72, 240)
	ground.size = Vector2(160, 48)
	add_child(ground)
	var shadow := Sprite2D.new()
	shadow.texture = SHADOW
	shadow.texture_filter = TEXTURE_FILTER_NEAREST
	shadow.position = Vector2(152, 268)
	shadow.scale = Vector2(3, 3)
	shadow.modulate.a = 0.7
	add_child(shadow)
	_hero = AnimatedSprite2D.new()
	_hero.texture_filter = TEXTURE_FILTER_NEAREST
	_hero.centered = false
	_hero.scale = Vector2(3, 3)
	_hero.position = Vector2(152 - 28 * 3, 270 - 53 * 3)  # feet of the frame on the grass
	add_child(_hero)

	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.07, 0.09, 0.18, 0.92)
	box.border_color = Color("c9a24a")
	box.set_border_width_all(1)
	box.set_content_margin_all(10)
	box.anti_aliasing = false
	panel.add_theme_stylebox_override("panel", box)
	panel.position = Vector2(318, 50)
	panel.custom_minimum_size = Vector2(290, 0)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)
	for i in _rows:
		var line := HBoxContainer.new()
		line.custom_minimum_size = Vector2(0, 21)
		line.mouse_filter = MOUSE_FILTER_PASS
		var mark := Label.new()
		mark.name = "Mark"
		mark.custom_minimum_size = Vector2(10, 0)
		mark.add_theme_color_override("font_color", GOLD)
		line.add_child(mark)
		if i < OPTIONS.size():
			var name_label := Label.new()
			name_label.text = OPTIONS[i]
			name_label.custom_minimum_size = Vector2(70, 0)
			name_label.add_theme_color_override("font_color", DIM)
			line.add_child(name_label)
			line.add_child(_arrow("<", i, -1))
			var value := Label.new()
			value.custom_minimum_size = Vector2(118, 0)
			value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			value.add_theme_color_override("font_color", INK)
			line.add_child(value)
			_values.append(value)
			line.add_child(_arrow(">", i, 1))
			var swatch := ColorRect.new()
			swatch.custom_minimum_size = Vector2(12, 12)
			swatch.size_flags_vertical = SIZE_SHRINK_CENTER
			line.add_child(swatch)
			_swatches.append(swatch)
		else:
			var button := Button.new()
			button.text = ["Aleatorio", "Nueva aventura", "Continuar partida"][i - ROW_RANDOM]
			button.focus_mode = FOCUS_NONE
			button.size_flags_horizontal = SIZE_EXPAND_FILL
			button.add_theme_color_override("font_color", GOLD if i == ROW_NEW else INK)
			button.pressed.connect(func() -> void:
				_row = i
				_activate(i))
			line.add_child(button)
		if i == ROW_RANDOM:
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(0, 6)
			column.add_child(gap)
		column.add_child(line)
		_lines.append(line)

	var hint := Label.new()
	hint.text = "Flechas o WASD: elegir · Intro: confirmar"
	hint.add_theme_color_override("font_color", DIM)
	hint.position = Vector2(318, 338)
	add_child(hint)


func _arrow(text: String, row: int, step: int) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = FOCUS_NONE
	b.add_theme_color_override("font_color", GOLD)
	b.pressed.connect(func() -> void:
		_row = row
		_change(row, step))
	return b
