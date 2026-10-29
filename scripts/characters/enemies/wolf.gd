extends CharacterBody3D
## Lobo de bruma, a stalker corrupted by the Fractura. Prowls around its den, chases the hero on
## sight, crouches with glowing eyes (the warning to dodge), pounces in a straight line and stays
## open for a moment after landing. Drops experience and comes back after a while.

enum State { PROWL, CHASE, WINDUP, POUNCE, RECOVER, HURT, DEAD }

const GRAVITY := 30.0

@export var data: EnemyData  ## its numbers: data/enemies/wolf.tres
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

var _status: StatusEffects
var _pounces_left := 0
var _summoned := false

@onready var _sprite: AnimatedSprite3D = $Sprite
@onready var _health: Health = $Health
@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _bite: Hitbox = $Bite
@onready var _bar: Node3D = $Bar
@onready var _bar_fill: Sprite3D = $Bar/Fill


func _ready() -> void:
	add_to_group("enemies")
	_status = StatusEffects.new()
	_status.name = "Status"
	add_child(_status)
	if data.frames:
		_sprite.sprite_frames = data.frames
	if data.sprite_offset != Vector2.ZERO:
		_sprite.offset = data.sprite_offset
		var frame := _sprite.sprite_frames.get_frame_texture(&"idle", 0)
		if frame:  # the health bar floats just above the drawing
			_bar.position.y = (frame.get_height() + data.sprite_offset.y) * _sprite.pixel_size + 0.25
	if data.sprite_scale != 1.0:
		scale = Vector3.ONE * data.sprite_scale
		_bar.scale = Vector3.ONE / data.sprite_scale
	_bite.attacker = self
	_health.maximum = data.max_hp
	_health.heal(data.max_hp)
	_bite.damage = data.damage
	_bite.push = data.push
	_layers = Vector2i(collision_layer, collision_mask)
	_home = global_position
	_wander_to = _home
	_hurtbox.struck.connect(_on_struck)
	_hurtbox.add_to_group("enemy_hurtbox")
	_health.died.connect(_on_died)
	_health.changed.connect(_on_health_changed)
	_bar.visible = false
	_sprite.play("idle")


## Moves it somewhere else for good (the edit mode): that becomes the spot it stays around.
func place(pos: Vector3) -> void:
	global_position = pos
	_home = pos
	_wander_to = pos


func _physics_process(delta: float) -> void:
	if _hero == null:
		_hero = get_tree().get_first_node_in_group("player")
	_timer -= delta
	var to_hero := _flat(_hero.global_position - global_position) if _hero else Vector3.INF
	if _state != State.DEAD and not _status.can_act():  # stunned or frozen
		_bite.set_active(false)
		if _state in [State.WINDUP, State.POUNCE]:
			_set_state(State.CHASE, 0.0, "idle")
		_halt(delta, 30.0)
		velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
		move_and_slide()
		_sprite.modulate = Color(0.75, 0.9, 1.4) if _status.has(&"congelado") else Color(1.2, 1.2, 0.8)
		return
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
			velocity.x = _pounce_dir.x * data.attack_speed
			velocity.z = _pounce_dir.z * data.attack_speed
			if _timer <= 0.0:
				_bite.set_active(false)
				_pounces_left -= 1
				if _pounces_left > 0 and _hero_alive():  # a pack leader lunges again
					_pounce_dir = _flat(_hero.global_position - global_position).normalized()
					_set_state(State.WINDUP, data.windup_seconds * 0.6 + _status.warning_bonus(), "windup")
				else:
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
	if to_hero.length() < data.detect_radius and _hero_alive():
		_set_state(State.CHASE, 0.0, "run")
		return
	var step := _flat(_wander_to - global_position)
	if step.length() < 0.3 or _timer <= 0.0:
		_wander_to = _home + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.0, 2.0))
		_timer = randf_range(2.0, 3.5)
		step = Vector3.ZERO
	_move(step.normalized() * data.speed * 0.35 if step.length() > 0.3 else Vector3.ZERO, "idle" if step == Vector3.ZERO else "run")


func _chase(to_hero: Vector3) -> void:
	var from_home := _flat(global_position - _home).length()
	if not _hero_alive() or to_hero.length() > data.give_up_radius or from_home > data.give_up_radius * 1.3:
		_wander_to = _home
		_set_state(State.PROWL, 3.0, "run")
		return
	if to_hero.length() < data.attack_range:
		_pounce_dir = to_hero.normalized()
		_face(View.to_screen(_pounce_dir).x)
		_pounces_left = data.attack_count
		_set_state(State.WINDUP, data.windup_seconds + _status.warning_bonus(), "windup")
		return
	_move(to_hero.normalized() * data.speed * _status.speed_mult(), "run")


func _pounce() -> void:
	_sprite.modulate = Color.WHITE
	var to_hero := _flat(_hero.global_position - global_position)
	if to_hero.length() > 0.5:  # a last small correction keeps the warning honest but readable
		_pounce_dir = _pounce_dir.lerp(to_hero.normalized(), 0.35).normalized()
	_set_state(State.POUNCE, 0.3, "pounce")
	var weaken: float = Progress.stat("marked_weaken") if _hero_marks_me() else 0.0
	var dmg := roundi(data.damage * (1.0 - weaken))
	match data.attack_kind:
		"burst":  # slams where it stands
			_pounce_dir = Vector3.ZERO
			SkillCaster.enemy_blast(self, global_position, dmg, data.shot_affinity, data.burst_radius)
		"volley":  # a fan of shots toward the hero
			var spread := deg_to_rad(16.0)
			for k in data.volley:
				var turn := (k - (data.volley - 1) / 2.0) * spread
				SkillCaster.enemy_bolt(self, global_position + Vector3(0, 0.7, 0), _pounce_dir.rotated(Vector3.UP, turn),
						dmg, data.shot_affinity, data.shot_speed)
			_pounce_dir = Vector3.ZERO
		_:
			_bite.damage = dmg
			_bite.set_active(true)


func _on_struck(damage: int, push: Vector3, source: Hitbox = null) -> void:
	if _state == State.DEAD:
		return
	damage = _status.take_hit(damage, source)
	_health.damage(damage)
	_popup(str(damage), Color("fff1b0"))
	_sprite.modulate = Color(4, 4, 4)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.14)
	GameFeel.hitstop(0.05)
	if _health.is_dead():
		return
	_check_summon()
	if data.boss and damage < data.max_hp * 0.08:  # a boss only staggers under heavy blows
		return
	velocity = push * (0.4 if data.boss else 1.0)
	_bite.set_active(false)
	_set_state(State.HURT, 0.28, "hurt")


## Coins always (more from tougher foes); now and then a Fractura crystal or a potion (the inventory, Tab).
func _drop_loot() -> void:
	Progress.add_item(&"monedas", maxi(1, data.xp_reward / 8))
	for drop: Array in [[&"cristal", 0.15], [&"pocion", 0.08]]:
		if randf() < drop[1]:
			Progress.add_item(drop[0])
			get_tree().call_group("hud", "say", "Has conseguido: " + Progress.ITEMS[drop[0]].name)


func _on_died() -> void:
	_status.on_owner_died()
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
		orb.amount = data.xp_reward
		_drop_loot()
	await create_tween().tween_property(_sprite, "modulate:a", 0.0, 0.4).finished
	visible = false
	if has_meta("summoned"):
		queue_free()
		return
	await get_tree().create_timer(data.respawn_seconds).timeout
	_summoned = false
	global_position = _home
	_health.heal(_health.maximum)
	_sprite.modulate = Color.WHITE
	visible = true
	_hurtbox.monitorable = true
	collision_layer = _layers.x
	collision_mask = _layers.y
	_set_state(State.PROWL, 1.0, "idle")


func is_alive() -> bool:
	return _state != State.DEAD


func is_recovering() -> bool:
	return _state == State.RECOVER


## Damage over time (burning, poison, shadow): no knockback, no reaction.
func status_damage(amount: int, colour: Color) -> void:
	if _state == State.DEAD or amount <= 0:
		return
	_health.damage(amount)
	_popup(str(amount), colour)


func _hero_marks_me() -> bool:
	return _status.has(&"marca_sombra") or _status.has(&"marca_electrica") or _status.has(&"quemadura") \
			or _status.has(&"frio") or _status.has(&"fisura")


## Bosses call cubs once, when they fall under half their health.
func _check_summon() -> void:
	if data.summons <= 0 or _summoned or _health.current > _health.maximum / 2:
		return
	_summoned = true
	var cub_data: EnemyData = load("res://data/enemies/lobezno.tres")
	for i in data.summons:
		var cub: CharacterBody3D = load(scene_file_path).instantiate()
		cub.data = cub_data
		cub.orb_scene = orb_scene
		cub.death_effect = death_effect
		cub.text_scene = text_scene
		get_parent().add_child(cub)
		cub.place(global_position + Vector3(cos(TAU * i / data.summons) * 2.0, 0, sin(TAU * i / data.summons) * 2.0))
		cub.set_meta("summoned", true)
	_popup("¡Aúlla!", Color("ffb0b0"))


func _on_health_changed(current: int, maximum: int) -> void:
	_bar.visible = (current < maximum or Progress.stat("show_enemy_hp") > 0.0) and current > 0
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
	return _hero != null and not _hero.get_node("Health").is_dead() and not _hero.is_invisible() and not _status.blinded()


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
