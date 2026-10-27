class_name StatusEffects
extends Node
## The statuses on an enemy (docs/diseno_combate.md, section 4) and the damage it takes from the
## hero's hits: weaknesses, resistances, defense and every bonus the hero has learned. The owner
## (an enemy) has `data: EnemyData`, a Health child and `status_damage(amount, colour)`; it may have
## `is_recovering()` (just missed an attack).

signal applied(status: StringName)

## base seconds of each status
const DURATION := {&"quemadura": 3.0, &"frio": 4.0, &"congelado": 1.0, &"marca_electrica": 5.0,
		&"marca_sombra": 8.0, &"fisura": 5.0, &"deslumbrado": 1.0, &"aturdido": 0.8, &"fragil": 6.0,
		&"lento": 0.5}
const NAMES := {&"quemadura": "Quemado", &"frio": "Frío", &"congelado": "¡Congelado!",
		&"marca_electrica": "Marca", &"marca_sombra": "Sombra", &"fisura": "Fisura",
		&"deslumbrado": "Deslumbrado", &"aturdido": "¡Aturdido!", &"fragil": "Frágil", &"lento": "Lento"}
const COLOURS := {&"quemadura": Color("ff8a3c"), &"frio": Color("8fd8ff"), &"congelado": Color("dff6ff"),
		&"marca_electrica": Color("b4b8ff"), &"marca_sombra": Color("a87ae0"), &"fisura": Color("c09060"),
		&"deslumbrado": Color("ffe880"), &"aturdido": Color("fff1b0"), &"fragil": Color("e0a0ff"),
		&"lento": Color("9fc8ff")}
const STUN_IMMUNITY := 6.0  ## bosses, after each stun

var _active := {}  ## status -> {"stacks": int, "left": float}
var _burn_clock := 0.0
var _dot_clock := 0.0
var _stun_immune := 0.0
var _zone_slow := 1.0
var _zone_slow_left := 0.0

@onready var _owner: Node = get_parent()


func _physics_process(delta: float) -> void:
	_stun_immune = maxf(_stun_immune - delta, 0.0)
	_zone_slow_left -= delta
	if _zone_slow_left <= 0.0:
		_zone_slow = 1.0
	for s in _active.keys():
		_active[s].left -= delta
		if _active[s].left <= 0.0:
			_active.erase(s)
	if has(&"quemadura"):
		_burn_clock += delta
		if _burn_clock >= 0.5:
			_burn_clock -= 0.5
			_owner.status_damage(3, COLOURS[&"quemadura"])
	var dot: float = Progress.stat("shadow_dot")
	if dot > 0.0 and has(&"marca_sombra"):
		_dot_clock += delta
		if _dot_clock >= 1.0:
			_dot_clock -= 1.0
			_owner.status_damage(roundi(dot * stacks(&"marca_sombra")), COLOURS[&"marca_sombra"])


func has(status: StringName) -> bool:
	return _active.has(status)


func stacks(status: StringName) -> int:
	return _active[status].stacks if _active.has(status) else 0


func is_boss() -> bool:
	return _owner.data != null and _owner.data.boss


## Speed factor for the owner's movement.
func speed_mult() -> float:
	if not can_act():
		return 0.0
	var m := _zone_slow
	if has(&"frio"):
		m = minf(m, 0.6)
	if has(&"lento"):
		m = minf(m, 0.5)
	return m


func can_act() -> bool:
	return not (has(&"aturdido") or has(&"congelado"))


## Dazzled enemies lose the hero for a moment (bosses only get a longer warning).
func blinded() -> bool:
	return has(&"deslumbrado") and not is_boss()


## Extra warning time before the owner's attacks.
func warning_bonus() -> float:
	return Progress.stat("warning_bonus") + (0.6 if has(&"deslumbrado") and is_boss() else 0.0)


## A zone keeps its slow on the enemies inside while it lasts.
func zone_slow(factor: float) -> void:
	_zone_slow = minf(_zone_slow, factor)
	_zone_slow_left = 0.6


func remove(status: StringName) -> int:
	var n := stacks(status)
	_active.erase(status)
	return n


func apply(status: StringName, amount := 1, seconds := 0.0) -> void:
	if status == &"":
		return
	var time: float = (seconds if seconds > 0.0 else DURATION.get(status, 1.0)) + Progress.stat("status_add." + status)
	match status:
		&"aturdido":
			if is_boss():
				if _stun_immune > 0.0:
					return
				_stun_immune = STUN_IMMUNITY
		&"congelado":
			if is_boss():
				status = &"frio"  # bosses only slow down
	var current: int = stacks(status)
	_active[status] = {"stacks": current + amount, "left": maxf(time, _active.get(status, {"left": 0.0}).left)}
	match status:
		&"frio":
			if stacks(&"frio") >= 3 and not is_boss():
				remove(&"frio")
				apply(&"congelado")
				_hero_event("freeze")
		&"marca_electrica":
			if stacks(&"marca_electrica") >= 3:
				remove(&"marca_electrica")
				_owner.status_damage(roundi(10 + Progress.stat("elec_discharge")), COLOURS[&"marca_electrica"])
		&"marca_sombra":
			_active[status].stacks = mini(stacks(status), 3 + int(Progress.stat("max_shadow_marks")))
		&"fisura":
			if stacks(&"fisura") >= 3:
				remove(&"fisura")
				if not is_boss():
					apply(&"aturdido", 1, 1.0)
	if current == 0 and has(status):
		applied.emit(status)


## The damage a hit really does, after applying everything; it also leaves the hit's statuses.
func take_hit(damage: int, source: Hitbox) -> int:
	if source == null or not source.from_hero:
		return damage
	var data: EnemyData = _owner.data
	var health: Health = _owner.get_node("Health")
	var skill := source.skill
	var m := 1.0
	var aff := source.affinity
	if data:
		if aff in data.weak:
			m *= 1.5
		elif aff in data.resist:
			m *= 0.5
		m *= 1.0 - data.defense
		if data.anomalous:
			m *= 1.0 + Progress.stat("anomalous_pct." + aff)
		if data.boss:
			m *= 1.0 + Progress.stat("boss_pct")
	if has(&"fisura"):
		m *= 1.2
	if has(&"fragil"):
		m *= 1.25
	var vs := 0.0
	for s in _active:
		vs += Progress.stat("vs_pct." + s)
	m *= 1.0 + vs
	if skill:
		var best := 1.0
		for s: String in skill.bonus_vs:
			if has(StringName(s)):
				best = maxf(best, skill.bonus_vs[s])
		m *= best
	var per_marked: float = Progress.stat("per_marked_pct." + aff)
	if per_marked > 0.0:
		m *= 1.0 + minf(0.1, per_marked * _marked_near(Affinity.STATUS.get(aff, &"")))
	if _owner.has_method("is_recovering") and _owner.is_recovering():
		m *= 1.0 + Progress.stat("punish_pct")
	if health.current < health.maximum * 0.25:
		m *= 1.0 + Progress.stat("execute_pct")
	if source.origin != Vector3.INF and source.global_position.distance_to(source.origin) > 5.0:
		m *= 1.0 + Progress.stat("far_pct." + aff)
	var extra := 0
	var hero := get_tree().get_first_node_in_group("player")
	if skill:
		if skill.consume != &"" and has(skill.consume):
			extra += skill.per_stack * remove(skill.consume)
		if skill.stack_status != &"" and hero:
			var n := stacks(skill.stack_status)
			hero.restore(skill.mp_per_stack * n, skill.hp_per_stack * n)
		if skill.stun_if != &"" and has(skill.stun_if):
			apply(&"aturdido", 1, skill.status_seconds)
	var total := damage + extra
	var final := 0 if total <= 0 else maxi(1, roundi(total * m))
	if source.status != &"":
		apply(source.status, source.stacks, source.status_seconds)
	if hero and hero.has_method("on_hit_landed"):
		hero.on_hit_landed(_owner, source, final)
	return final


## Called by the owner when it dies (some passives make burning enemies explode).
func on_owner_died() -> void:
	var blast: float = Progress.stat("burning_explode")
	if blast > 0.0 and has(&"quemadura"):
		SkillCaster.explosion(_owner, _owner.global_position, roundi(blast), &"fuego", 1.6)
	_active.clear()


func _marked_near(status: StringName) -> int:
	var hero := get_tree().get_first_node_in_group("player") as Node3D
	if hero == null or status == &"":
		return 0
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		var st: StatusEffects = e.get_node_or_null("Status")
		if st and st.has(status) and e.global_position.distance_to(hero.global_position) < 6.0:
			n += 1
	return n


func _hero_event(event: String) -> void:
	var hero := get_tree().get_first_node_in_group("player")
	if hero and hero.has_method("on_enemy_event"):
		hero.on_enemy_event(event, _owner)
