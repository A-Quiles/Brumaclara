extends CharacterBody3D
## The hero. Free 8-way movement drawn with 4-direction sprites (left is the mirrored right), a
## chainable sword attack, a dodge with brief invulnerability, skills read from data files (`skills`:
## the first on Q, the second on E), hit reactions, defeat and respawn, experience and levels.

signal stats_changed(hp: int, max_hp: int, mp: float, max_mp: float)
signal progressed(level: int, xp: int, xp_next: int)
signal cooldown_started(skill: StringName, seconds: float)
signal said(text: String)

enum State { MOVE, ATTACK, DODGE, CAST, HURT, DEAD }

const SPEED := 5.0
const GRAVITY := 30.0
const DODGE_SPEED := 13.0
const MASK_WITH_ENEMIES := 1 | 4  # world + enemy bodies
const MASK_WORLD := 1

@export var max_mp := 50.0
@export var mp_regen := 5.0  ## mana recovered per second
@export var skills: Array[SkillData] = []  ## data/skills/*.tres, in key order (Q, E)
@export var dust_scene: PackedScene
@export var text_scene: PackedScene  ## floating damage numbers and words

var level := 1
var xp := 0
var mp := 0.0

var _state := State.MOVE
var _facing := Vector2.DOWN
var _elapsed := 0.0       # time spent in the current action
var _duration := 0.0      # length of the current action
var _invulnerable := 0.0  # seconds of invulnerability left
var _cooldowns := {}      # skill -> seconds left
var _queued_attack := false
var _sword_state := 0     # 0 waiting, 1 swinging, 2 done (per attack)
var _cast_skill: SkillData
var _cast_released := false
var _dodge_dir := Vector3.ZERO
var _afterimage_clock := 0.0
var _shake := 0.0
var _spawn_point := Vector3.ZERO

@onready var _sprite: AnimatedSprite3D = $Sprite
@onready var _silhouette: AnimatedSprite3D = $Silhouette  ## shows the hero through trees and walls
@onready var _health: Health = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _sword: Hitbox = $Sword
@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	add_to_group("player")
	_sprite.sprite_frames = HeroLook.frames(HeroLook.load_look())  # the look from the character creator
	_silhouette.sprite_frames = _sprite.sprite_frames
	if Exit.pending_arrival != Vector3.INF:  # arriving through another map's exit
		global_position = Exit.pending_arrival
		Exit.pending_arrival = Vector3.INF
	_spawn_point = global_position
	mp = max_mp
	_hurtbox.struck.connect(_on_struck)
	_health.died.connect(_on_died)
	_health.changed.connect(func(_hp: int, _max_hp: int) -> void: _emit_stats())
	_emit_stats.call_deferred()
	progressed.emit.call_deferred(level, xp, _xp_next())


func _physics_process(delta: float) -> void:
	_tick(delta)
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	match _state:
		State.MOVE:
			_walk(input)
			_read_actions(input)
		State.ATTACK:
			_brake(delta, 25.0)
			_swing()
			if Input.is_action_just_pressed("attack") and _elapsed > 0.1:
				_queued_attack = true
			elif Input.is_action_just_pressed("dodge") and _elapsed > 0.16 and _ready_skill(&"dodge"):
				_start_dodge(input)
		State.DODGE:
			_dodge_step(delta)
		State.CAST:
			_brake(delta, 40.0)
			_cast_step()
		State.HURT, State.DEAD:
			_brake(delta, 14.0)
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	_elapsed += delta
	if _state in [State.ATTACK, State.DODGE, State.CAST, State.HURT] and _elapsed >= _duration:
		_finish_action(input)


func _process(delta: float) -> void:
	_sprite.visible = _state == State.DODGE or _invulnerable <= 0.0 or int(_invulnerable * 16.0) % 2 == 0
	_silhouette.visible = _sprite.visible
	_silhouette.animation = _sprite.animation
	_silhouette.frame = _sprite.frame
	_silhouette.flip_h = _sprite.flip_h
	if _shake > 0.0:
		_shake -= delta
		var s := maxf(_shake, 0.0) * 0.6
		_camera.h_offset = randf_range(-s, s)
		_camera.v_offset = randf_range(-s, s)
	else:
		_camera.h_offset = 0.0
		_camera.v_offset = 0.0


# --- actions --------------------------------------------------------------------------------

func _walk(input: Vector2) -> void:
	var move := View.to_world(input) * SPEED  # the controls follow the screen
	velocity.x = move.x
	velocity.z = move.z
	if input != Vector2.ZERO:
		_facing = input
	_play("walk" if input != Vector2.ZERO else "idle")


func _read_actions(input: Vector2) -> void:
	if Input.is_action_just_pressed("attack"):
		_start_attack()
	elif Input.is_action_just_pressed("dodge") and _ready_skill(&"dodge"):
		_start_dodge(input)
	else:
		for i in mini(skills.size(), 2):
			if Input.is_action_just_pressed("skill_%d" % (i + 1)):
				_try_cast(skills[i])
				return


func _begin(state: State, seconds: float, animation: String) -> void:
	_state = state
	_elapsed = 0.0
	_duration = seconds
	_play(animation)
	_sprite.frame = 0


func _finish_action(input: Vector2) -> void:
	var was := _state
	_state = State.MOVE
	_sword.set_active(false)
	if was == State.DODGE:
		collision_mask = MASK_WITH_ENEMIES
		_spawn(dust_scene, global_position)
	if was == State.ATTACK and _queued_attack:
		_start_attack()
	else:
		_walk(input)


func _start_attack() -> void:
	_queued_attack = false
	_sword_state = 0
	_begin(State.ATTACK, 0.3, "attack")
	velocity = _facing_3d() * 2.5  # a small step into the swing
	var reach := _facing_3d() * 0.85
	_sword.position = Vector3(reach.x, 0.8, reach.z)


func _swing() -> void:
	if _sword_state == 0 and _elapsed >= 0.13:
		_sword_state = 1
		_sword.set_active(true)
	elif _sword_state == 1 and _elapsed >= 0.24:
		_sword_state = 2
		_sword.set_active(false)


func _start_dodge(input: Vector2) -> void:
	var dir := input.normalized() if input != Vector2.ZERO else _facing.normalized()
	_facing = dir
	_dodge_dir = View.to_world(dir)
	_sword.set_active(false)
	_begin(State.DODGE, 0.3, "dodge")
	_invulnerable = maxf(_invulnerable, 0.28)
	collision_mask = MASK_WORLD  # roll through enemies
	_cooldowns[&"dodge"] = 0.55
	cooldown_started.emit(&"dodge", 0.55)
	_spawn(dust_scene, global_position)


func _dodge_step(delta: float) -> void:
	var speed := lerpf(DODGE_SPEED, SPEED, _elapsed / _duration)
	velocity.x = _dodge_dir.x * speed
	velocity.z = _dodge_dir.z * speed
	_afterimage_clock -= delta
	if _afterimage_clock <= 0.0:
		_afterimage_clock = 0.05
		_afterimage()


func _try_cast(skill: SkillData) -> void:
	if not _ready_skill(skill.id):
		return
	if mp < skill.mana_cost:
		_popup("Sin maná", Color("9fc8ff"))
		return
	mp -= skill.mana_cost
	_emit_stats()
	_cooldowns[skill.id] = skill.cooldown
	cooldown_started.emit(skill.id, skill.cooldown)
	_cast_skill = skill
	_cast_released = false
	_begin(State.CAST, skill.cast_seconds, "cast")


func _cast_step() -> void:
	if _cast_released or _elapsed < _cast_skill.release_at:
		return
	_cast_released = true
	var effect: Hitbox = _cast_skill.scene.instantiate()
	effect.damage = _cast_skill.damage
	effect.push = _cast_skill.push
	if _cast_skill.kind == SkillData.Kind.PROJECTILE:
		effect.set("direction", _facing_3d())  # a projectile scene (fire_bolt.gd) flies this way
		get_parent().add_child(effect)
		effect.global_position = global_position + _facing_3d() * 0.7 + Vector3(0, 0.95, 0.05)
	else:
		get_parent().add_child(effect)
		effect.global_position = global_position + Vector3(0, 0, 0.1)
		effect.landed.connect(func(_target: Hurtbox) -> void: GameFeel.hitstop(0.04))
		_shake = 0.3


# --- damage, defeat, experience ---------------------------------------------------------------

func _on_struck(damage: int, push: Vector3) -> void:
	if _invulnerable > 0.0 or _state == State.DEAD:
		return
	_health.damage(damage)
	_popup(str(damage), Color("ff6a55"))
	_flash()
	GameFeel.hitstop(0.06)
	_shake = 0.2
	if _health.is_dead():
		return
	velocity = push
	_sword.set_active(false)
	collision_mask = MASK_WITH_ENEMIES
	_begin(State.HURT, 0.3, "hurt")
	_invulnerable = 1.0


func _on_died() -> void:
	_state = State.DEAD
	_sword.set_active(false)
	_sprite.flip_h = false
	_sprite.play("dead")
	said.emit("Has caído... Vuelves al inicio del camino.")
	await get_tree().create_timer(2.5).timeout
	global_position = _spawn_point
	velocity = Vector3.ZERO
	_health.heal(_health.maximum)
	mp = max_mp
	_emit_stats()
	_invulnerable = 1.5
	_state = State.MOVE


func gain_xp(amount: int) -> void:
	xp += amount
	_popup("+%d EXP" % amount, Color("ffd34a"))
	while xp >= _xp_next():
		xp -= _xp_next()
		level += 1
		_health.maximum += 10
		_health.heal(_health.maximum)
		max_mp += 5.0
		mp = max_mp
		_emit_stats()
		_popup("¡NIVEL %d!" % level, Color("8fe8ff"), 0.5)
		said.emit("¡Nivel %d! Tu vida y tu maná aumentan." % level)
	progressed.emit(level, xp, _xp_next())


func _xp_next() -> int:
	return 60 + 40 * (level - 1)


# --- helpers ------------------------------------------------------------------------------------

func _tick(delta: float) -> void:
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	for skill in _cooldowns:
		_cooldowns[skill] = maxf(_cooldowns[skill] - delta, 0.0)
	if _state != State.DEAD and mp < max_mp:
		mp = minf(max_mp, mp + mp_regen * delta)
		_emit_stats()


func _ready_skill(skill: StringName) -> bool:
	return _cooldowns.get(skill, 0.0) <= 0.0


func _brake(delta: float, rate: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, rate * delta)
	velocity.z = move_toward(velocity.z, 0.0, rate * delta)


func _facing_3d() -> Vector3:
	var dir := _dir_name()
	if dir == "side":
		return View.to_world(Vector2(signf(_facing.x), 0))
	return View.to_world(Vector2(0, -1 if dir == "up" else 1))


func _dir_name() -> String:
	return "side" if absf(_facing.x) > absf(_facing.y) else ("up" if _facing.y < 0.0 else "down")


func _play(base: String) -> void:
	var dir := _dir_name()
	_sprite.flip_h = dir == "side" and _facing.x < 0.0
	_sprite.play(base + "_" + dir)


func _flash() -> void:
	_sprite.modulate = Color(4, 4, 4)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.15)


func _afterimage() -> void:
	var ghost := Sprite3D.new()
	ghost.texture = _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	ghost.pixel_size = _sprite.pixel_size
	ghost.centered = _sprite.centered
	ghost.offset = _sprite.offset
	ghost.flip_h = _sprite.flip_h
	ghost.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	ghost.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ghost.modulate = Color(0.55, 0.8, 1.0, 0.5)
	get_parent().add_child(ghost)
	ghost.global_transform = _sprite.global_transform
	ghost.global_position.z -= 0.02  # just behind the hero
	var fade := ghost.create_tween()
	fade.tween_property(ghost, "modulate:a", 0.0, 0.22)
	fade.tween_callback(ghost.queue_free)


func _spawn(scene: PackedScene, where: Vector3) -> Node3D:
	var node: Node3D = scene.instantiate()
	get_parent().add_child(node)
	node.global_position = where
	return node


func _popup(text: String, colour: Color, lift := 0.0) -> void:
	var label: Label3D = text_scene.instantiate()
	label.text = text
	label.modulate = colour
	get_parent().add_child(label)
	label.global_position = global_position + Vector3(0, 2.3 + lift, 0.3)


func _emit_stats() -> void:
	stats_changed.emit(_health.current, _health.maximum, mp, max_mp)


func cooldown_left(skill: StringName) -> float:
	return _cooldowns.get(skill, 0.0)
