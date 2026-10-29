extends StaticBody3D
## The plaza's fountain: the drawing at full flow stays still and the water moves on top of it, as
## particles (pixel-sized drops that rise from the spout and fall back into the basin, and glints on
## the water), so the flow is smooth instead of pulsing between the three drawn stages.

const SPOUT := Vector3(0.05, 2.1, -0.35)  ## where the water leaves, from the fountain's feet
const WATER := [Color(0.92, 0.98, 1.0), Color(0.6, 0.85, 1.0), Color(0.36, 0.62, 0.95, 0.0)]


func _ready() -> void:
	var sprite := get_node_or_null("Sprite") as AnimatedSprite3D
	if sprite:
		sprite.stop()
		sprite.frame = sprite.sprite_frames.get_frame_count(sprite.animation) - 1  # the full flow
	add_child(_drops(SPOUT, 70, 1.05, Vector3(0, 1, 0), 28.0, 2.2, 0.065))  # the jet
	add_child(_drops(SPOUT + Vector3(0, -0.9, 0.0), 30, 0.7, Vector3(0, 0.3, 0), 80.0, 1.2, 0.05))  # the upper bowl's rim
	add_child(_glints())


func _drops(at: Vector3, amount: int, life: float, direction: Vector3, spread: float, speed: float, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = at
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.direction = direction
	p.spread = spread
	p.initial_velocity_min = speed * 0.75
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -6.5, 0)
	p.mesh = _quad(size)
	p.color_ramp = _ramp(WATER)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.05
	return p


func _glints() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = Vector3(0, 0.62, -0.4)
	p.amount = 14
	p.lifetime = 0.8
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(1.0, 0.0, 0.5)
	p.gravity = Vector3.ZERO
	p.initial_velocity_max = 0.0
	p.mesh = _quad(0.07)
	p.color_ramp = _ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.95), Color(0.8, 0.95, 1.0, 0.0)])
	return p


static func _quad(size: float) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = mat
	return q


static func _ramp(colours: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray(colours)
	return g
