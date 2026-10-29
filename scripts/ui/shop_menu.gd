class_name ShopMenu
extends Control
## A merchant's goods (townsfolk.gd `shop`): item, price and how many the hero carries. Arrows or the
## mouse choose, Intro (or a click) buys one, Esc or F closes. The game waits while it is open.

const FONT := preload("res://assets/fonts/pixelify_sans_medium.woff")
const GOLD := Color("ffd34a")
const INK := Color("f4e9c8")
const DIM := Color(0.62, 0.66, 0.8)
const BAD := Color(1.0, 0.45, 0.4)

var seller := ""
var goods := {}  ## item id -> price

var _ids: Array = []
var _selected := 0
var _rows: Array[Label] = []
var _coins: Label
var _note: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = get_viewport_rect().size
	get_tree().paused = true
	_ids = goods.keys().filter(func(id: Variant) -> bool: return Progress.ITEMS.has(StringName(id)))
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.04, 0.09, 0.9)
	shade.size = size
	add_child(shade)
	var panel := ColorRect.new()
	panel.color = Color(0.06, 0.07, 0.13, 1)
	panel.position = Vector2(150, 70)
	panel.size = Vector2(340, 60 + _ids.size() * 26)
	add_child(panel)
	_label("TIENDA DE " + seller.to_upper(), Vector2(160, 76), GOLD, 13)
	_coins = _label("", Vector2(160, 94), GOLD, 10)
	for i in _ids.size():
		var icon := TextureRect.new()
		icon.texture = SkillIcons.item(StringName(_ids[i]))
		icon.position = Vector2(164, 112 + i * 26)
		icon.modulate = Progress.ITEMS[StringName(_ids[i])].get("tint", Color.WHITE)
		add_child(icon)
		var row := _label("", Vector2(192, 116 + i * 26), INK, 11)
		row.mouse_filter = MOUSE_FILTER_STOP
		row.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed:
				_select(i)
				buy())
		_rows.append(row)
	_note = _label("", Vector2(160, 76 + 60 + _ids.size() * 26), INK, 10)
	_label("Flechas: elegir · Intro o clic: comprar · Esc o F: salir", Vector2(10, 346), DIM, 10)
	_select(0)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("ui_cancel") or event.is_action("interact"):
		get_tree().paused = false
		queue_free()
	elif event.is_action("move_down") or event.is_action("ui_down"):
		_select(_selected + 1)
	elif event.is_action("move_up") or event.is_action("ui_up"):
		_select(_selected - 1)
	elif event.is_action("ui_accept"):
		buy()
	else:
		return
	get_viewport().set_input_as_handled()


## Buys one of the selected item; returns whether there was money for it.
func buy() -> bool:
	if _ids.is_empty():
		return false
	var id := StringName(_ids[_selected])
	var price := int(goods[_ids[_selected]])
	if Progress.count(&"monedas") < price:
		_note.text = "No te llega: cuesta %d monedas." % price
		_note.add_theme_color_override("font_color", BAD)
		return false
	Progress.take_item(&"monedas", price)
	Progress.add_item(id)
	_note.text = "Has comprado: " + Progress.ITEMS[id].name
	_note.add_theme_color_override("font_color", GOLD)
	_select(_selected)
	return true


func _select(index: int) -> void:
	_selected = wrapi(index, 0, maxi(1, _ids.size()))
	_coins.text = "Tus monedas: %d" % Progress.count(&"monedas")
	for i in _rows.size():
		var id := StringName(_ids[i])
		_rows[i].text = "%s%s — %d monedas  (llevas %d)" % ["> " if i == _selected else "  ", Progress.ITEMS[id].name,
				int(goods[_ids[i]]), Progress.count(id)]
		_rows[i].add_theme_color_override("font_color", GOLD if i == _selected else INK)


func _label(text: String, at: Vector2, colour: Color, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = at
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(l)
	return l
