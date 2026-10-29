class_name ArenaMenu
extends Control
## The board of the Patio de pruebas (arena.gd): every enemy of the bestiary by zone. Arrows or the
## mouse choose, Intro (or a click) calls the chosen one: a group of three, or a boss alone. The last
## two lines call a wave of the chosen zone or send every creature away. Esc closes; the game waits
## while it is open.

const FONT := preload("res://assets/fonts/pixelify_sans_medium.woff")
const GOLD := Color("ffd34a")
const INK := Color("f4e9c8")
const DIM := Color(0.62, 0.66, 0.8)
const COLS := 4
const ROW_H := 15

var arena: Node  ## arena.gd

var _entries: Array = []  # [label, callable]
var _selected := 0
var _buttons: Array[Button] = []
var _info: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = get_viewport_rect().size
	theme = Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 10
	get_tree().paused = true
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.04, 0.09, 0.96)
	shade.size = size
	add_child(shade)
	add_child(_label("PATIO DE PRUEBAS — llamar criaturas", Vector2(10, 6), GOLD, 14))
	var y := 30
	for group: Array in arena.roster():
		var list: Array = group[1]
		if list.is_empty():
			continue
		add_child(_label(group[0], Vector2(12, y), GOLD))
		y += 14
		for i in list.size():
			var d: EnemyData = list[i]
			var count := 1 if d.boss else 3
			var text := ("%s (jefe)" if d.boss else "%s ×3") % d.display_name
			_add(text, Vector2(18 + (i % COLS) * 152, y + (i / COLS) * ROW_H), arena.call_enemy.bind(d, count), d)
		y += ceili(list.size() / float(COLS)) * ROW_H + 4
		_add("» Oleada: uno de cada (" + group[0] + ")", Vector2(18, y), arena.call_wave.bind(list.filter(
				func(d: EnemyData) -> bool: return not d.boss)), null)
		y += ROW_H + 4
	_add("» Limpiar el patio", Vector2(18, y), arena.clear_enemies, null)
	_info = _label("", Vector2(10, 330), INK)
	add_child(_info)
	add_child(_label("Flechas o ratón: elegir · Intro o clic: llamar · Esc o F: cerrar", Vector2(10, 346), DIM))
	_select(0)


func _add(text: String, at: Vector2, action: Callable, data: EnemyData) -> void:
	var b := Button.new()
	b.text = text
	b.position = at
	b.size = Vector2(150, ROW_H - 1)
	b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = FOCUS_NONE
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", GOLD)
	var index := _entries.size()
	b.pressed.connect(func() -> void: _select(index); _run())
	b.mouse_entered.connect(_select.bind(index))
	add_child(b)
	_buttons.append(b)
	_entries.append([action, data])


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("ui_cancel") or event.is_action("interact"):
		close()
	elif event.is_action("move_down") or event.is_action("ui_down"):
		_select(_selected + 1)
	elif event.is_action("move_up") or event.is_action("ui_up"):
		_select(_selected - 1)
	elif event.is_action("ui_accept"):
		_run()
	else:
		return
	get_viewport().set_input_as_handled()


func close() -> void:
	get_tree().paused = false
	queue_free()


func _run() -> void:
	(_entries[_selected][0] as Callable).call()
	close()


func _select(index: int) -> void:
	_selected = wrapi(index, 0, _entries.size())
	for i in _buttons.size():
		_buttons[i].add_theme_color_override("font_color", GOLD if i == _selected else INK)
	var d: EnemyData = _entries[_selected][1]
	if d == null:
		_info.text = ""
		return
	var weak := ", ".join(d.weak.map(func(a: StringName) -> String: return str(a))) if not d.weak.is_empty() else "—"
	var resist := ", ".join(d.resist.map(func(a: StringName) -> String: return str(a))) if not d.resist.is_empty() else "—"
	_info.text = "%s · vida %d · daño %d · débil: %s · resiste: %s" % [d.display_name, d.max_hp, d.damage, weak, resist]


func _label(text: String, at: Vector2, colour: Color, font_size := 10) -> Label:
	var l := Label.new()
	l.text = text
	l.position = at
	l.add_theme_color_override("font_color", colour)
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = MOUSE_FILTER_IGNORE
	return l
