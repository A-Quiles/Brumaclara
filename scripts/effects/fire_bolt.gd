extends Hitbox
## A skill projectile (Chispa and every other PROJECTILE skill): flies straight and bursts on the
## first enemy, tree or wall it meets. It can pierce, bounce to another enemy, explode in an area,
## split into shards or leave embers, as its skill says. Drawn with its affinity's art.

@export var speed := 14.0
@export var lifetime := 0.9
@export var impact: PackedScene  ## effect left where it bursts

var direction := Vector3.FORWARD
var _bounces_left := 0
var _hit_before: Array[Area3D] = []


func _ready() -> void:
	super()
	set_active(true)
	if skill:
		speed = skill.speed
		lifetime = clampf(12.0 / speed, 0.6, 3.0)
		_bounces_left = skill.bounce
		scale = Vector3.ONE * skill.scale
		$Sprite.sprite_frames = Affinity.frames($Sprite.sprite_frames, affinity)
	origin = global_position
	landed.connect(_on_landed)
	body_entered.connect(_burst.unbind(1))
	get_tree().create_timer(lifetime).timeout.connect(_burst)
	$Sprite.flip_h = View.to_screen(direction).x < 0.0
	$Sprite.play()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	super(delta)


func _on_landed(target: Hurtbox) -> void:
	_hit_before.append(target)
	if skill and skill.pierce:
		return
	if _bounces_left > 0:
		var next := SkillCaster.nearest_enemy(global_position, 4.0, func(e: Node3D) -> bool:
			return e.get_node_or_null("Hurtbox") not in _hit_before)
		if next:
			_bounces_left -= 1
			direction = SkillCaster.flat(next.global_position - global_position).normalized()
			$Sprite.flip_h = View.to_screen(direction).x < 0.0
			set_active(true)
			return
	_burst()


func _burst() -> void:
	if is_queued_for_deletion():
		return
	var at := global_position
	if impact:
		var fx: AnimatedSprite3D = impact.instantiate()
		fx.sprite_frames = Affinity.frames(fx.sprite_frames, affinity)
		get_parent().add_child(fx)
		fx.global_position = at + Vector3(0, -0.3, 0.05)
	Vfx.burst(get_parent(), at + Vector3(0, -0.9, 0), affinity, 0.55)
	if skill and attacker and is_instance_valid(attacker):
		var floor_at := Vector3(at.x, attacker.global_position.y, at.z)
		if skill.explode_radius > 0.0:
			SkillCaster.explosion(attacker, floor_at, damage, affinity, skill.explode_radius / 1.2, skill)
		for i in skill.split:
			var angle := TAU * i / skill.split
			SkillCaster.projectile(attacker, skill, floor_at + Vector3(0, 0.95, 0), Vector3(cos(angle), 0, sin(angle)),
					attacker.scale_damage(skill.split_damage, skill), {"split": 0, "explode_radius": 0.0, "scale": 0.6})
		for i in skill.embers:
			var angle := TAU * i / skill.embers
			SkillCaster.explosion(attacker, floor_at + Vector3(cos(angle), 0, sin(angle)) * 1.8,
					attacker.scale_damage(skill.ember_damage, skill), affinity, 0.6, null, 0.15 * (i + 1))
	queue_free()
