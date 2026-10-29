class_name Inventory
extends Control
## The inventory screen (Tab): the items the hero carries (Progress.items), the selected one's
## description, and Enter to use it. Up/Down choose, Tab or Esc close.

signal closed

const FONT := preload("res://assets/fonts/pixelify_sans_medium.woff")
const GOLD := Color("ffd34a")
const INK := Color("f4e9c8")
const DIM := Color(0.62, 0.66, 0.8)

var player: Node  ## the hero, who gets the item's effect

var _row := 0
var _list: VBoxContainer
var _info: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	position = Vector2.ZERO
	size = get_viewport_rect().size
	theme = Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 11
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.04, 0.09, 0.985)
	shade.size = size
	add_child(shade)
	add_child(_label("INVENTARIO", Vector2(10, 6), GOLD, 14))
	add_child(_label("Arriba/abajo: elegir · Intro: usar · Tab: cerrar", Vector2(10, 340), DIM))
	_list = VBoxContainer.new()
	_list.position = Vector2(20, 34)
	add_child(_list)
	_info = _label("", Vector2(330, 40), INK)
	_info.custom_minimum_size = Vector2(280, 0)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_info)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var ids := Progress.items.keys()
	if event.is_action("open_inventory") or event.is_action("ui_cancel"):
		closed.emit()
	elif event.is_action("move_up") and not ids.is_empty():
		_row = posmod(_row - 1, ids.size())
	elif event.is_action("move_down") and not ids.is_empty():
		_row = posmod(_row + 1, ids.size())
	elif event.is_action("ui_accept") and not ids.is_empty():
		_use(ids[_row])
	else:
		return
	get_viewport().set_input_as_handled()
	_refresh()


func _use(id: StringName) -> void:
	var item: Dictionary = Progress.ITEMS[id]
	if player:
		player.restore(float(item.get("mp", 0)), int(item.get("hp", 0)))
	Progress.add_item(id, -1)


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var ids := Progress.items.keys()
	_row = clampi(_row, 0, maxi(ids.size() - 1, 0))
	if ids.is_empty():
		_list.add_child(_label("Vacío. Abre cofres para encontrar objetos.", Vector2.ZERO, DIM))
		_info.text = ""
		return
	for i in ids.size():
		var on := i == _row
		_list.add_child(_label("%s %s  x%d" % [">" if on else " ", Progress.ITEMS[ids[i]].name, Progress.items[ids[i]]],
				Vector2.ZERO, GOLD if on else INK))
	_info.text = Progress.ITEMS[ids[_row]].text


func _label(text: String, at: Vector2, colour: Color, font_size := 11) -> Label:
	var l := Label.new()
	l.text = text
	l.position = at
	l.add_theme_color_override("font_color", colour)
	l.add_theme_font_size_override("font_size", font_size)
	return l
