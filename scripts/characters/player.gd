extends CharacterBody3D
## The hero. Free 8-way movement drawn with 4-direction sprites (left is the mirrored right), a
## chainable sword combo, a dodge with brief invulnerability, four skill slots and an ultimate read
## from the learned skill tree (Progress), buffs, shields, hit reactions, defeat and respawn.
## Everything that depends on what the hero has learned goes through Progress.stat().

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
const SWORD_DAMAGE := 12
const SLOT_ACTIONS := ["skill_1", "skill_2", "skill_3", "skill_4"]

@export var mp_regen := 5.0  ## mana recovered per second
@export var dust_scene: PackedScene
@export var text_scene: PackedScene  ## floating damage numbers and words

var mp := 0.0

var _state := State.MOVE
var _facing := Vector2.DOWN
var _elapsed := 0.0       # time spent in the current action
var _duration := 0.0      # length of the current action
var _invulnerable := 0.0  # seconds of invulnerability left
var _cooldowns := {}      # skill -> seconds left
var _queued_attack := false
var _sword_state := 0     # 0 waiting, 1 swinging, 2 done (per attack)
var _combo := 0
var _combo_window := 0.0
var _cast_skill: SkillData
var _cast_released := false
var _dodge_dir := Vector3.ZERO
var _dodge_charges := 1
var _dodge_recharge := 0.0
var _after_dodge := 0.0
var _afterimage_clock := 0.0
var _dash: Hitbox
var _dash_dir := Vector3.ZERO
var _dash_speed := 0.0
var _shake := 0.0
var _spawn_point := Vector3.ZERO
var _buffs: Array[Dictionary] = []  # {"mods": Dictionary, "left": float}
var _shield := {}
var _zone_mods := {}
var _zone_left := 0.0
var _since_hit := 99.0    # seconds since the hero was last hurt (halo)
var _combat := 99.0       # seconds since the last blow given or taken (out of combat)
var _revive_used := false
var _last_stand := {}     # charge index -> seconds until it is back
var _trigger_clock := {}  # trigger -> seconds until it may fire again
var _free_luz := 0.0
var _free_luz_ready := false
var _cast_counts := {}
var _charges_used := {}
var _regen_hp := 0.0
var _tinted := false

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
	_sword.from_hero = true
	_sword.attacker = self
	_sword.affinity = &"espada"
	_dodge_charges = dodge_charges_max()
	_health.maximum = Progress.max_hp()
	_health.current = _health.maximum
	mp = max_mp()
	_hurtbox.struck.connect(_on_struck)
	_health.died.connect(_on_died)
	_health.changed.connect(func(_hp: int, _max_hp: int) -> void: _emit_stats())
	Progress.changed.connect(_on_progress_changed)
	_emit_stats.call_deferred()
	progressed.emit.call_deferred(Progress.level, Progress.xp, Progress.xp_next())


func _exit_tree() -> void:
	if Progress.changed.is_connected(_on_progress_changed):
		Progress.changed.disconnect(_on_progress_changed)


func _physics_process(delta: float) -> void:
	_tick(delta)
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	match _state:
		State.MOVE:
			_walk(input)
			_read_actions(input)
		State.ATTACK:
			if input == Vector2.ZERO:
				_brake(delta, 25.0)
			else:  # the sword can be swung while walking (not while dodging)
				var step := View.to_world(input) * speed()
				velocity.x = step.x
				velocity.z = step.z
			_swing()
			if Input.is_action_just_pressed("attack") and _elapsed > 0.1:
				_queued_attack = true
			elif Input.is_action_just_pressed("dodge") and _elapsed > 0.16 and _can_dodge():
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
	var tint := _body_tint()
	if tint != Color.WHITE or _tinted:  # (a hit's white flash owns the sprite's colour otherwise)
		_sprite.modulate = tint
	_tinted = tint != Color.WHITE
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


# --- numbers ------------------------------------------------------------------------------------

func max_hp() -> int:
	return Progress.max_hp()


func max_mp() -> float:
	return Progress.max_mp()


## A learned passive's number (see data/trees), plus the buffs running now.
func stat(name: String) -> float:
	return float(Progress.stat(name)) + mod(name)


## The sum of one number over the buffs running now (and the zone the hero stands in).
func mod(name: String) -> float:
	var total := 0.0
	for b in _buffs:
		total += float(b.mods.get(name, 0.0))
	if _zone_left > 0.0:
		total += float(_zone_mods.get(name, 0.0))
	return total


func speed() -> float:
	var m := 1.0 + 0.01 * Progress.attr("agilidad") + mod("move_pct")
	if _combat > 5.0:
		m += stat("ooc_move_pct")
	return SPEED * maxf(m, 0.2)


func dodge_charges_max() -> int:
	return 1 + int(Progress.stat("dodge_charges"))


func scale_damage(amount: int, s: SkillData = null) -> int:
	var magic := s != null and s.affinity != &""
	var m := 1.0 + 0.04 * (Progress.attr("control") if magic else Progress.attr("poder")) + mod("damage_pct")
	if magic:
		m += mod("aff_pct." + s.affinity)
	return roundi(amount * m)


func skill_damage(s: SkillData) -> int:
	return scale_damage(s.damage, s)


func facing_3d() -> Vector3:
	var dir := _dir_name()
	if dir == "side":
		return View.to_world(Vector2(signf(_facing.x), 0))
	return View.to_world(Vector2(0, -1 if dir == "up" else 1))


func is_invisible() -> bool:
	return mod("invisible") > 0.0


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func cooldown_left(skill: StringName) -> float:
	if skill == &"dodge":
		return _dodge_recharge if _dodge_charges == 0 else 0.0
	return _cooldowns.get(skill, 0.0)


func cooldown_fraction(skill: StringName) -> float:
	var total := 1.0
	if skill == &"dodge":
		total = dodge_cooldown()
	elif Progress.nodes.has(skill):
		total = Progress.skill(skill).cooldown
	return clampf(cooldown_left(skill) / maxf(total, 0.1), 0.0, 1.0)


# --- actions --------------------------------------------------------------------------------

var _base_scale := Vector3.ZERO


func _walk(input: Vector2) -> void:
	var move := View.to_world(input) * speed()  # the controls follow the screen
	velocity.x = move.x
	velocity.z = move.z
	if input != Vector2.ZERO:
		_facing = input
	_play("walk" if input != Vector2.ZERO else "idle")
	_breathe(input != Vector2.ZERO)


## Idle breathing and a small squash while walking, on top of the drawn frames.
func _breathe(walking: bool) -> void:
	if _base_scale == Vector3.ZERO:
		_base_scale = _sprite.scale
	var t := Time.get_ticks_msec() / 1000.0
	var k := 0.035 * sin(t * 14.0) if walking else 0.02 * sin(t * 2.6)
	_sprite.scale = Vector3(_base_scale.x * (1.0 - k * 0.5), _base_scale.y * (1.0 + k), _base_scale.z)


func _read_actions(input: Vector2) -> void:
	if Input.is_action_just_pressed("attack"):
		_start_attack()
	elif Input.is_action_just_pressed("dodge") and _can_dodge():
		_start_dodge(input)
	elif Input.is_action_just_pressed("ultimate"):
		_try_cast(Progress.ultimate)
	else:
		for i in Progress.SLOTS:
			if Input.is_action_just_pressed(SLOT_ACTIONS[i]):
				_try_cast(Progress.equipped[i])
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
		_end_dash()
		_spawn(dust_scene, global_position)
	if was == State.ATTACK:
		_combo_window = 0.45
	if was == State.ATTACK and _queued_attack:
		_start_attack()
	else:
		_walk(input)


# the sword

func _start_attack() -> void:
	_queued_attack = false
	_sword_state = 0
	var hits := 3 + int(stat("combo_hits"))
	_combo = _combo % hits + 1 if _combo_window > 0.0 else 1
	var last := _combo == hits
	var m := 1.0 + 0.04 * Progress.attr("poder") + mod("damage_pct") + mod("next_sword_pct")
	if _after_dodge > 0.0:
		m += stat("after_dodge_pct")
	var push := 7.0
	var status := &""
	if last:
		m += stat("combo_last_pct")
		push *= 1.0 + stat("combo_last_push")
		status = StringName(str(Progress.stat("combo_last_status", "")))
		if status == &"" and stat("combo_last_stun") > 0.0:
			status = &"aturdido"
	var buffed := _consume_next_sword()
	if buffed != &"":
		status = buffed
	_sword.damage = roundi(SWORD_DAMAGE * m)
	_sword.push = push
	_sword.status = status
	_sword.stacks = 1
	_begin(State.ATTACK, 0.3, "attack")
	velocity = facing_3d() * 2.5  # a small step into the swing
	var reach := facing_3d() * 0.85
	_sword.position = Vector3(reach.x, 0.8, reach.z)


## The "next sword hit" buffs are used up by the swing; returns the status they carried.
func _consume_next_sword() -> StringName:
	var status := &""
	for b in _buffs:
		if b.mods.has("next_sword_status") or b.mods.has("next_sword_pct"):
			status = StringName(str(b.mods.get("next_sword_status", "")))
			b.left = 0.0
	return status


func _swing() -> void:
	if _sword_state == 0 and _elapsed >= 0.13:
		_sword_state = 1
		_sword.set_active(true)
	elif _sword_state == 1 and _elapsed >= 0.24:
		_sword_state = 2
		_sword.set_active(false)


# the dodge

func _can_dodge() -> bool:
	return _dodge_charges > 0


func _start_dodge(input: Vector2) -> void:
	var dir := input.normalized() if input != Vector2.ZERO else _facing.normalized()
	_facing = dir
	_dodge_dir = View.to_world(dir)
	_sword.set_active(false)
	_begin(State.DODGE, 0.3, "dodge")
	_invulnerable = maxf(_invulnerable, 0.28 + stat("dodge_iframes"))
	collision_mask = MASK_WORLD  # roll through enemies
	_dodge_charges -= 1
	if _dodge_recharge <= 0.0:
		_dodge_recharge = dodge_cooldown()
	cooldown_started.emit(&"dodge", dodge_cooldown())
	_after_dodge = 1.0
	_spawn(dust_scene, global_position)
	for t: Dictionary in Progress.triggers("dodge"):
		if t.has("zone"):
			SkillCaster.passive_zone(self, t.zone)


func dodge_cooldown() -> float:
	return 0.55 * maxf(1.0 - 0.02 * Progress.attr("agilidad") - stat("dodge_cooldown_pct"), 0.2)


func _dodge_step(delta: float) -> void:
	if _dash != null:
		velocity.x = _dash_dir.x * _dash_speed
		velocity.z = _dash_dir.z * _dash_speed
		return
	var speed_now := lerpf(DODGE_SPEED, SPEED, _elapsed / _duration)
	velocity.x = _dodge_dir.x * speed_now
	velocity.z = _dodge_dir.z * speed_now
	_afterimage_clock -= delta
	if _afterimage_clock <= 0.0:
		_afterimage_clock = 0.05
		_afterimage()


## DASH skills: the hero rushes forward hitting what is on the way.
func start_dash(s: SkillData, dmg: int) -> void:
	_dash_dir = facing_3d()
	var seconds := 0.22
	_dash_speed = maxf(s.length, 1.0) / seconds
	_begin(State.DODGE, seconds, "dodge")
	collision_mask = MASK_WORLD
	if s.invulnerable > 0.0:
		_invulnerable = maxf(_invulnerable, seconds + 0.05)
	_dash = Hitbox.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.9
	shape.shape = sphere
	shape.position.y = 0.8
	_dash.add_child(shape)
	SkillCaster._setup(_dash, self, s, dmg)
	_dash.landed.connect(func(_t: Hurtbox) -> void: GameFeel.hitstop(0.04))
	add_child(_dash)
	_dash.set_active(true)
	if s.trail_status != &"":  # leaves a lingering mark where it passed
		var trail := SkillData.new()
		trail.affinity = s.affinity
		trail.status = s.trail_status
		trail.damage = roundi(dmg * 0.4)
		trail.radius = 1.0
		trail.duration = 2.0
		trail.tick = 0.5
		SkillCaster.zone(self, trail, global_position + _dash_dir * s.length * 0.5, _dash_dir, trail.damage)


func _end_dash() -> void:
	if _dash != null:
		_dash.queue_free()
		_dash = null


# skills

func _try_cast(id: StringName) -> void:
	if id == &"" or not Progress.nodes.has(id):
		return
	var s := Progress.skill(id)
	if _cooldowns.get(id, 0.0) > 0.0 and not (s.charges > 1 and _charges_used.get(id, 0) < s.charges):
		return
	var cost := s.mana_cost * maxf(1.0 - 0.01 * Progress.attr("control"), 0.5)
	var free := s.affinity == &"luz" and _free_luz_ready
	if free:
		cost = 0.0
	if mp < cost:
		_popup("Sin maná", Color("9fc8ff"))
		return
	if s.hp_cost_pct > 0.0:
		var price := roundi(max_hp() * s.hp_cost_pct)
		if _health.current <= price + 1:
			_popup("Poca vida", Color("ff6a55"))
			return
		_health.damage(price)
	mp -= cost
	if free:
		_free_luz_ready = false
		_free_luz = 0.0
		_popup("¡Sin coste!", Color("ffe880"), 0.3)
	_emit_stats()
	_start_cooldown(id, s)
	_cast_skill = s
	_cast_released = false
	_cast_counts[id] = _cast_counts.get(id, 0) + 1
	_begin(State.CAST, s.cast_seconds, "cast")


func _start_cooldown(id: StringName, s: SkillData) -> void:
	var total := s.cooldown * maxf(1.0 - stat("cooldown_pct"), 0.3)
	if s.charges > 1:
		_charges_used[id] = _charges_used.get(id, 0) + 1
		if _charges_used[id] < s.charges:
			if _cooldowns.get(id, 0.0) <= 0.0:
				_cooldowns[id] = total
			return
	_cooldowns[id] = total
	cooldown_started.emit(id, total)


## Casts a skill without cost or cooldown (triggers: a revival that explodes, a shield when low).
func cast_free(id: StringName) -> void:
	if Progress.nodes.has(id):
		SkillCaster.cast(self, Progress.skill(id))


func _cast_step() -> void:
	if _cast_released or _cast_skill == null or _elapsed < _cast_skill.release_at:
		return
	_cast_released = true
	var s := _cast_skill
	SkillCaster.cast(self, s)
	if s.double_every > 0 and _cast_counts.get(s.id, 0) % s.double_every == 0:
		get_tree().create_timer(0.25, false).timeout.connect(func() -> void:
			if _state != State.DEAD:
				SkillCaster.cast(self, s))


func add_buff(mods: Dictionary, seconds: float) -> void:
	_buffs.append({"mods": mods, "left": seconds})


func add_shield(s: SkillData) -> void:
	_shield = {"hp": s.shield, "hits": s.hits, "left": s.duration if s.duration > 0.0 else 8.0,
			"thorns": s.thorns, "status": s.break_status, "affinity": s.affinity}


func heal_skill(s: SkillData) -> void:
	if s.heal_pct > 0.0:
		restore(0.0, roundi(max_hp() * s.heal_pct))
	if s.restore_mp:
		restore(max_mp(), 0)
	if s.invulnerable > 0.0:
		_invulnerable = maxf(_invulnerable, s.invulnerable)
	var puff: AnimatedSprite3D = load("res://scenes/effects/spark.tscn").instantiate()
	puff.sprite_frames = Affinity.frames(puff.sprite_frames, s.affinity)
	get_parent().add_child(puff)
	puff.global_position = global_position + Vector3(0, 0.9, 0.1)


func restore(mana: float, hp: int) -> void:
	if mana > 0.0:
		mp = minf(max_mp(), mp + mana)
	if hp > 0:
		_health.heal(hp)
		_popup("+%d" % hp, Color("8fe88f"), 0.2)
	_emit_stats()


## Zones the hero stands in change its numbers for a moment.
func zone_mods(mods: Dictionary) -> void:
	_zone_mods = mods
	_zone_left = 0.2


# --- damage, defeat, experience ---------------------------------------------------------------

func _on_struck(damage: int, push: Vector3, source: Hitbox = null) -> void:
	if _state == State.DEAD:
		return
	if _invulnerable > 0.0:
		if _state == State.DODGE and source != null:
			_perfect_dodge(source)
		return
	var m := 1.0 + stat("received_pct")
	if _health.current < max_hp() * 0.3:
		m += stat("low_hp_received_pct")
	if stat("halo") > 0.0 and _since_hit >= 4.0:
		m *= 0.5
	var amount := maxi(1, roundi(damage * maxf(m, 0.1)))
	_since_hit = 0.0
	_combat = 0.0
	var blocked := _shield_absorb(amount)
	if blocked >= amount:
		_popup("Bloqueado", Color("e8f0ff"))
		_invulnerable = 0.4
		return
	amount -= blocked
	_apply_thorns(source)
	if _zone_left > 0.0 and _zone_mods.has("min_hp"):
		amount = mini(amount, maxi(_health.current - roundi(max_hp() * float(_zone_mods.min_hp)), 0))
	if amount >= _health.current and _use_last_stand():
		amount = _health.current - 1
	_health.damage(amount)
	_popup(str(amount), Color("ff6a55"))
	_flash()
	GameFeel.hitstop(0.06)
	_shake = 0.2
	if _health.is_dead():
		return
	_check_low_hp()
	velocity = push
	_sword.set_active(false)
	_end_dash()
	collision_mask = MASK_WITH_ENEMIES
	_begin(State.HURT, 0.3, "hurt")
	_invulnerable = 1.0


func _shield_absorb(amount: int) -> int:
	if _shield.is_empty():
		return 0
	var blocked := 0
	if _shield.hits > 0:
		_shield.hits -= 1
		blocked = amount
	elif _shield.hp > 0:
		blocked = mini(amount, _shield.hp)
		_shield.hp -= blocked
	if _shield.hits <= 0 and _shield.hp <= 0:
		_break_shield()
	return blocked


func _break_shield() -> void:
	var s: Dictionary = _shield
	_shield = {}
	if s.thorns > 0:
		SkillCaster.explosion(self, global_position, s.thorns, s.affinity, 1.4)
	if s.status != &"":
		for e in get_tree().get_nodes_in_group("enemies"):
			var st: StatusEffects = e.get_node_or_null("Status")
			if st and SkillCaster.flat(e.global_position - global_position).length() < 3.0:
				st.apply(s.status)


func _apply_thorns(source: Hitbox) -> void:
	var status := StringName(str(Progress.stat("thorns_status", "")))
	if status == &"" or source == null or source.attacker == null:
		return
	var st: StatusEffects = source.attacker.get_node_or_null("Status")
	if st:
		st.apply(status)


func _perfect_dodge(source: Hitbox) -> void:
	if _elapsed > 0.2 or source.has_meta("perfect"):
		return
	source.set_meta("perfect", true)
	_popup("¡Esquiva!", Color("fff1b0"), 0.2)
	restore(stat("perfect_dodge_mp"), 0)
	var status := StringName(str(Progress.stat("perfect_dodge_status", "")))
	if status != &"" and source.attacker:
		var st: StatusEffects = source.attacker.get_node_or_null("Status")
		if st:
			st.apply(status)
	var slow := stat("perfect_dodge_slow")
	if slow > 0.0:
		for e in get_tree().get_nodes_in_group("enemies"):
			var st: StatusEffects = e.get_node_or_null("Status")
			if st and SkillCaster.flat(e.global_position - global_position).length() < 8.0:
				st.apply(&"lento", 1, slow)


func _use_last_stand() -> bool:
	for i in int(Progress.stat("last_stand")):
		if not _last_stand.has(i):
			_last_stand[i] = 60.0
			_invulnerable = 1.0
			_popup("¡Segundo aliento!", Color("fff1b0"), 0.4)
			return true
	return false


func _check_low_hp() -> void:
	for t: Dictionary in Progress.triggers("low_hp"):
		var key := "low_hp:" + str(t.cast)
		if _health.current < max_hp() * float(t.below) and _trigger_clock.get(key, 0.0) <= 0.0:
			_trigger_clock[key] = float(t.every)
			cast_free(StringName(t.cast))


func _on_died() -> void:
	for t: Dictionary in Progress.triggers("death"):
		if not _revive_used:  # once per zone: the flag lives with this level's hero
			_revive_used = true
			_health.heal(roundi(max_hp() * float(t.revive_pct)))
			_invulnerable = 1.5
			_popup("¡Resurges!", Color("fff1b0"), 0.4)
			cast_free(StringName(t.cast))
			return
	_state = State.DEAD
	_sword.set_active(false)
	_end_dash()
	_sprite.flip_h = false
	_sprite.play("dead")
	said.emit("Has caído... Vuelves al inicio del camino.")
	await get_tree().create_timer(2.5).timeout
	global_position = _spawn_point
	velocity = Vector3.ZERO
	_buffs.clear()
	_shield = {}
	_health.maximum = max_hp()
	_health.heal(_health.maximum)
	mp = max_mp()
	_emit_stats()
	_invulnerable = 1.5
	_state = State.MOVE


func gain_xp(amount: int) -> void:
	var gained := Progress.gain_xp(amount)
	_popup("+%d EXP" % amount, Color("ffd34a"))
	if gained > 0:
		_health.maximum = max_hp()
		_health.heal(_health.maximum)
		mp = max_mp()
		_emit_stats()
		_popup("¡NIVEL %d!" % Progress.level, Color("8fe8ff"), 0.5)
		said.emit("¡Nivel %d! Tienes PA y un punto de atributo nuevos (T)." % Progress.level)
	progressed.emit(Progress.level, Progress.xp, Progress.xp_next())


## What the hero's hits cause once they land (called by the enemy's StatusEffects).
func on_hit_landed(enemy: Node, hit: Hitbox, _final: int) -> void:
	_combat = 0.0
	if hit.affinity != &"espada":
		return
	var status: StatusEffects = enemy.get_node_or_null("Status")
	if status and status.has(&"quemadura"):
		restore(stat("mp_on_burning_hit"), 0)
	var cdr := stat("sword_cdr")
	if cdr > 0.0:
		for id in _cooldowns:
			_cooldowns[id] = maxf(_cooldowns[id] - cdr, 0.0)


func on_enemy_event(event: String, _enemy: Node) -> void:
	if event != "freeze":
		return
	restore(stat("freeze_mp"), 0)
	var cdr := stat("freeze_cdr.hielo")
	if cdr > 0.0:
		for id in _cooldowns:
			if Progress.nodes.has(id) and Progress.nodes[id].tree == &"hielo":
				_cooldowns[id] = maxf(_cooldowns[id] - cdr, 0.0)


func _on_progress_changed() -> void:
	_health.maximum = max_hp()
	_dodge_charges = mini(_dodge_charges, dodge_charges_max())
	_emit_stats()
	progressed.emit(Progress.level, Progress.xp, Progress.xp_next())


# --- helpers ------------------------------------------------------------------------------------

func _tick(delta: float) -> void:
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	_since_hit += delta
	_combat += delta
	_after_dodge = maxf(_after_dodge - delta, 0.0)
	_combo_window = maxf(_combo_window - delta, 0.0)
	_zone_left -= delta
	for id in _cooldowns.keys():
		_cooldowns[id] = maxf(_cooldowns[id] - delta, 0.0)
		if _cooldowns[id] <= 0.0 and _charges_used.get(id, 0) > 0:
			_charges_used[id] -= 1
			if _charges_used[id] > 0:
				_cooldowns[id] = Progress.skill(id).cooldown
	for key in _trigger_clock.keys():
		_trigger_clock[key] = maxf(_trigger_clock[key] - delta, 0.0)
	for i in _last_stand.keys():
		_last_stand[i] -= delta
		if _last_stand[i] <= 0.0:
			_last_stand.erase(i)
	if _dodge_charges < dodge_charges_max():
		_dodge_recharge -= delta
		if _dodge_recharge <= 0.0:
			_dodge_charges += 1
			_dodge_recharge = dodge_cooldown() if _dodge_charges < dodge_charges_max() else 0.0
	for b in _buffs:
		b.left -= delta
	_buffs = _buffs.filter(func(b: Dictionary) -> bool: return b.left > 0.0)
	if not _shield.is_empty():
		_shield.left -= delta
		if _shield.left <= 0.0:
			_shield = {}
	var every := stat("free_cast_every.luz")
	if every > 0.0 and not _free_luz_ready:
		_free_luz += delta
		_free_luz_ready = _free_luz >= every
	if _state == State.DEAD:
		return
	var regen := mp_regen + stat("mp_regen")
	if stat("regen_near_burning") > 0.0 and not SkillCaster.enemies_with(global_position, 6.0, &"quemadura").is_empty():
		regen *= 1.0 + stat("regen_near_burning")
	if mp < max_mp():
		mp = minf(max_mp(), mp + regen * delta)
		_emit_stats()
	var hp_regen := 0.0
	if _combat > 5.0:
		hp_regen += stat("ooc_regen_pct")
	if _zone_left > 0.0:
		hp_regen += float(_zone_mods.get("regen_pct", 0.0))
	if hp_regen > 0.0 and _health.current < max_hp():
		_regen_hp += max_hp() * hp_regen * delta
		if _regen_hp >= 1.0:
			_health.heal(int(_regen_hp))
			_regen_hp -= int(_regen_hp)


func _body_tint() -> Color:
	if not _shield.is_empty():
		return Affinity.color(_shield.affinity).lerp(Color.WHITE, 0.55 + 0.15 * sin(Time.get_ticks_msec() * 0.01))
	if is_invisible():
		return Color(0.7, 0.55, 1.0, 0.45)
	return Color.WHITE


func _brake(delta: float, rate: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, rate * delta)
	velocity.z = move_toward(velocity.z, 0.0, rate * delta)


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
	stats_changed.emit(_health.current, _health.maximum, mp, max_mp())
