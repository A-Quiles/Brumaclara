extends CanvasLayer
## On-screen HUD: level, health, mana and experience bars, the four action slots with their
## cooldowns, and the message line at the bottom (the controls, or a message for a few seconds).

## action slot -> skill name used by the player's cooldowns
const SLOTS := {"SlotSword": &"", "SlotBolt": &"bolt", "SlotBurst": &"burst", "SlotDash": &"dodge"}

@export var player_path: NodePath

var _cooldown_total := {}  # skill -> length of its last cooldown

@onready var _player: Node = get_node_or_null(player_path)
@onready var _hint: String = %Message.text


func _ready() -> void:
	if _player == null:
		return
	_player.stats_changed.connect(_on_stats_changed)
	_player.progressed.connect(_on_progressed)
	_player.said.connect(say)
	_player.cooldown_started.connect(func(skill: StringName, seconds: float) -> void: _cooldown_total[skill] = seconds)


func _process(_delta: float) -> void:
	if _player == null:
		return
	for slot in SLOTS:
		var skill: StringName = SLOTS[slot]
		var shade: ColorRect = get_node("%" + slot).get_node("Cooldown")
		var left: float = _player.cooldown_left(skill) if skill else 0.0
		var total: float = _cooldown_total.get(skill, 1.0)
		shade.size.y = roundf(shade.get_parent().size.y * clampf(left / total, 0.0, 1.0))
		shade.position.y = shade.get_parent().size.y - shade.size.y


func _on_stats_changed(hp: int, max_hp: int, mp: float, max_mp: float) -> void:
	%HPBar.max_value = max_hp
	%HPBar.value = hp
	%MPBar.max_value = max_mp
	%MPBar.value = mp


func _on_progressed(level: int, xp: int, xp_next: int) -> void:
	%Level.text = "Nv. %d" % level
	%XPBar.max_value = xp_next
	%XPBar.value = xp


func say(text: String, seconds := 4.0) -> void:
	%Message.text = text
	await get_tree().create_timer(seconds).timeout
	if %Message.text == text:
		%Message.text = _hint
