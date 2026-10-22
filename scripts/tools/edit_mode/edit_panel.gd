extends Control
## The edit mode's screen: the palette of sprites on the left (one tab per folder of the sprite
## catalog, and a search box), the info line at the bottom, the help sheet, and an overlay the edit
## mode draws its frames and brush on.

signal picked(group: String)  ## a palette item was chosen ("" when it was let go)

const FONT := preload("res://assets/fonts/pixelify_sans_medium.woff")
const GOLD := Color("ffd34a")
const INK := Color("f4e9c8")
const SIDE_W := 168
const BAR_H := 15
const HELP := """MODO EDICIÓN · F1 (o F4) entra y sale: al salir juegas con los cambios. Todo se guarda solo.
Cámara: WASD · rueda: zoom · arrastrar en un hueco o con el botón central: desplazarla
Colocar: elige un objeto en el panel y haz clic en el mundo · clic derecho o Esc: soltarlo
Seleccionar: clic en un objeto · arrastrar: moverlo · flechas: ajustarlo (Mayús: más)
R / Mayús+R: girar (usa la vista dibujada para esa dirección o el espejo) · Alt+R: 15°
V: otro modelo · F: espejo · Q / E: tamaño · 0: tamaño original · C: sólido sí o no
Re Pág / Av Pág: subir o bajar · G: rejilla · B: ver a través de los edificios
Ctrl+D: duplicar · Ctrl+C: usarlo para colocar más · Supr: borrar · Ctrl+Z / Ctrl+Y: deshacer
P: pincel de caminos · 1 adoquín · 2 tierra · 3 huerto · 4 bosque · clic der.: hierba · Q/E grosor
T: llevar al héroe al cursor · Tab: ocultar el panel · Ctrl+R: releer los sprites · H: esta ayuda
Imágenes nuevas: déjalas en assets/nuevos y pulsa Ctrl+R (se recortan y se escalan solas)."""

var overlay: Control  ## the edit mode draws on it

var _side: PanelContainer
var _bar: PanelContainer
var _help: PanelContainer
var _title: Label
var _grid: GridContainer
var _search: LineEdit
var _name: Label
var _info: Label
var _status: Label
var _folder := "props"
var _items := ButtonGroup.new()
var _thumbs := {}
var _status_until := 0


func _init() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	theme = _theme()
	overlay = Control.new()
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(overlay)

	_side = PanelContainer.new()
	_side.anchor_bottom = 1.0
	_side.offset_right = SIDE_W
	_side.offset_bottom = -BAR_H
	add_child(_side)
	var column := VBoxContainer.new()
	_side.add_child(column)
	_title = Label.new()
	_title.add_theme_color_override("font_color", GOLD)
	column.add_child(_title)
	var tabs := HBoxContainer.new()
	column.add_child(tabs)
	var tab_group := ButtonGroup.new()
	for folder: String in SpriteCatalog.FOLDERS:
		var tab := Button.new()
		tab.text = SpriteCatalog.LABELS[folder]
		tab.toggle_mode = true
		tab.button_group = tab_group
		tab.button_pressed = folder == _folder
		tab.focus_mode = FOCUS_NONE
		tab.size_flags_horizontal = SIZE_EXPAND_FILL
		tab.pressed.connect(func() -> void:
			_folder = folder
			fill())
		tabs.add_child(tab)
	_search = LineEdit.new()
	_search.placeholder_text = "buscar…"
	_search.text_changed.connect(func(_text: String) -> void: fill())
	column.add_child(_search)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 5
	scroll.add_child(_grid)
	_name = Label.new()
	_name.clip_text = true
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(_name)
	_items.allow_unpress = true

	_bar = PanelContainer.new()
	_bar.add_theme_stylebox_override("panel", _box(Color(0.03, 0.04, 0.09, 0.93), Color(0, 0, 0, 0), 1))
	_bar.anchor_top = 1.0
	_bar.anchor_right = 1.0
	_bar.anchor_bottom = 1.0
	_bar.offset_top = -BAR_H
	add_child(_bar)
	var line := HBoxContainer.new()
	_bar.add_child(line)
	_info = Label.new()
	_info.size_flags_horizontal = SIZE_EXPAND_FILL
	_info.clip_text = true
	_info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	line.add_child(_info)
	_status = Label.new()
	_status.add_theme_color_override("font_color", GOLD)
	line.add_child(_status)

	_help = PanelContainer.new()
	_help.set_anchors_preset(PRESET_CENTER)
	_help.grow_horizontal = GROW_DIRECTION_BOTH
	_help.grow_vertical = GROW_DIRECTION_BOTH
	_help.visible = false
	add_child(_help)
	var sheet := Label.new()
	sheet.text = HELP
	_help.add_child(sheet)


func _process(_delta: float) -> void:
	if _status.text != "" and Time.get_ticks_msec() > _status_until:
		_status.text = ""


## Shows the screen for a level and fills the palette (the catalog has just been read again).
func open(level_name: String) -> void:
	_title.text = "EDICIÓN · " + level_name
	_thumbs.clear()
	visible = true
	fill()


func fill() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var filter := _search.text.strip_edges().to_lower()
	var groups := SpriteCatalog.groups(_folder)
	var names := groups.keys()
	names.sort_custom(func(a: String, b: String) -> bool: return SpriteCatalog.group_label(a) < SpriteCatalog.group_label(b))
	var shown := 0
	for group: String in names:
		var label := SpriteCatalog.group_label(group)
		if filter != "" and not (filter in label.to_lower() or filter in group.to_lower()):
			continue
		var item := Button.new()
		item.set_meta("group", group)
		item.custom_minimum_size = Vector2(28, 28)
		item.toggle_mode = true
		item.button_group = _items
		item.focus_mode = FOCUS_NONE
		item.icon = _thumb(group)
		item.expand_icon = true
		item.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		var views := 0
		for model: Dictionary in groups[group].values():
			views += model.size()
		var text := label + (" · %d dibujos" % views if views > 1 else "")
		item.mouse_entered.connect(func() -> void: _name.text = text)
		item.toggled.connect(func(on: bool) -> void:
			if on:
				picked.emit(group)
			elif _items.get_pressed_button() == null:
				picked.emit(""))
		_grid.add_child(item)
		shown += 1
	if names.is_empty():
		_name.text = "Vacío: deja imágenes en " + SpriteCatalog.FOLDERS[_folder].trim_prefix("res://")
	else:
		_name.text = "%d objetos" % shown


## Lets go of the chosen palette item (the edit mode dropped it).
func release() -> void:
	var item := _items.get_pressed_button()
	if item:
		item.set_pressed_no_signal(false)


func info(text: String) -> void:
	_info.text = text


func say(text: String) -> void:
	_status.text = text + "  "
	_status_until = Time.get_ticks_msec() + 2500


func toggle_help() -> void:
	_help.visible = not _help.visible


func toggle_side() -> void:
	_side.visible = not _side.visible


## Is this point of the screen on the panel (where clicks are not for the world)?
func covers(point: Vector2) -> bool:
	for part: Control in [_side, _bar, _help]:
		if part.visible and part.get_global_rect().has_point(point):
			return true
	return false


func _thumb(group: String) -> Texture2D:
	if _thumbs.has(group):
		return _thumbs[group]
	var tex := SpriteCatalog.preview(SpriteCatalog.default_key(group))
	var out := tex
	if tex:
		var img := SpriteCatalog.image_of(tex)
		var fit := minf(1.0, 24.0 / maxf(img.get_width(), img.get_height()))
		if fit < 1.0:
			out = ImageTexture.create_from_image(SpriteCatalog.shrink(img, maxi(1, roundi(img.get_height() * fit))))
	_thumbs[group] = out
	return out


func _theme() -> Theme:
	var t := Theme.new()
	t.default_font = FONT
	t.default_font_size = 11
	t.set_color("font_color", "Label", INK)
	t.set_stylebox("panel", "PanelContainer", _box(Color(0.07, 0.09, 0.18, 0.93), Color("c9a24a"), 4))
	t.set_stylebox("normal", "Button", _box(Color(0.14, 0.17, 0.3), Color(0.25, 0.3, 0.48), 2))
	t.set_stylebox("hover", "Button", _box(Color(0.2, 0.24, 0.42), Color("c9a24a"), 2))
	t.set_stylebox("pressed", "Button", _box(Color(0.42, 0.33, 0.12), GOLD, 2))
	t.set_stylebox("hover_pressed", "Button", _box(Color(0.42, 0.33, 0.12), GOLD, 2))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_focus_color"]:
		t.set_color(state, "Button", INK)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_hover_pressed_color", "Button", GOLD)
	t.set_stylebox("normal", "LineEdit", _box(Color(0.03, 0.04, 0.09), Color(0.25, 0.3, 0.48), 2))
	t.set_stylebox("focus", "LineEdit", _box(Color(0.03, 0.04, 0.09), GOLD, 2))
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", Color(INK, 0.45))
	t.set_color("caret_color", "LineEdit", GOLD)
	t.set_constant("separation", "VBoxContainer", 3)
	t.set_constant("separation", "HBoxContainer", 2)
	t.set_constant("h_separation", "GridContainer", 2)
	t.set_constant("v_separation", "GridContainer", 2)
	t.set_stylebox("scroll", "VScrollBar", _box(Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), 1))
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		t.set_stylebox(state, "VScrollBar", _box(Color("c9a24a"), Color("c9a24a"), 1))
	return t


func _box(bg: Color, border: Color, margin: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1 if border.a > 0.0 else 0)
	box.set_content_margin_all(margin)
	box.anti_aliasing = false
	return box
