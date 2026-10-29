class_name HUD
extends CanvasLayer
## On-screen HUD: level, health, mana and experience bars, the action slots (sword, the four equipped
## skills, the ultimate and the dodge) with their cooldowns, the points waiting to be spent and the
## message line at the bottom (the controls, or a message for a few seconds).

const ICON_BOLT := preload("res://assets/ui/icon_bolt.png")
const ICON_BURST := preload("res://assets/ui/icon_burst.png")
const ICON_DASH := preload("res://assets/ui/icon_dash.png")
const FONT := preload("res://assets/fonts/pixelify_sans_medium.woff")
const KEYS := ["Q", "E", "R", "C"]
const SLOT := 27
const LEFT := 448

@export var player_path: NodePath

var _skill_slots: Array[TextureRect] = []
var _ultimate_slot: TextureRect
var _points: Label
var _clock: Label
var _goal: Label
var _tree: SkillTree
var _inventory: Inventory

@onready var _player: Node = get_node_or_null(player_path)
@onready var _hint: String = %Message.text


func _ready() -> void:
	%SlotSword.position.x = LEFT
	for i in Progress.SLOTS:
		_skill_slots.append(_make_slot(KEYS[i], LEFT + SLOT * (i + 1)))
	_ultimate_slot = _make_slot("X", LEFT + SLOT * 5)
	%SlotDash.position.x = LEFT + SLOT * 6
	_points = Label.new()
	_points.position = Vector2(8, 46)
	_points.add_theme_font_override("font", FONT)
	_points.add_theme_font_size_override("font_size", 11)
	_points.add_theme_color_override("font_color", Color("8fe8ff"))
	_points.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	add_child(_points)
	_clock = _points.duplicate()
	_clock.position = Vector2(596, 6)
	_clock.add_theme_color_override("font_color", Color("ffe6a8"))
	add_child(_clock)
	_goal = _points.duplicate()  # the story's next step (Quests), under the clock
	_goal.position = Vector2(330, 22)
	_goal.size = Vector2(304, 40)
	_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_goal.add_theme_font_size_override("font_size", 11)
	_goal.add_theme_color_override("font_color", Color("f4e9c8"))
	add_child(_goal)
	Quests.changed.connect(_refresh_goal)
	_refresh_goal()
	Progress.changed.connect(_refresh_slots)
	_refresh_slots()
	if _player == null:
		return
	_player.stats_changed.connect(_on_stats_changed)
	_player.progressed.connect(_on_progressed)
	_player.said.connect(say)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("open_tree"):
		open_tree(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory") and not get_tree().paused:
		open_inventory()
		get_viewport().set_input_as_handled()


## The inventory screen; the game waits while it is open.
func open_inventory() -> void:
	if _inventory != null or _tree != null:
		return
	_inventory = Inventory.new()
	_inventory.closed.connect(close_inventory)
	add_child(_inventory)
	get_tree().paused = true


func close_inventory() -> void:
	if _inventory == null:
		return
	_inventory.queue_free()
	_inventory = null
	get_tree().paused = false


## The skill-tree screen; the game waits while it is open. At a shrine it can also choose affinities.
func open_tree(at_shrine := false) -> void:
	if _tree != null or _inventory != null:
		return
	_tree = SkillTree.new()
	_tree.at_shrine = at_shrine
	_tree.closed.connect(close_tree)
	add_child(_tree)
	get_tree().paused = true


func close_tree() -> void:
	if _tree == null:
		return
	_tree.queue_free()
	_tree = null
	get_tree().paused = false


func _process(_delta: float) -> void:
	_clock.text = DayNight.clock_text() if DayNight.outdoors() else ""
	if _player == null:
		return
	for i in Progress.SLOTS:
		_shade(_skill_slots[i], Progress.equipped[i])
	_shade(_ultimate_slot, Progress.ultimate)
	_shade(%SlotDash, &"dodge")


func _shade(slot: TextureRect, id: StringName) -> void:
	var shade: ColorRect = slot.get_node("Cooldown")
	var frac: float = _player.cooldown_fraction(id) if id != &"" else 0.0
	shade.size.y = roundf(slot.size.y * frac)
	shade.position.y = slot.size.y - shade.size.y


func _refresh_slots() -> void:
	for i in Progress.SLOTS:
		_set_icon(_skill_slots[i], Progress.equipped[i])
	_set_icon(_ultimate_slot, Progress.ultimate)
	var waiting := Progress.pa + Progress.attr_points
	_points.text = "T: %d PA · %d atrib." % [Progress.pa, Progress.attr_points] if waiting > 0 else ""


func _set_icon(slot: TextureRect, id: StringName) -> void:
	if id == &"" or not Progress.nodes.has(id):
		slot.texture = ICON_BURST
		slot.modulate = Color(1, 1, 1, 0.18)
		return
	slot.modulate = Color.WHITE
	slot.texture = icon_for(Progress.skill(id))


## The icon of a skill: the bolt, burst or dash drawing in its affinity's colour.
static func icon_for(s: SkillData) -> Texture2D:
	var drawn := SkillIcons.for_skill(s.id)
	if drawn:
		return drawn
	var base: Texture2D = ICON_BURST
	match s.kind:
		SkillData.Kind.PROJECTILE, SkillData.Kind.CHAIN, SkillData.Kind.BEAM, SkillData.Kind.LINE, SkillData.Kind.PULL:
			base = ICON_BOLT
		SkillData.Kind.DASH, SkillData.Kind.BLINK:
			base = ICON_DASH
	return Affinity.texture(base, s.affinity)


func _make_slot(key: String, x: float) -> TextureRect:
	var slot := TextureRect.new()
	slot.position = Vector2(x, 302)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.texture = ICON_BURST
	var shade := ColorRect.new()
	shade.name = "Cooldown"
	shade.color = Color(0.02, 0.02, 0.06, 0.68)
	shade.size = Vector2(22, 0)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(shade)
	var label := Label.new()
	label.text = key
	label.position = Vector2(0, 21)
	label.size = Vector2(22, 15)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	slot.add_child(label)
	add_child(slot)
	return slot


func _on_stats_changed(hp: int, max_hp: int, mp: float, max_mp: float) -> void:
	%HPBar.max_value = max_hp
	%HPBar.value = hp
	%MPBar.max_value = max_mp
	%MPBar.value = mp


func _on_progressed(level: int, xp: int, xp_next: int) -> void:
	%Level.text = "Nv. %d" % level
	%XPBar.max_value = xp_next
	%XPBar.value = xp


func _refresh_goal() -> void:
	_goal.text = Quests.objective()


## A big banner in the middle of the screen for a few seconds (the end of a chapter).
func chapter_complete(title: String) -> void:
	var banner := Label.new()
	banner.text = title + "\ncompletado"
	banner.add_theme_font_override("font", FONT)
	banner.add_theme_font_size_override("font_size", 22)
	banner.add_theme_color_override("font_color", Color("ffd34a"))
	banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	banner.add_theme_constant_override("shadow_offset_y", 2)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.size = Vector2(640, 60)
	banner.position = Vector2(0, 120)
	banner.modulate.a = 0.0
	add_child(banner)
	var t := create_tween()
	t.tween_property(banner, "modulate:a", 1.0, 0.8)
	t.tween_interval(4.0)
	t.tween_property(banner, "modulate:a", 0.0, 1.2)
	t.tween_callback(banner.queue_free)


func say(text: String, seconds := 4.0) -> void:
	%Message.text = text
	await get_tree().create_timer(seconds).timeout
	if %Message.text == text:
		%Message.text = _hint
