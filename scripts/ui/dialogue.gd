class_name Dialogue
extends Control
## The dialogue box at the bottom of the screen: who speaks, what they say (one line at a time,
## written out letter by letter) and, at the end, the choices if there are any. F, Intro, Espacio or a
## click go on; the arrows (or W/S) pick a choice. The game waits while it is open.
##   var pick := await Dialogue.run(self, "Mara", ["Hola.", "¿Buscas trabajo?"], ["Sí", "No"])

signal finished(choice: int)

const FONT := preload("res://assets/fonts/pixelify_sans_medium.woff")
const GOLD := Color("ffd34a")
const INK := Color("f4e9c8")
const DIM := Color(0.62, 0.66, 0.8)
const BOX := Rect2(24, 236, 592, 98)
const LETTERS_PER_SECOND := 55.0

var speaker := ""
var lines: PackedStringArray = []
var choices: PackedStringArray = []

var _line := 0
var _shown := 0.0
var _choice := 0
var _text: Label
var _name: Label
var _hint: Label
var _choice_labels: Array[Label] = []


## Shows a conversation on the HUD of `from`'s scene and returns the chosen option (0 with no choices).
static func run(from: Node, who: String, said: PackedStringArray, options: PackedStringArray = []) -> int:
	var d := Dialogue.new()
	d.speaker = who
	d.lines = said
	d.choices = options
	var host: Node = from.get_tree().get_first_node_in_group("hud")
	(host if host else from.get_tree().current_scene).add_child(d)
	return await d.finished


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = get_viewport_rect().size
	mouse_filter = MOUSE_FILTER_STOP
	get_tree().paused = true
	var frame := ColorRect.new()
	frame.color = Color("ffd34a")
	frame.position = BOX.position - Vector2(2, 2)
	frame.size = BOX.size + Vector2(4, 4)
	add_child(frame)
	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.06, 0.12, 0.97)
	panel.position = BOX.position
	panel.size = BOX.size
	add_child(panel)
	var tag := ColorRect.new()
	tag.color = Color(0.05, 0.06, 0.12, 0.97)
	tag.position = BOX.position + Vector2(8, -14)
	tag.size = Vector2(maxf(60.0, speaker.length() * 7.5 + 16.0), 14)
	add_child(tag)
	_name = _label(speaker, BOX.position + Vector2(16, -15), GOLD, 12)
	_text = _label("", BOX.position + Vector2(12, 8), INK, 11)
	_text.size = Vector2(BOX.size.x - 24, 60)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint = _label("", BOX.position + Vector2(BOX.size.x - 150, BOX.size.y - 15), DIM, 9)
	_hint.size = Vector2(140, 12)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if lines.is_empty():
		lines = [""]


func _process(delta: float) -> void:
	_shown += delta * LETTERS_PER_SECOND
	var full := lines[_line]
	_text.text = full.substr(0, int(_shown))
	var done := int(_shown) >= full.length()
	var last := _line == lines.size() - 1
	if done and last and not choices.is_empty() and _choice_labels.is_empty():
		_show_choices()
	_hint.text = "" if not done else ("F: continuar" if not last else ("Flechas + F: elegir" if not choices.is_empty() else "F: cerrar"))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if not _choice_labels.is_empty() and (event.is_action("move_up") or event.is_action("ui_up")):
		_pick(_choice - 1)
	elif not _choice_labels.is_empty() and (event.is_action("move_down") or event.is_action("ui_down")):
		_pick(_choice + 1)
	elif event.is_action("interact") or event.is_action("ui_accept") or event.is_action("dodge"):
		_advance()
	else:
		return
	get_viewport().set_input_as_handled()


func _advance() -> void:
	if int(_shown) < lines[_line].length():
		_shown = lines[_line].length()  # first press: the whole line at once
		return
	if _line < lines.size() - 1:
		_line += 1
		_shown = 0.0
		return
	if not choices.is_empty() and _choice_labels.is_empty():
		_show_choices()
		return
	get_tree().paused = false
	finished.emit(_choice)
	queue_free()


func _show_choices() -> void:
	_text.size.y = 22 if choices.size() > 2 else 36
	for i in choices.size():
		var l := _label("", BOX.position + Vector2(24, 48 - maxi(0, choices.size() - 3) * 12 + i * 12), INK, 10)
		l.mouse_filter = MOUSE_FILTER_STOP
		l.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed:
				_pick(i)
				_advance())
		_choice_labels.append(l)
	_pick(0)


func _pick(index: int) -> void:
	_choice = wrapi(index, 0, choices.size())
	for i in _choice_labels.size():
		_choice_labels[i].text = ("> " if i == _choice else "  ") + choices[i]
		_choice_labels[i].add_theme_color_override("font_color", GOLD if i == _choice else INK)


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
