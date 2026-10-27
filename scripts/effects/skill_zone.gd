extends Hitbox
## A ZONE skill on the ground: strikes what is inside every `tick` for `duration`, slows it, marks it
## once, zaps one enemy per tick or changes the hero's numbers while the hero stands in it. It can
## be a circle or a line across the facing direction, and can follow the hero.

const SPARK := preload("res://scenes/effects/spark.tscn")

var radius := 1.5
var duration := 3.0
var tick := 0.5
var slow := 1.0
var line_length := 0.0
var follow: Node3D
var single_target := false
var once_status := &""  ## applied once per enemy (marks, slips)
var once_stacks := 1
var once_seconds := 0.0
var self_mods := {}

var _age := 0.0
var _clock := 0.0
var _touched := {}


func _ready() -> void:
	super()
	set_deferred("monitoring", true)  # slows and marks need to see what is inside even with no damage
	var shape := CollisionShape3D.new()
	if line_length > 0.0:
		var box := BoxShape3D.new()
		box.size = Vector3(line_length, 2.0, radius * 2.0)
		shape.shape = box
	else:
		var cyl := CylinderShape3D.new()
		cyl.radius = radius
		cyl.height = 2.0
		shape.shape = cyl
	shape.position.y = 0.8
	add_child(shape)
	var glow := Sprite3D.new()  # placeholder look until the zone effects are drawn: a tinted glow on the ground
	glow.texture = preload("res://assets/environment/textures/blob_shadow.png")
	glow.axis = Vector3.AXIS_Y
	glow.modulate = Color(Affinity.color(affinity), 0.55)
	glow.shaded = false
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glow.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var size := Vector2(line_length if line_length > 0.0 else radius * 2.0, radius * 2.0)
	glow.pixel_size = size.x / glow.texture.get_width()
	glow.scale = Vector3(1.0, 1.0, size.y / size.x * glow.texture.get_width() / glow.texture.get_height())
	glow.position.y = 0.04
	add_child(glow)
	_fire()


func _physics_process(delta: float) -> void:
	super(delta)
	if is_instance_valid(follow):
		global_position = follow.global_position
	_age += delta
	_clock += delta
	if _clock >= tick:
		_clock -= tick
		_fire()
	if not monitoring:
		return
	for area in get_overlapping_areas():
		if area is Hurtbox and area.get_parent().has_node("Status"):
			var status: StatusEffects = area.get_parent().get_node("Status")
			if slow < 1.0:
				status.zone_slow(slow)
			if once_status != &"" and not _touched.has(area):
				_touched[area] = true
				status.apply(once_status, once_stacks, once_seconds)
	if not self_mods.is_empty():
		var hero := attacker as Node3D
		if hero and SkillCaster.flat(hero.global_position - global_position).length() < radius + 0.3:
			hero.zone_mods(self_mods)
	if _age >= duration:
		queue_free()


func _fire() -> void:
	if single_target:
		var target := SkillCaster.nearest_enemy(global_position, radius)
		if target:
			SkillCaster.explosion(attacker, target.global_position, damage, affinity, 0.5, skill)
	elif damage > 0 or status != &"":
		set_active(true)
	var spark: AnimatedSprite3D = SPARK.instantiate()
	spark.sprite_frames = Affinity.frames(spark.sprite_frames, affinity)
	get_parent().add_child(spark)
	var r := randf() * radius * 0.8
	var a := randf() * TAU
	var spread := Vector3(randf_range(-0.5, 0.5) * line_length, 0, 0) if line_length > 0.0 else Vector3(cos(a), 0, sin(a)) * r
	spark.global_position = global_position + global_transform.basis * spread + Vector3(0, 0.4, 0.05)
