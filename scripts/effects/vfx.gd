class_name Vfx
## The flashy part of the magic, drawn by the engine on top of the sprite effects so every skill
## reads at a glance: pixel-square particles in the affinity's colours, a shock ring on the ground,
## a brief flash of light, a trail behind projectiles, an aura when a skill touches the hero and
## motes rising inside ground zones. Each affinity moves its own way: fire climbs, ice sparkles and
## falls, lightning snaps outward, shadow drifts and swirls, earth throws heavy debris, light rises.

## colours from hot to fading (the last one transparent)
const RAMPS := {
	&"fuego": [Color("fff4a8"), Color("ffb030"), Color("ff5a1c"), Color(0.6, 0.12, 0.05, 0.0)],
	&"hielo": [Color("ffffff"), Color("bff0ff"), Color("6ac4ff"), Color(0.3, 0.55, 1.0, 0.0)],
	&"rayo": [Color("ffffff"), Color("e8ecff"), Color("9aa0ff"), Color(0.5, 0.4, 1.0, 0.0)],
	&"sombra": [Color("e6d0ff"), Color("a87ae0"), Color("5a2a8a"), Color(0.15, 0.05, 0.25, 0.0)],
	&"tierra": [Color("f0d8a8"), Color("c09060"), Color("7a5a3a"), Color(0.35, 0.25, 0.15, 0.0)],
	&"luz": [Color("ffffff"), Color("fff6c0"), Color("ffe060"), Color(1.0, 0.85, 0.3, 0.0)],
	&"": [Color("ffffff"), Color("f4e9c8"), Color("c8b890"), Color(0.6, 0.55, 0.45, 0.0)],
}
## how the bits move: [gravity y, speed, spread, damping, lifetime]
const MOTION := {
	&"fuego": [3.5, 5.0, 70.0, 2.0, 0.6], &"hielo": [-7.0, 5.5, 80.0, 1.0, 0.7], &"rayo": [0.0, 11.0, 180.0, 8.0, 0.28],
	&"sombra": [1.0, 2.5, 180.0, 1.5, 0.9], &"tierra": [-14.0, 7.0, 55.0, 0.5, 0.8], &"luz": [4.0, 3.5, 180.0, 1.0, 0.8],
	&"": [-6.0, 5.0, 90.0, 1.0, 0.5],
}

static var _quads := {}
static var _ramps := {}
static var _ring: Texture2D
static var _glow: Texture2D


## An explosion's dressing at `at` (feet level); `size` 1 is about 1.2 units of radius.
static func burst(parent: Node, at: Vector3, affinity: StringName, size := 1.0, delay := 0.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	if delay > 0.0:
		await parent.get_tree().create_timer(delay, false).timeout
		if not is_instance_valid(parent):
			return
	var m: Array = MOTION.get(affinity, MOTION[&""])
	var p := _particles(affinity, int(40 + 40 * size), m[4], 0.15 * clampf(size, 0.6, 1.6))
	p.one_shot = true
	p.explosiveness = 0.92
	p.direction = Vector3.UP
	p.spread = m[2]
	p.gravity = Vector3(0, m[0], 0)
	p.initial_velocity_min = m[1] * 0.45 * size
	p.initial_velocity_max = m[1] * size
	p.damping_min = m[3]
	p.damping_max = m[3] * 1.5
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.3 * size
	if affinity == &"sombra":
		p.orbit_velocity_min = 0.6
		p.orbit_velocity_max = 1.2
	parent.add_child(p)
	p.global_position = at + Vector3(0, 0.6, 0.1)
	p.emitting = true
	_free_later(p, m[4] + 0.3)
	ring(parent, at, affinity, 1.4 * size)
	glow(parent, at + Vector3(0, 0.7, 0.2), affinity, 1.6 * size)
	if size >= 0.7:  # the small ones (beams, rains) would light up the screen all the time
		flash(parent, at, affinity, 1.6 + size)


## A shock ring on the ground that grows and fades.
static func ring(parent: Node, at: Vector3, affinity: StringName, radius: float, seconds := 0.35) -> void:
	var s := Sprite3D.new()
	s.texture = _ring_texture()
	s.axis = Vector3.AXIS_Y
	s.shaded = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	s.modulate = RAMPS.get(affinity, RAMPS[&""])[1]
	s.pixel_size = radius * 2.0 / s.texture.get_width()
	parent.add_child(s)
	s.global_position = at + Vector3(0, 0.06, 0)
	s.scale = Vector3.ONE * 0.3
	var t := s.create_tween().set_parallel()
	t.tween_property(s, "scale", Vector3.ONE, seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(s, "modulate:a", 0.0, seconds).set_delay(seconds * 0.3)
	t.chain().tween_callback(s.queue_free)


## A soft bright core that swells and fades (additive): the punch of an impact.
static func glow(parent: Node, at: Vector3, affinity: StringName, radius: float, seconds := 0.25) -> void:
	var s := Sprite3D.new()
	s.texture = _glow_texture()
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.pixel_size = radius * 2.0 / s.texture.get_width()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_texture = s.texture
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.vertex_color_use_as_albedo = true
	s.material_override = mat
	s.modulate = RAMPS.get(affinity, RAMPS[&""])[1]
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(s)
	s.global_position = at
	s.scale = Vector3.ONE * 0.4
	var t := s.create_tween().set_parallel()
	t.tween_property(s, "scale", Vector3.ONE, seconds * 0.5)
	t.tween_property(s, "modulate:a", 0.0, seconds).set_delay(seconds * 0.3)
	t.chain().tween_callback(s.queue_free)


## A short flash of the affinity's light (lights the ground and whoever stands near).
static func flash(parent: Node, at: Vector3, affinity: StringName, reach := 3.0, seconds := 0.22) -> void:
	var l := OmniLight3D.new()
	l.light_color = RAMPS.get(affinity, RAMPS[&""])[1]
	l.light_energy = 2.6
	l.omni_range = reach
	l.shadow_enabled = false
	parent.add_child(l)
	l.global_position = at + Vector3(0, 1.0, 0.3)
	var t := l.create_tween()
	t.tween_property(l, "light_energy", 0.0, seconds)
	t.tween_callback(l.queue_free)


## A trail of sparks left behind a moving node (a projectile); it stops with the node.
static func trail(node: Node3D, affinity: StringName, size := 1.0) -> void:
	var m: Array = MOTION.get(affinity, MOTION[&""])
	var p := _particles(affinity, 34, 0.4, 0.12 * size)
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 180.0
	p.gravity = Vector3(0, m[0] * 0.4, 0)
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 1.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.12 * size
	node.add_child(p)
	p.emitting = true


## An aura round the hero (buffs, shields, heals, blinks): bits rise around the body for a moment.
static func aura(parent: Node, at: Vector3, affinity: StringName, seconds := 0.6) -> void:
	var p := _particles(affinity, 50, 0.8, 0.13)
	p.one_shot = true
	p.explosiveness = 0.5
	p.direction = Vector3.UP
	p.spread = 15.0
	p.gravity = Vector3(0, 2.5, 0)
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 2.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 0.7
	p.emission_ring_inner_radius = 0.4
	p.emission_ring_height = 0.1
	parent.add_child(p)
	p.global_position = at + Vector3(0, 0.15, 0)
	p.emitting = true
	_free_later(p, seconds + 1.0)
	ring(parent, at, affinity, 1.3, 0.45)
	flash(parent, at, affinity, 2.5, 0.35)


## Motes rising inside a ground zone for as long as it lasts (a child of the zone).
static func zone(owner: Node3D, affinity: StringName, size: Vector2) -> void:
	var p := _particles(affinity, int(clampf(size.x * size.y * 8.0, 20, 110)), 0.9, 0.12)
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0, 1.2, 0)
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.8
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(size.x / 2.0, 0.05, size.y / 2.0)
	p.position.y = 0.1
	owner.add_child(p)
	p.emitting = true


static func _particles(affinity: StringName, amount: int, life: float, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = maxi(amount, 4)
	p.lifetime = life
	p.mesh = _quad(size)
	p.color_ramp = _ramp(affinity)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	p.emitting = false
	return p


static func _free_later(node: Node, seconds: float) -> void:
	node.get_tree().create_timer(seconds, false).timeout.connect(node.queue_free)


## A square of `size` units: at the game's scale, a few pixels, so the bits stay pixel art.
static func _quad(size: float) -> QuadMesh:
	var key := snappedf(size, 0.01)
	if _quads.has(key):
		return _quads[key]
	var q := QuadMesh.new()
	q.size = Vector2(key, key)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = mat
	_quads[key] = q
	return q


static func _ramp(affinity: StringName) -> Gradient:
	if _ramps.has(affinity):
		return _ramps[affinity]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	g.colors = PackedColorArray(RAMPS.get(affinity, RAMPS[&""]))
	_ramps[affinity] = g
	return g


## A hard-edged pixel ring (two pixels thick on 32): stays crisp like the rest of the art.
static func _ring_texture() -> Texture2D:
	if _ring == null:
		var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in 32:
			for x in 32:
				var d := Vector2(x + 0.5 - 16.0, y + 0.5 - 16.0).length()
				if d >= 13.0 and d < 15.5:
					img.set_pixel(x, y, Color(1, 1, 1, 1.0 if d >= 14.0 else 0.55))
		_ring = ImageTexture.create_from_image(img)
	return _ring


## A round glow in steps of 16 px (stepped, not smooth, so it stays pixel art when it is big).
static func _glow_texture() -> Texture2D:
	if _glow == null:
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for y in 16:
			for x in 16:
				var d := Vector2(x + 0.5 - 8.0, y + 0.5 - 8.0).length() / 8.0
				var a := 1.0 if d < 0.35 else (0.6 if d < 0.65 else (0.25 if d < 0.95 else 0.0))
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_glow = ImageTexture.create_from_image(img)
	return _glow
