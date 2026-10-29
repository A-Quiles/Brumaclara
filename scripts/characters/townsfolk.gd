extends CharacterBody3D
## A person of the town. It strolls around its spot (`wander`), walks a `route` through the streets
## (stopping a moment at each point), or stands still. F near it talks: first whatever the story
## (Quests) has to say, else its own lines one by one in the dialogue box; a person with a `shop`
## then offers its goods (ShopMenu).

@export var lines: PackedStringArray = []
@export var wander := 0.0  ## how far from its spot it strolls; 0 stands still
@export var speed := 1.6
## points it walks through in order, round and round (world positions; empty: wander or stand)
@export var route: PackedVector3Array = []
@export var pause := 2.5  ## seconds it stops at each point of the route
## goods it sells: item id -> price in coins (empty: not a merchant)
@export var shop: Dictionary = {}

var _home := Vector3.ZERO
var _target := Vector3.ZERO
var _wait := 0.0
var _facing := "down"
var _line := 0
var _hero_near := false
var _leg := 0
var _stuck := 0.0
var _last := Vector3.ZERO
var _talking := false

@onready var _sprite: AnimatedSprite3D = $Sprite


func _ready() -> void:
	_home = global_position
	_target = route[0] if not route.is_empty() else _home
	_wait = randf_range(0.5, 3.0)
	$Reach.body_entered.connect(func(_body: Node3D) -> void: _hero_near = true)
	$Reach.body_exited.connect(func(_body: Node3D) -> void: _hero_near = false)


## Moves it somewhere else for good (the edit mode): that becomes the spot it stays around.
func place(pos: Vector3) -> void:
	global_position = pos
	_home = pos
	_target = pos
	route = PackedVector3Array()


func _physics_process(delta: float) -> void:
	if _hero_near and Input.is_action_just_pressed("interact") and not _talking:
		_talk()
	var step := Vector3(_target.x - global_position.x, 0, _target.z - global_position.z)
	var walks := not route.is_empty() or wander > 0.0
	if _hero_near or _talking or not walks or step.length() < 0.2:
		velocity = Vector3.ZERO
		_wait -= delta
		if _wait <= 0.0 and walks and not _hero_near and not _talking:
			_next_target()
	else:
		velocity = step.normalized() * speed
		_face(View.to_screen(step))
		_stuck += delta
		if _stuck > 1.5:  # something in the way: give up this point
			if global_position.distance_to(_last) < 0.4:
				_next_target()
			_stuck = 0.0
			_last = global_position
	velocity.y = 0.0 if is_on_floor() else -9.0
	move_and_slide()
	_play("walk" if Vector2(velocity.x, velocity.z).length() > 0.1 else "idle")


func _next_target() -> void:
	if not route.is_empty():
		_leg = (_leg + 1) % route.size()
		_target = route[_leg]
		_wait = pause * randf_range(0.6, 1.4)
	else:
		_target = _home + Vector3(randf_range(-wander, wander), 0, randf_range(-wander, wander))
		_wait = randf_range(2.0, 5.0)
	_last = global_position
	_stuck = 0.0


func face_hero() -> void:
	var hero := get_tree().get_first_node_in_group("player") as Node3D
	if hero:
		_face(View.to_screen(hero.global_position - global_position))
		_play("idle")


func _talk() -> void:
	_talking = true
	face_hero()
	if not await Quests.talk(name, self):
		if not lines.is_empty():
			await Dialogue.run(self, display_name(), PackedStringArray([lines[_line]]))
			_line = (_line + 1) % lines.size()
		if not shop.is_empty():
			var menu := ShopMenu.new()
			menu.seller = display_name()
			menu.goods = shop
			get_tree().get_first_node_in_group("hud").add_child(menu)
			await menu.tree_exited
	await get_tree().physics_frame  # the key that closed the box must not open it again
	await get_tree().physics_frame
	_talking = false


func display_name() -> String:
	return str(get_meta("display_name", name))


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
