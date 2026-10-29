extends StaticBody3D
## Treasure chest: when the hero stands next to it, a prompt appears; the interact key opens it
## (its opening frames play once), its coins burst out as experience orbs and the hero takes 20 coins and
## a potion (the inventory). It stays open.

@export var orb_scene: PackedScene
@export var orbs := 3
@export var xp_per_orb := 15
@export var message := "¡Un cofre escondido!"

var _hero_near := false
var _opened := false

@onready var _sprite: AnimatedSprite3D = $Sprite
@onready var _prompt: Label3D = $Prompt


func _ready() -> void:
	$Reach.body_entered.connect(func(_body: Node3D) -> void: _set_near(true))
	$Reach.body_exited.connect(func(_body: Node3D) -> void: _set_near(false))
	_prompt.visible = false


func _physics_process(_delta: float) -> void:
	if _hero_near and not _opened and Input.is_action_just_pressed("interact"):
		_open()


func _set_near(near: bool) -> void:
	_hero_near = near
	_prompt.visible = near and not _opened


func _open() -> void:
	_opened = true
	_prompt.visible = false
	_sprite.play("open")
	get_tree().call_group("hud", "say", message + "  +20 monedas, Poción de vida")
	Progress.add_item(&"monedas", 20)
	Progress.add_item(&"pocion")
	await _sprite.animation_finished
	for i in orbs:  # a small fan of orbs in front of the chest
		var orb: Node3D = orb_scene.instantiate()
		orb.amount = xp_per_orb
		get_parent().add_child(orb)
		var angle := PI * (0.25 + 0.5 * i / maxf(orbs - 1, 1))
		orb.global_position = global_position + Vector3(cos(angle), 0, sin(angle)) * 1.1
	_sprite.play("empty")
