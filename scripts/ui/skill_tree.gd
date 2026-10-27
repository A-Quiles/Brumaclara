class_name SkillTree
extends Control
## The skill-tree screen (T, or the shrine's key): one tab per affinity plus the adventurer's common
## trunk, the tree as columns (branches) by rows (tiers), the selected node's description, learning,
## equipping skills in the four slots and the ultimate, attribute points. At a shrine it also chooses
## the first affinity, awakens the others and takes the learning points back (docs/arbol_habilidades.md).

signal closed

const FONT := preload("res://assets/fonts/pixelify_sans_medium.woff")
const GOLD := Color("ffd34a")
const INK := Color("f4e9c8")
const DIM := Color(0.62, 0.66, 0.8)
const NODE := 24
const COLUMN := 104
const ROW := 40
const GRID := Vector2(96, 62)
const KEYS := ["Q", "E", "R", "C"]
const GLYPH := {"pasiva": "P", "mejora": "+", "definitiva": "X"}

var at_shrine := false

var _tab: StringName = &"tronco"
var _selected: StringName = &""
var _buttons := {}
var _tab_buttons := {}
var _grid: Control
var _info: VBoxContainer
var _head: Label
var _points: Label
var _bottom: HBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	position = Vector2.ZERO
	size = get_viewport_rect().size
	theme = Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 11
	_build()
	_tab = Progress.principal if Progress.principal != &"" else &"tronco"
	_show_tab(_tab)
	Progress.changed.connect(_refresh)


func _exit_tree() -> void:
	if Progress.changed.is_connected(_refresh):
		Progress.changed.disconnect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("open_tree") or event.is_action("ui_cancel"):
		closed.emit()
	elif event.is_action("move_right") or event.is_action("move_left"):
		var tabs: Array = _tab_buttons.keys()
		_show_tab(tabs[posmod(tabs.find(_tab) + (1 if event.is_action("move_right") else -1), tabs.size())])
	elif event.is_action("ui_accept") and _selected != &"" and Progress.can_learn(_selected) == "":
		Progress.learn(_selected)
	else:
		return
	get_viewport().set_input_as_handled()


# --- layout -----------------------------------------------------------------------------------

func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.04, 0.09, 0.985)
	shade.size = get_viewport_rect().size
	add_child(shade)
	_head = _label("", Vector2(10, 6), GOLD, 14)
	add_child(_head)
	_points = _label("", Vector2(300, 8), Color("8fe8ff"))
	add_child(_points)
	var column := VBoxContainer.new()
	column.position = Vector2(8, 30)
	column.add_theme_constant_override("separation", 2)
	add_child(column)
	for tree in Progress.TREE_IDS:
		var b := Button.new()
		b.text = Affinity.NAMES.get(tree, "Aventurero")
		b.custom_minimum_size = Vector2(76, 22)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = FOCUS_NONE
		b.pressed.connect(_show_tab.bind(tree))
		column.add_child(b)
		_tab_buttons[tree] = b
	_grid = Control.new()
	_grid.position = Vector2.ZERO
	add_child(_grid)
	_info = VBoxContainer.new()
	_info.position = Vector2(430, 34)
	_info.custom_minimum_size = Vector2(200, 0)
	_info.size = Vector2(200, 260)
	_info.add_theme_constant_override("separation", 4)
	add_child(_info)
	_bottom = HBoxContainer.new()
	_bottom.position = Vector2(10, 322)
	_bottom.add_theme_constant_override("separation", 6)
	add_child(_bottom)
	var hint := _label("Clic: elegir · Intro: aprender · ←/→: pestañas · T o Esc: cerrar", Vector2(10, 346), DIM, 11)
	add_child(hint)


func _label(text: String, at: Vector2, colour: Color, size := 11) -> Label:
	var l := Label.new()
	l.text = text
	l.position = at
	l.add_theme_color_override("font_color", colour)
	l.add_theme_font_size_override("font_size", size)
	return l


func _show_tab(tree: StringName) -> void:
	_tab = tree
	_selected = &""
	_refresh()


func _refresh() -> void:
	_head.text = "ÁRBOL DE HABILIDADES" + ("  ·  SANTUARIO" if at_shrine else "")
	_points.text = "Nivel %d   PA: %d   Puntos de atributo: %d" % [Progress.level, Progress.pa, Progress.attr_points]
	for tree: StringName in _tab_buttons:
		var b: Button = _tab_buttons[tree]
		var open := tree == &"tronco" or tree == Progress.principal or tree in Progress.awakened
		b.modulate = Affinity.color(tree) if open else Color(1, 1, 1, 0.45)
		b.text = Affinity.NAMES.get(tree, "Aventurero") + ("" if open else " ·")
		b.flat = tree != _tab
	for child in _grid.get_children():
		child.queue_free()
	_buttons.clear()
	_draw_tree()
	_draw_info()
	_draw_bottom()


func _draw_tree() -> void:
	var nodes: Array = Progress.trees[_tab].nodes
	var colour := Affinity.color(_tab) if _tab != &"tronco" else Affinity.color(&"")
	var branches := {}
	for n: Dictionary in nodes:
		if n.branch >= 0:
			branches[int(n.branch)] = n.branch_name
	for b: int in branches:
		var l := _label(str(branches[b]).split(" (")[0], GRID + Vector2(b * COLUMN, -26), colour, 11)
		l.custom_minimum_size = Vector2(COLUMN - 6, 0)
		l.size = Vector2(COLUMN - 6, 24)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.clip_text = true
		_grid.add_child(l)
	var slots := {}  # (branch, tier) -> how many nodes are already in that cell
	for n: Dictionary in nodes:
		var key := Vector2i(n.branch, n.tier)
		var k: int = slots.get(key, 0)
		slots[key] = k + 1
		var x: float = GRID.x + n.branch * COLUMN + k * (NODE + 2)
		var y: float = GRID.y + (n.tier - 1) * ROW
		if n.branch < 0:  # the ultimate sits alone under the branches
			x = GRID.x + COLUMN
			y = GRID.y + 5 * ROW
		_grid.add_child(_node_button(n, Vector2(x, y), colour))


func _node_button(n: Dictionary, at: Vector2, colour: Color) -> Button:
	var id := StringName(n.id)
	var b := Button.new()
	b.position = at
	b.custom_minimum_size = Vector2(NODE, NODE)
	b.size = Vector2(NODE, NODE)
	b.focus_mode = FOCUS_NONE
	b.clip_text = true
	var learned := id in Progress.learned
	var reason := "" if learned else Progress.can_learn(id)
	var can := reason == ""
	var fill := colour.darkened(0.35) if learned else (Color(0.1, 0.12, 0.22) if can else Color(0.07, 0.08, 0.13))
	var border := GOLD if (id == _selected) else (colour if learned else (Color("c9a24a") if can else Color(0.3, 0.32, 0.4)))
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2 if id == _selected else 1)
	style.anti_aliasing = false
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, style)
	var icon: Texture2D = null
	var mark := ""
	if n.type in ["activa", "definitiva"] and n.get("skill") != null and n.get("implemented", true):
		icon = HUD.icon_for(Progress.skill(id))
	elif n.type == "mejora" and n.get("requires", []).size() > 0:
		var base := StringName(n.requires[0])
		icon = SkillIcons.for_skill(base)
		if icon == null and Progress.nodes.has(base) and Progress.nodes[base].get("skill") != null:
			icon = HUD.icon_for(Progress.skill(base))
		mark = "+"
	elif n.type == "pasiva":
		icon = SkillIcons.passive(str(n.tree), hash(n.id) % 2 == 0, id)
		mark = "P" if icon == null else ""
	if icon:
		b.icon = icon
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if mark != "":  # an upgrade: its skill's icon with a gold mark in the corner
			var badge := Label.new()
			badge.text = mark
			badge.position = Vector2(NODE - 10, -4)
			badge.add_theme_color_override("font_color", GOLD)
			badge.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08))
			badge.add_theme_constant_override("outline_size", 4)
			badge.add_theme_font_size_override("font_size", 11)
			b.add_child(badge)
			b.self_modulate = Color(0.8, 0.8, 0.85)
	else:
		b.text = GLYPH.get(n.type, "·")
		b.add_theme_color_override("font_color", INK if learned or can else DIM)
	if n.get("implemented", true) == false:
		b.modulate = Color(1, 1, 1, 0.35)
	elif not learned and not can:
		b.modulate = Color(1, 1, 1, 0.6)
	b.pressed.connect(func() -> void:
		_selected = id
		_refresh())
	b.tooltip_text = n.name
	_buttons[id] = b
	return b


func _draw_info() -> void:
	for child in _info.get_children():
		child.queue_free()
	if _selected == &"":
		_draw_tab_info()
		return
	var n: Dictionary = Progress.nodes[_selected]
	var colour := Affinity.color(StringName(n.tree)) if n.tree != &"tronco" else GOLD
	_info.add_child(_text(n.name, colour, 14))
	_info.add_child(_text("%s · nivel %s · %d PA" % [str(n.type).capitalize(), Progress.roman(int(n.tier)), int(n.cost)], DIM, 11))
	_info.add_child(_text(n.desc, INK, 11))
	if n.type in ["activa", "definitiva"] and n.get("skill") != null and n.get("implemented", true):
		var s := Progress.skill(_selected)
		var bits: Array[String] = []
		if s.mana_cost > 0:
			bits.append("Maná %d" % roundi(s.mana_cost))
		bits.append("Recarga %s s" % str(snappedf(s.cooldown, 0.1)))
		if s.damage > 0:
			bits.append("Daño %d" % s.damage)
		_info.add_child(_text(" · ".join(bits), Color("9fc8ff"), 11))
	var learned := _selected in Progress.learned
	var reason := "Aprendido" if learned else Progress.can_learn(_selected)
	if reason != "" and not learned:
		_info.add_child(_text(reason, Color("ff9a80"), 11))
	elif learned:
		_info.add_child(_text("Aprendido", Color("8fe88f"), 11))
	if not learned and reason == "":
		_info.add_child(_button("Aprender (%d PA)" % int(n.cost), func() -> void: Progress.learn(_selected), GOLD))
	if learned and n.type == "activa":
		var row := HBoxContainer.new()
		row.add_child(_text("Ranura:", DIM, 11))
		for i in Progress.SLOTS:
			var slot := i
			var b := _button(KEYS[i], func() -> void: Progress.equip(slot, _selected), GOLD if Progress.equipped[i] == _selected else INK)
			b.custom_minimum_size = Vector2(26, 0)
			row.add_child(b)
		_info.add_child(row)
	elif learned and n.type == "definitiva":
		_info.add_child(_button("Equipar (X)" if Progress.ultimate != _selected else "Equipada (X)", func() -> void: Progress.equip_ultimate(_selected), GOLD))


func _draw_tab_info() -> void:
	var tree := _tab
	if tree == &"tronco":
		_info.add_child(_text("Aventurero", GOLD, 14))
		_info.add_child(_text("Técnicas de todo viajero: espada, esquiva, resistencia y exploración. Sirve a cualquier afinidad.", INK, 11))
		return
	var colour := Affinity.color(tree)
	_info.add_child(_text(Affinity.NAMES[tree], colour, 14))
	_info.add_child(_text(Affinity.ROLES[tree], DIM, 11))
	if tree == Progress.principal:
		_info.add_child(_text("Tu afinidad principal: llega al nivel V.", INK, 11))
	elif tree in Progress.awakened:
		_info.add_child(_text("Afinidad secundaria despertada: llega al nivel III.", INK, 11))
	elif Progress.principal == &"":
		_info.add_child(_text("Tu primera afinidad se elige en un santuario y define tu camino: llegará al nivel V; las otras se despiertan después y llegan al III.", INK, 11))
		if at_shrine:
			_info.add_child(_button("Elegir %s como principal" % Affinity.NAMES[tree], func() -> void: Progress.choose_principal(tree), colour))
	else:
		var why := Progress.can_awaken(tree)
		_info.add_child(_text("Dormida. " + (why if why != "" else "Puedes despertarla."), INK, 11))
		if at_shrine and why == "":
			_info.add_child(_button("Despertar %s" % Affinity.NAMES[tree], func() -> void: Progress.awaken(tree), colour))
		elif why == "" and not at_shrine:
			_info.add_child(_text("Hazlo en un santuario.", DIM, 11))


func _draw_bottom() -> void:
	for child in _bottom.get_children():
		child.queue_free()
	for attr in Progress.ATTRS:
		var a: String = attr
		var l := _text("%s %d" % [a.capitalize(), Progress.attr(a)], INK, 11)
		_bottom.add_child(l)
		var b := _button("+", func() -> void: Progress.add_attr(a), GOLD)
		b.disabled = Progress.attr_points <= 0 or Progress.attrs[a] >= Progress.ATTR_CAP[a]
		b.custom_minimum_size = Vector2(18, 0)
		_bottom.add_child(b)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(8, 0)
		_bottom.add_child(gap)
	if at_shrine and Progress.principal != &"":
		_bottom.add_child(_button("Devolver todos los puntos", Progress.respec, Color("ff9a80")))


func _text(text: String, colour: Color, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(196, 0)
	l.add_theme_color_override("font_color", colour)
	l.add_theme_font_size_override("font_size", size)
	return l


func _button(text: String, action: Callable, colour: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = FOCUS_NONE
	b.add_theme_color_override("font_color", colour)
	b.pressed.connect(action)
	return b
