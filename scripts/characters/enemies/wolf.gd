extends CharacterBody3D
## Lobo de bruma, a stalker corrupted by the Fractura. Prowls around its den, chases the hero on
## sight, crouches with glowing eyes (the warning to dodge), pounces in a straight line and stays
## open for a moment after landing. Drops experience and comes back after a while.

enum State { PROWL, CHASE, WINDUP, POUNCE, RECOVER, HURT, DEAD }

const GRAVITY := 30.0

@export var detect_radius := 7.5
@export var give_up_radius := 13.0
@export var attack_range := 3.6
@export var speed := 4.0
@export var pounce_speed := 12.5
@export var windup_seconds := 0.6
@export var xp_reward := 30
@export var respawn_seconds := 12.0
@export var orb_scene: PackedScene
@export var death_effect: PackedScene
@export var text_scene: PackedScene

var _state := State.PROWL
var _timer := 0.0
var _home := Vector3.ZERO
var _wander_to := Vector3.ZERO
var _pounce_dir := Vector3.ZERO
var _hero: Node3D
var _layers := Vector2i.ZERO  # collision layer and mask while alive

@onready var _sprite: AnimatedSprite3D = $Sprite
@onready var _health: Health = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _bite: Hitbox = $Bite
@onready var _bar: Node3D = $Bar
@onready var _bar_fill: Sprite3D = $Bar/Fill


func _ready() -> void:
	_layers = Vector2i(collision_layer, collision_mask)
	_home = global_position
	_wander_to = _home
	_hurtbox.struck.connect(_on_struck)
	_health.died.connect(_on_died)
	_health.changed.connect(_on_health_changed)
	_bar.visible = false
	_sprite.play("idle")


func _physics_process(delta: float) -> void:
	if _hero == null:
		_hero = get_tree().get_first_node_in_group("player")
	_timer -= delta
	var to_hero := _flat(_hero.global_position - global_position) if _hero else Vector3.INF
	match _state:
		State.PROWL:
			_prowl(to_hero)
		State.CHASE:
			_chase(to_hero)
		State.WINDUP:
			_halt(delta, 30.0)
			_sprite.modulate = Color(1.0, 0.75, 1.0).lerp(Color(2.2, 1.4, 2.6), 0.5 + 0.5 * sin(_timer * 40.0))
			if _timer <= 0.0:
				_pounce()
		State.POUNCE:
			velocity.x = _pounce_dir.x * pounce_speed
			velocity.z = _pounce_dir.z * pounce_speed
			if _timer <= 0.0:
				_bite.set_active(false)
				_set_state(State.RECOVER, 0.8, "idle")
		State.RECOVER, State.HURT:
			_halt(delta, 20.0)
			if _timer <= 0.0:
				_set_state(State.CHASE, 0.0, "run")
		State.DEAD:
			_halt(delta, 20.0)
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()


func _prowl(to_hero: Vector3) -> void:
	if to_hero.length() < detect_radius and _hero_alive():
		_set_state(State.CHASE, 0.0, "run")
		return
	var step := _flat(_wander_to - global_position)
	if step.length() < 0.3 or _timer <= 0.0:
		_wander_to = _home + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.0, 2.0))
		_timer = randf_range(2.0, 3.5)
		step = Vector3.ZERO
	_move(step.normalized() * speed * 0.35 if step.length() > 0.3 else Vector3.ZERO, "idle" if step == Vector3.ZERO else "run")


func _chase(to_hero: Vector3) -> void:
	var from_home := _flat(global_position - _home).length()
	if not _hero_alive() or to_hero.length() > give_up_radius or from_home > give_up_radius * 1.3:
		_wander_to = _home
		_set_state(State.PROWL, 3.0, "run")
		return
	if to_hero.length() < attack_range:
		_pounce_dir = to_hero.normalized()
		_face(View.to_screen(_pounce_dir).x)
		_set_state(State.WINDUP, windup_seconds, "windup")
		return
	_move(to_hero.normalized() * speed, "run")


func _pounce() -> void:
	_sprite.modulate = Color.WHITE
	var to_hero := _flat(_hero.global_position - global_position)
	if to_hero.length() > 0.5:  # a last small correction keeps the warning honest but readable
		_pounce_dir = _pounce_dir.lerp(to_hero.normalized(), 0.35).normalized()
	_set_state(State.POUNCE, 0.3, "pounce")
	_bite.set_active(true)


func _on_struck(damage: int, push: Vector3) -> void:
	if _state == State.DEAD:
		return
	_health.damage(damage)
	_popup(str(damage), Color("fff1b0"))
	_sprite.modulate = Color(4, 4, 4)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.14)
	GameFeel.hitstop(0.05)
	if _health.is_dead():
		return
	velocity = push
	_bite.set_active(false)
	_set_state(State.HURT, 0.28, "hurt")


func _on_died() -> void:
	_set_state(State.DEAD, 0.0, "dead")
	_bite.set_active(false)
	_bar.visible = false
	_hurtbox.set_deferred("monitorable", false)
	collision_layer = 0  # the body stays on the ground but no longer blocks anyone
	collision_mask = 1
	await _sprite.animation_finished
	if death_effect:
		_spawn(death_effect, global_position + Vector3(0, 0.6, 0.1))
	if orb_scene:
		var orb := _spawn(orb_scene, global_position + Vector3(0, 0, 0.2))
		orb.amount = xp_reward
	await create_tween().tween_property(_sprite, "modulate:a", 0.0, 0.4).finished
	visible = false
	await get_tree().create_timer(respawn_seconds).timeout
	global_position = _home
	_health.heal(_health.maximum)
	_sprite.modulate = Color.WHITE
	visible = true
	_hurtbox.monitorable = true
	collision_layer = _layers.x
	collision_mask = _layers.y
	_set_state(State.PROWL, 1.0, "idle")


func _on_health_changed(current: int, maximum: int) -> void:
	_bar.visible = current < maximum and current > 0
	_bar_fill.region_rect.size.x = roundf(_bar_fill.texture.get_width() * float(current) / maximum)


func _set_state(state: State, seconds: float, animation: String) -> void:
	_state = state
	_timer = seconds
	_sprite.play(animation)
	if state != State.WINDUP:
		_sprite.modulate = Color(1, 1, 1, _sprite.modulate.a)


func _move(motion: Vector3, animation: String) -> void:
	velocity.x = motion.x
	velocity.z = motion.z
	if absf(motion.x) > 0.05:
		_face(View.to_screen(motion).x)
	_sprite.play(animation)


func _halt(delta: float, rate: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, rate * delta)
	velocity.z = move_toward(velocity.z, 0.0, rate * delta)


func _face(x: float) -> void:
	_sprite.flip_h = x < 0.0  # the sheet faces right


func _hero_alive() -> bool:
	return _hero != null and not _hero.get_node("Health").is_dead()


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func _spawn(scene: PackedScene, where: Vector3) -> Node3D:
	var node: Node3D = scene.instantiate()
	get_parent().add_child(node)
	node.global_position = where
	return node


func _popup(text: String, colour: Color) -> void:
	if text_scene == null:
		return
	var label: Label3D = text_scene.instantiate()
	label.text = text
	label.modulate = colour
	get_parent().add_child(label)
	label.global_position = global_position + Vector3(0, 1.9, 0.3)
