class_name SkillCaster
## Runs a skill by its kind (SkillData.Kind): builds the projectiles, explosions, zones, lines and so
## on with the art of its affinity, and asks the hero for what touches the hero itself (dashes,
## buffs, shields, healing). The hero gives `facing_3d()`, `skill_damage(skill)`, `scale_damage()`.

const BOLT := preload("res://scenes/effects/fire_bolt.tscn")
const BURST := preload("res://scenes/effects/fire_burst.tscn")
const SPARK := preload("res://scenes/effects/spark.tscn")
const BLAST_SCRIPT := preload("res://scripts/effects/skill_blast.gd")
const ZONE_SCRIPT := preload("res://scripts/effects/skill_zone.gd")
const ENEMY_HURTBOXES := 16  ## collision layer 5
const HERO_HURTBOX := 8  ## collision layer 4
const PROPS := {"boulder": preload("res://scenes/environment/nature/boulder.tscn"),
		"crystal": preload("res://scenes/environment/props/crystal.tscn")}

static var _blast_frames: SpriteFrames


static func cast(hero: Node3D, s: SkillData) -> void:
	var dmg: int = hero.skill_damage(s)
	var face: Vector3 = hero.facing_3d()
	var at := hero.global_position
	match s.kind:
		SkillData.Kind.PROJECTILE:
			var extra: int = int(hero.stat("extra_projectiles." + s.affinity))
			var n := s.count + extra
			var spread := s.spread_deg if s.count > 1 or extra == 0 else 12.0
			for i in n:
				var dir := face
				if s.interval <= 0.0 and n > 1:
					dir = face.rotated(Vector3.UP, deg_to_rad(spread * (i - (n - 1) / 2.0)))
				var hand: Vector3 = hero.global_position + face * 0.7 + Vector3(0, 0.95, 0.05)
				if s.interval > 0.0 and i > 0:
					await hero.get_tree().create_timer(s.interval, false).timeout
					if not is_instance_valid(hero):
						return
					face = hero.facing_3d()
					dir = face
					hand = hero.global_position + face * 0.7 + Vector3(0, 0.95, 0.05)
				projectile(hero, s, hand, dir, dmg)
		SkillData.Kind.AREA:
			area(hero, s, at, dmg)
		SkillData.Kind.STRIKE:
			var point := at + face * s.offset
			var target_enemy: Node3D = null
			if s.target == &"nearest":
				target_enemy = nearest_enemy(at, s.offset)
				if target_enemy == null:
					return
				point = target_enemy.global_position
			explosion(hero, point, dmg, s.affinity, s.radius / 1.2 * s.scale, s, s.delay)
			if s.aoe_marked > 0.0:
				for e in enemies_with(point, s.aoe_marked, Affinity.STATUS[s.affinity]):
					if e != target_enemy:
						explosion(hero, e.global_position, dmg, s.affinity, 0.6, s)
		SkillData.Kind.ZONE:
			zone(hero, s, at + face * s.offset, face, dmg)
		SkillData.Kind.LINE:
			line(hero, s, at, face, dmg)
		SkillData.Kind.CHAIN:
			var hit: Array[Node3D] = []
			var from := at
			var reach := s.offset
			for i in s.count:
				var next := nearest_enemy(from, reach, func(e: Node3D) -> bool: return e not in hit)
				if next == null:
					break
				hit.append(next)
				explosion(hero, next.global_position, dmg, s.affinity, 0.6, s, 0.08 * i)
				from = next.global_position
				reach = s.radius
		SkillData.Kind.BEAM:
			hero.add_buff({"move_pct": -0.6}, s.duration)
			var ticks := int(s.duration / s.tick)
			for i in ticks:
				if not is_instance_valid(hero):
					return
				line(hero, s, hero.global_position, hero.facing_3d(), dmg)
				await hero.get_tree().create_timer(s.tick, false).timeout
		SkillData.Kind.DASH:
			hero.start_dash(s, dmg)
		SkillData.Kind.BLINK:
			var marked := enemies_with(at, s.offset, s.on_marked)
			if marked.is_empty():
				return
			marked.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.global_position.distance_to(at) < b.global_position.distance_to(at))
			var e := marked[0]
			var behind := e.global_position + flat(e.global_position - at).normalized() * 1.2
			_puff(hero, at, s.affinity)
			hero.global_position = Vector3(behind.x, hero.global_position.y, behind.z)
			_puff(hero, hero.global_position, s.affinity)
		SkillData.Kind.PULL:
			var e := nearest_enemy(at + face * s.offset * 0.5, s.offset * 0.6)
			if e == null:
				return
			var st: StatusEffects = e.get_node_or_null("Status")
			if st and st.is_boss():
				hero.global_position = e.global_position - flat(e.global_position - at).normalized() * 1.4
			else:
				var to := at + flat(e.global_position - at).normalized() * 1.3
				e.create_tween().tween_property(e, "global_position", Vector3(to.x, e.global_position.y, to.z), 0.18)
				if st:
					st.apply(&"aturdido", 1, 0.4)
			_puff(hero, e.global_position, s.affinity)
		SkillData.Kind.RAIN:
			rain(hero, s, at + face * s.offset, dmg)
		SkillData.Kind.BUFF:
			var mods := s.mods.duplicate()
			if mods.has("next_sword_status"):
				mods["next_sword_status"] = s.status
			hero.add_buff(mods, s.duration)
			_puff(hero, at, s.affinity)
		SkillData.Kind.SHIELD:
			hero.add_shield(s)
			_puff(hero, at, s.affinity)
		SkillData.Kind.HEAL:
			hero.heal_skill(s)
		SkillData.Kind.WALL:
			wall(hero, s, at + face * s.offset, face)
	if s.repeat_after > 0.0:
		await hero.get_tree().create_timer(s.repeat_after, false).timeout
		if is_instance_valid(hero) and s.kind == SkillData.Kind.AREA:
			area(hero, s, hero.global_position, dmg)


# --- builders (also used by projectiles, zones and passives) -----------------------------------

static func projectile(hero: Node3D, s: SkillData, from: Vector3, dir: Vector3, dmg: int, overrides := {}) -> void:
	var bolt: Hitbox = BOLT.instantiate()
	var skill := s
	if not overrides.is_empty():
		skill = s.duplicate()
		skill.apply(overrides, "set")
	_setup(bolt, hero, skill, dmg)
	bolt.direction = dir
	hero.get_parent().add_child(bolt)
	bolt.global_position = from


static func area(hero: Node3D, s: SkillData, at: Vector3, dmg: int) -> void:
	if s.fx == "spark":
		explosion(hero, at, dmg, s.affinity, 1.8 * s.scale, s)
		return
	var burst: Hitbox = BURST.instantiate()
	_setup(burst, hero, s, dmg)
	burst.scale = Vector3.ONE * s.scale
	hero.get_parent().add_child(burst)
	burst.global_position = at + Vector3(0, 0, 0.1)
	burst.landed.connect(func(_t: Hurtbox) -> void: GameFeel.hitstop(0.04))
	if s.heal_if_hits > 0:
		var count := [0]
		burst.landed.connect(func(_t: Hurtbox) -> void:
			count[0] += 1
			if count[0] == s.heal_if_hits and is_instance_valid(hero):
				hero.restore(0, roundi(hero.max_hp() * s.heal_pct)))
	hero.shake(0.3)


## One explosion that hurts whatever is within `size` (about 1.2 units at size 1) after `delay`.
static func explosion(hero: Node3D, at: Vector3, dmg: int, affinity: StringName, size := 1.0, s: SkillData = null, delay := 0.0) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	var blast := Hitbox.new()
	blast.set_script(BLAST_SCRIPT)
	_setup(blast, hero, s, dmg)
	blast.affinity = affinity
	if s == null:
		blast.status = &""
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.2 * size
	shape.shape = sphere
	shape.position.y = 0.6
	blast.add_child(shape)
	var sprite := AnimatedSprite3D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = Affinity.frames(_explosion_frames(), affinity)
	sprite.animation = &"burst"
	sprite.pixel_size = 0.0449 * size
	sprite.offset = Vector2(0, 16)
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	blast.add_child(sprite)
	blast.delay = delay
	if delay >= 0.3:
		blast.warning = _warning_mark(hero, at, 1.2 * size, affinity)
	hero.get_parent().add_child(blast)
	blast.global_position = at + Vector3(0, 0, 0.05)


static func zone(hero: Node3D, s: SkillData, at: Vector3, face: Vector3, dmg: int) -> Hitbox:
	var z := Hitbox.new()
	z.set_script(ZONE_SCRIPT)
	_setup(z, hero, s, dmg)
	z.radius = s.radius
	z.duration = s.duration
	z.tick = s.tick
	z.slow = s.slow
	z.line_length = s.line
	z.single_target = s.single_target
	z.self_mods = s.self_mods
	if s.follow:
		z.follow = hero
	if s.marks > 0:
		z.once_status = Affinity.STATUS[s.affinity]
		z.once_stacks = s.marks
	elif s.stun_once > 0.0:
		z.once_status = &"aturdido"
		z.once_seconds = s.stun_once
	if s.single_target:
		z.status = &""  # the zaps carry it
	hero.get_parent().add_child(z)
	z.global_position = at
	if s.line > 0.0:
		z.look_at(at + face, Vector3.UP)  # the line's long side lies across the facing direction
	return z


## A ground zone made by a passive (dodging leaves fire or ice).
static func passive_zone(hero: Node3D, data: Dictionary) -> void:
	var s := SkillData.new()
	s.affinity = StringName(data.affinity)
	s.damage = int(data.damage)
	s.duration = data.duration
	s.tick = data.tick
	s.radius = data.radius
	s.slow = data.get("slow", 1.0)
	s.status = Affinity.STATUS[s.affinity] if s.damage > 0 else &""
	zone(hero, s, hero.global_position, hero.facing_3d(), hero.scale_damage(s.damage, s))


static func line(hero: Node3D, s: SkillData, at: Vector3, face: Vector3, dmg: int) -> void:
	var group: Variant = {} if s.once or s.kind == SkillData.Kind.BEAM else null
	var n := maxi(1, s.count if s.kind != SkillData.Kind.BEAM else int(s.length / 1.2))
	for i in n:
		var point := at + face * (s.length * (i + 1) / n)
		var size := 0.55 * s.scale if s.kind == SkillData.Kind.BEAM else 0.8 * s.scale
		explosion(hero, point, dmg, s.affinity, size, s, s.delay + s.step_delay * i)
		if group != null:
			var last: Node = hero.get_parent().get_child(-1)
			if last is Hitbox:
				last.once_group = group


static func rain(hero: Node3D, s: SkillData, center: Vector3, dmg: int) -> void:
	var steps := s.count if s.on_marked == &"" else int(s.duration / maxf(s.interval, 0.1))
	var wait := s.duration / maxi(steps, 1)
	for i in steps:
		if not is_instance_valid(hero):
			return
		if s.on_marked != &"":
			for e in enemies_with(hero.global_position, s.radius, s.on_marked):
				explosion(hero, e.global_position, dmg, s.affinity, 0.8, s)
		else:
			var a := randf() * TAU
			var r := sqrt(randf()) * s.radius  # where it lands is random; the damage never is
			explosion(hero, center + Vector3(cos(a), 0, sin(a)) * r, dmg, s.affinity, 0.8, s, 0.0)
		await hero.get_tree().create_timer(wait, false).timeout


static func wall(hero: Node3D, s: SkillData, center: Vector3, face: Vector3) -> void:
	var across := face.cross(Vector3.UP).normalized()
	var pieces := maxi(2, int(s.length / 1.0))
	var made: Array[Node3D] = []
	for i in pieces:
		var piece: Node3D = PROPS[s.prop].instantiate()
		hero.get_parent().add_child(piece)
		piece.global_position = center + across * (i - (pieces - 1) / 2.0) * 1.0
		if s.affinity == &"hielo":
			for sprite in piece.find_children("*", "Sprite3D", false):
				if sprite.name == "Sprite":
					sprite.modulate = Color(0.7, 0.95, 1.5)
		made.append(piece)
	await hero.get_tree().create_timer(s.duration, false).timeout
	for piece in made:
		if is_instance_valid(piece):
			if s.shatter_damage > 0 and is_instance_valid(hero):
				explosion(hero, piece.global_position, hero.scale_damage(s.shatter_damage, s), s.affinity, 0.8, s)
			piece.queue_free()


# --- queries -----------------------------------------------------------------------------------

static func nearest_enemy(from: Vector3, reach: float, accept := Callable()) -> Node3D:
	var best: Node3D = null
	var best_d := reach
	var tree := Engine.get_main_loop() as SceneTree
	for e: Node3D in tree.get_nodes_in_group("enemies"):
		if not e.visible or (e.has_method("is_alive") and not e.is_alive()):
			continue
		var d := flat(e.global_position - from).length()
		if d <= best_d and (not accept.is_valid() or accept.call(e)):
			best = e
			best_d = d
	return best


static func enemies_with(from: Vector3, reach: float, status: StringName) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var tree := Engine.get_main_loop() as SceneTree
	for e: Node3D in tree.get_nodes_in_group("enemies"):
		var st: StatusEffects = e.get_node_or_null("Status")
		if e.visible and st and st.has(status) and flat(e.global_position - from).length() <= reach:
			out.append(e)
	return out


static func flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


# --- helpers ------------------------------------------------------------------------------------

## An enemy's slam: an area around `at` that hurts only the hero (the enemy's warning came before).
static func enemy_blast(enemy: Node3D, at: Vector3, dmg: int, affinity: StringName, radius: float) -> void:
	var blast := Hitbox.new()
	blast.set_script(BLAST_SCRIPT)
	blast.damage = dmg
	blast.push = 9.0
	blast.attacker = enemy
	blast.collision_layer = 0
	blast.collision_mask = HERO_HURTBOX
	blast.affinity = affinity
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	shape.position.y = 0.6
	blast.add_child(shape)
	var sprite := AnimatedSprite3D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = Affinity.frames(_explosion_frames(), affinity)
	sprite.animation = &"burst"
	sprite.pixel_size = 0.0449 * radius / 1.2
	sprite.offset = Vector2(0, 16)
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	blast.add_child(sprite)
	enemy.get_parent().add_child(blast)
	blast.global_position = at + Vector3(0, 0, 0.05)


## An enemy's shot: flies straight and hurts only the hero; walls stop it.
static func enemy_bolt(enemy: Node3D, from: Vector3, direction: Vector3, dmg: int, affinity: StringName, speed := 9.0) -> void:
	var bolt: Hitbox = BOLT.instantiate()
	bolt.damage = dmg
	bolt.push = 5.0
	bolt.attacker = enemy
	bolt.affinity = affinity
	bolt.speed = speed
	bolt.lifetime = 1.6
	bolt.direction = direction
	enemy.get_parent().add_child(bolt)
	bolt.collision_layer = 0
	bolt.collision_mask = HERO_HURTBOX | 1
	bolt.get_node("Sprite").sprite_frames = Affinity.frames(bolt.get_node("Sprite").sprite_frames, affinity)
	bolt.global_position = from


static func _setup(hb: Hitbox, hero: Node3D, s: SkillData, dmg: int) -> void:
	hb.damage = dmg
	hb.attacker = hero
	hb.from_hero = true
	hb.collision_layer = 0
	hb.collision_mask = ENEMY_HURTBOXES | (1 if hb.has_method("_burst") else 0)  # projectiles also stop at walls
	if s:
		hb.skill = s
		hb.push = s.push
		hb.affinity = s.affinity
		hb.status = s.status
		hb.stacks = s.stacks
		hb.status_seconds = s.status_seconds


static func _explosion_frames() -> SpriteFrames:
	if _blast_frames == null:
		var burst := BURST.instantiate()
		_blast_frames = burst.get_node("Sprite").sprite_frames
		burst.free()
	return _blast_frames


static func _puff(hero: Node3D, at: Vector3, affinity: StringName) -> void:
	var spark: AnimatedSprite3D = SPARK.instantiate()
	spark.sprite_frames = Affinity.frames(spark.sprite_frames, affinity)
	hero.get_parent().add_child(spark)
	spark.global_position = at + Vector3(0, 0.9, 0.1)


static func _warning_mark(hero: Node3D, at: Vector3, radius: float, affinity: StringName) -> Node3D:
	var mark := Sprite3D.new()
	mark.texture = preload("res://assets/environment/textures/blob_shadow.png")
	mark.axis = Vector3.AXIS_Y
	mark.modulate = Color(Affinity.color(affinity), 0.6)
	mark.shaded = false
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mark.pixel_size = radius * 2.0 / mark.texture.get_width()
	hero.get_parent().add_child(mark)
	mark.global_position = Vector3(at.x, hero.global_position.y + 0.05, at.z)
	return mark
