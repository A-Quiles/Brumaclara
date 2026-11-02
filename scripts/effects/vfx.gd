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

const PX := 0.0449  ## the game's pixel: rings, glows and bits are drawn at it, whatever their size
static var _quads := {}
static var _ramps := {}
static var _rings := {}  # radius in px -> texture
static var _glows := {}
static var _discs := {}


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
	glow(parent, at + Vector3(0, 0.7, 0.2), affinity, 1.1 * size)  # smaller core: it must not hide whoever stands there (plan 4, «Efectos»)
	if size >= 0.7:  # the small ones (beams, rains) would light up the screen all the time
		flash(parent, at, affinity, 1.6 + size)


## A shock ring on the ground that grows and fades. It grows by adding pixels, never by enlarging
## them (docs/plan_unificacion_artistica.md, 3.5): each step is a ring drawn at the game's pixel.
static func ring(parent: Node, at: Vector3, affinity: StringName, radius: float, seconds := 0.35) -> void:
	var s := Sprite3D.new()
	var full := maxi(4, roundi(radius / PX))
	s.texture = _ring_texture(maxi(3, roundi(full * 0.3)))
	s.axis = Vector3.AXIS_Y
	s.shaded = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	s.modulate = RAMPS.get(affinity, RAMPS[&""])[1]
	s.pixel_size = PX
	parent.add_child(s)
	s.global_position = at + Vector3(0, 0.06, 0)
	var t := s.create_tween().set_parallel()
	t.tween_method(func(f: float) -> void: s.texture = _ring_texture(maxi(3, roundi(full * f))), 0.3, 1.0, seconds) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(s, "modulate:a", 0.0, seconds).set_delay(seconds * 0.3)
	t.chain().tween_callback(s.queue_free)


## A bright core that swells and fades (additive): the punch of an impact. Stepped bands at the game's
## pixel; it swells by redrawing at a bigger radius.
static func glow(parent: Node, at: Vector3, affinity: StringName, radius: float, seconds := 0.25) -> void:
	var s := Sprite3D.new()
	var full := maxi(3, roundi(radius / PX))
	s.texture = _glow_texture(maxi(2, roundi(full * 0.4)))
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.pixel_size = PX
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.vertex_color_use_as_albedo = true
	s.material_override = mat
	s.modulate = RAMPS.get(affinity, RAMPS[&""])[1]
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(s)
	s.global_position = at
	var t := s.create_tween().set_parallel()
	mat.albedo_texture = s.texture  # the override material draws the texture, not the sprite
	t.tween_method(func(f: float) -> void:
		s.texture = _glow_texture(maxi(2, roundi(full * f)))
		mat.albedo_texture = s.texture, 0.4, 1.0, seconds * 0.5)
	t.tween_property(s, "modulate:a", 0.0, seconds).set_delay(seconds * 0.3)
	t.chain().tween_callback(s.queue_free)


## A soft-edged oval patch on the ground, `size` world units, at the game's pixel (warning marks and
## the glow under ground zones): the edge is dithered in two steps instead of blurred.
static func ground_patch(size: Vector2) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = _disc_texture(maxi(2, roundi(size.x / PX / 2.0)), maxi(2, roundi(size.y / PX / 2.0)))
	s.axis = Vector3.AXIS_Y
	s.pixel_size = PX
	s.shaded = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return s


## A short flash of the affinity's light (lights the ground and whoever stands near).
static func flash(parent: Node, at: Vector3, affinity: StringName, reach := 3.0, seconds := 0.22) -> void:
	var l := OmniLight3D.new()
	l.light_color = RAMPS.get(affinity, RAMPS[&""])[1]
	l.light_energy = 2.6
	l.omni_range = reach
	l.shadow_enabled = false
	l.set_meta("transient", true)  # DayNight leaves it alone
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
	p.emitting = false
	return p


static func _free_later(node: Node, seconds: float) -> void:
	node.get_tree().create_timer(seconds, false).timeout.connect(node.queue_free)


## A square of `size` units snapped to whole game pixels, so the bits stay pixel art.
static func _quad(size: float) -> QuadMesh:
	var key := maxf(2.0, roundf(size / PX)) * PX
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


## A hard-edged ring `r` pixels across the radius, two pixels thick.
static func _ring_texture(r: int) -> Texture2D:
	if not _rings.has(r):
		var size := r * 2 + 2
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		for y in size:
			for x in size:
				var d := Vector2(x + 0.5 - size / 2.0, y + 0.5 - size / 2.0).length()
				if d >= r - 2.0 and d < r:
					img.set_pixel(x, y, Color(1, 1, 1, 1.0 if d >= r - 1.0 else 0.55))
		_rings[r] = ImageTexture.create_from_image(img)
	return _rings[r]


## A round glow `r` pixels across the radius in three stepped bands (not smooth: stays pixel art).
static func _glow_texture(r: int) -> Texture2D:
	if not _glows.has(r):
		var size := r * 2
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		for y in size:
			for x in size:
				var d := Vector2(x + 0.5 - r, y + 0.5 - r).length() / r
				var a := 1.0 if d < 0.35 else (0.6 if d < 0.65 else (0.25 if d < 0.95 else 0.0))
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_glows[r] = ImageTexture.create_from_image(img)
	return _glows[r]


## A filled oval (rx, ry pixels) whose outer band is a checkerboard dither: soft without blur.
static func _disc_texture(rx: int, ry: int) -> Texture2D:
	var key := Vector2i(rx, ry)
	if not _discs.has(key):
		var img := Image.create(rx * 2, ry * 2, false, Image.FORMAT_RGBA8)
		for y in ry * 2:
			for x in rx * 2:
				var d := Vector2((x + 0.5 - rx) / rx, (y + 0.5 - ry) / ry).length()
				if d < 0.8 or (d < 1.0 and (x + y) % 2 == 0):
					img.set_pixel(x, y, Color(1, 1, 1, 1.0 if d < 0.8 else 0.7))
		_discs[key] = ImageTexture.create_from_image(img)
	return _discs[key]
