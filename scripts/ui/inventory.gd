class_name Inventory
extends Control
## The inventory screen (Tab): what the hero carries (Progress.inventory) as a grid of slots, the
## selected item's description, and "Usar" for the ones that restore health or mana. The game waits
## while it is open (hud.gd).

signal closed

const FONT := preload("res://assets/fonts/pixelify_sans_medium.woff")
const GOLD := Color("ffd34a")
const INK := Color("f4e9c8")
const DIM := Color(0.62, 0.66, 0.8)
const COLS := 6
const ROWS := 3
const SLOT := 44
const GRID := Vector2(20, 44)

var _selected := 0
var _slots: Array[Button] = []
var _coins: Label
var _info: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = get_viewport_rect().size
	theme = Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 11
	_build()
	_refresh()
	Progress.changed.connect(_refresh)


func _exit_tree() -> void:
	if Progress.changed.is_connected(_refresh):
		Progress.changed.disconnect(_refresh)


## The items shown in the grid, in the order of Progress.ITEMS (coins have their own counter).
func items() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in Progress.ITEMS:
		if id != &"monedas" and Progress.count(id) > 0:
			out.append(id)
	return out


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("inventory") or event.is_action("ui_cancel"):
		closed.emit()
	elif event.is_action("move_right") or event.is_action("move_left"):
		_select(_selected + (1 if event.is_action("move_right") else -1))
	elif event.is_action("move_down") or event.is_action("move_up"):
		_select(_selected + (COLS if event.is_action("move_down") else -COLS))
	elif event.is_action("ui_accept"):
		use_selected()
	else:
		return
	get_viewport().set_input_as_handled()


## Uses the selected item if it restores something; returns whether it was used.
func use_selected() -> bool:
	var list := items()
	if _selected >= list.size():
		return false
	var id := list[_selected]
	var it: Dictionary = Progress.ITEMS[id]
	var hero := get_tree().get_first_node_in_group("player")
	if hero == null or not (it.has("hp") or it.has("mp")) or not Progress.take_item(id):
		return false
	hero.restore(float(it.get("mp", 0)), int(it.get("hp", 0)))
	return true


func _select(index: int) -> void:
	_selected = clampi(index, 0, COLS * ROWS - 1)
	_refresh()


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.04, 0.09, 0.95)
	shade.size = size
	add_child(shade)
	add_child(_label("INVENTARIO", Vector2(10, 6), GOLD, 14))
	_coins = _label("", Vector2(20, 28), GOLD)
	add_child(_coins)
	for i in COLS * ROWS:
		var b := Button.new()
		b.position = GRID + Vector2(i % COLS, i / COLS) * SLOT
		b.size = Vector2(SLOT - 4, SLOT - 4)
		b.focus_mode = FOCUS_NONE
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.pressed.connect(_select.bind(i))
		add_child(b)
		_slots.append(b)
	_info = VBoxContainer.new()
	_info.position = Vector2(300, 44)
	_info.size = Vector2(320, 200)
	_info.add_theme_constant_override("separation", 6)
	add_child(_info)
	add_child(_label("Flechas o clic: elegir · Intro: usar · Tab o Esc: cerrar", Vector2(10, 346), DIM))


func _refresh() -> void:
	var list := items()
	_coins.text = "Monedas: %d" % Progress.count(&"monedas")
	for i in _slots.size():
		var b := _slots[i]
		var id: StringName = list[i] if i < list.size() else &""
		b.icon = SkillIcons.item(id) if id != &"" else null
		b.self_modulate = GOLD if i == _selected else Color(1, 1, 1, 0.75)
		b.tooltip_text = Progress.ITEMS[id].name if id != &"" else ""
		var tint: Color = Progress.ITEMS[id].get("tint", Color.WHITE) if id != &"" else Color.WHITE
		for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
			b.add_theme_color_override(state, tint)
		for child in b.get_children():
			child.queue_free()
		if id != &"":
			var n := _label(str(Progress.count(id)), Vector2(SLOT - 18, SLOT - 20), INK)
			n.add_theme_color_override("font_shadow_color", Color.BLACK)
			b.add_child(n)
	for child in _info.get_children():
		child.queue_free()
	if _selected >= list.size():
		_info.add_child(_label("Hueco vacío." if not list.is_empty() else "No llevas nada todavía.", Vector2.ZERO, DIM))
		return
	var id := list[_selected]
	var it: Dictionary = Progress.ITEMS[id]
	_info.add_child(_label("%s  ×%d" % [it.name, Progress.count(id)], Vector2.ZERO, GOLD, 13))
	var text := _label(it.text, Vector2.ZERO, INK)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(310, 0)
	_info.add_child(text)
	if it.has("hp") or it.has("mp"):
		var use := Button.new()
		use.text = "Usar (Intro)"
		use.focus_mode = FOCUS_NONE
		use.custom_minimum_size = Vector2(110, 22)
		use.size_flags_horizontal = SIZE_SHRINK_BEGIN
		use.add_theme_color_override("font_color", GOLD)
		use.pressed.connect(use_selected)
		_info.add_child(use)


func _label(text: String, at: Vector2, colour: Color, font_size := 11) -> Label:
	var l := Label.new()
	l.text = text
	l.position = at
	l.add_theme_color_override("font_color", colour)
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = MOUSE_FILTER_IGNORE
	return l
