extends CharacterBody3D
## A person of the town: strolls around its spot (or stands still if `wander` is 0), turns to the
## hero when spoken to and says its lines one by one in the HUD's message line.

@export var lines: PackedStringArray = []
@export var wander := 0.0  ## how far from its spot it strolls; 0 stands still
@export var speed := 1.6

var _home := Vector3.ZERO
var _target := Vector3.ZERO
var _wait := 0.0
var _facing := "down"
var _line := 0
var _hero_near := false

@onready var _sprite: AnimatedSprite3D = $Sprite


func _ready() -> void:
	_home = global_position
	_target = _home
	_wait = randf_range(0.5, 3.0)
	$Reach.body_entered.connect(func(_body: Node3D) -> void: _hero_near = true)
	$Reach.body_exited.connect(func(_body: Node3D) -> void: _hero_near = false)


## Moves it somewhere else for good (the edit mode): that becomes the spot it stays around.
func place(pos: Vector3) -> void:
	global_position = pos
	_home = pos
	_target = pos


func _physics_process(delta: float) -> void:
	if _hero_near and not lines.is_empty() and Input.is_action_just_pressed("interact"):
		_talk()
	var step := Vector3(_target.x - global_position.x, 0, _target.z - global_position.z)
	if _hero_near or wander <= 0.0 or step.length() < 0.15:
		velocity = Vector3.ZERO
		_wait -= delta
		if _wait <= 0.0 and wander > 0.0 and not _hero_near:
			_target = _home + Vector3(randf_range(-wander, wander), 0, randf_range(-wander, wander))
			_wait = randf_range(2.0, 5.0)
	else:
		velocity = step.normalized() * speed
		_face(View.to_screen(step))
	move_and_slide()
	_play("walk" if velocity.length() > 0.1 else "idle")


func _talk() -> void:
	var hero := get_tree().get_first_node_in_group("player") as Node3D
	if hero:
		_face(View.to_screen(hero.global_position - global_position))
	get_tree().call_group("hud", "say", lines[_line], 5.0)
	_line = (_line + 1) % lines.size()


func _face(dir: Vector2) -> void:
	if dir.length() < 0.01:
		return
	_facing = "side" if absf(dir.x) > absf(dir.y) else ("up" if dir.y < 0.0 else "down")
	_sprite.flip_h = _facing == "side" and dir.x < 0.0


func _play(state: String) -> void:
	var anim := StringName(state + "_" + _facing)
	if not _sprite.sprite_frames.has_animation(anim):  # people drawn only from the front
		anim = StringName(state + "_down")
	if _sprite.animation != anim:
		_sprite.play(anim)
