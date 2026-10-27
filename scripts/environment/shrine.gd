extends StaticBody3D
## A rune shrine: with the hero beside it, the interact key opens the skill tree in shrine mode,
## where the hero chooses the first affinity, awakens the others and gets the learning points back.

var _hero_near := false

@onready var _prompt: Label3D = $Prompt


func _ready() -> void:
	$Reach.body_entered.connect(func(_body: Node3D) -> void: _set_near(true))
	$Reach.body_exited.connect(func(_body: Node3D) -> void: _set_near(false))
	_prompt.visible = false
	_prompt.text = "F: santuario"


func _physics_process(_delta: float) -> void:
	if _hero_near and Input.is_action_just_pressed("interact"):
		get_tree().call_group("hud", "open_tree", true)


func _set_near(near: bool) -> void:
	_hero_near = near
	_prompt.visible = near
