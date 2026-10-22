@tool
class_name TownTerrain
extends StaticBody3D
## Natural ground for a town on a hillside: flat shelves where houses stand, joined by slopes whose
## outline wanders and whose steepness changes along the way, so nothing is straight. The ground
## texture (grass, rock on steep parts, streets painted from a mask) comes from town_terrain.gdshader.
## The same height function places houses, props and people (see height()).

## [x0, x1, z0, z1, level, slope width] of each shelf, lowest first; each one rises from the ground below it
@export var shelves: Array = []
## [x, z, radius] where streets climb between shelves: the slope there is wide and walkable
@export var ramps: Array = []
@export var bounds := Rect2(-44, -54, 88, 98)  ## x, z, width, depth of the ground
@export var step := 0.5  ## grid spacing in world units
@export var surface: ShaderMaterial

var _noise: FastNoiseLite


func _ready() -> void:
	_build()


func height(x: float, z: float) -> float:
	if _noise == null:
		_noise = FastNoiseLite.new()
		_noise.seed = 5
		_noise.frequency = 0.07
	var h := 0.0
	for s in shelves:
		var dx := maxf(maxf(s[0] - x, x - s[1]), 0.0)
		var dz := maxf(maxf(s[2] - z, z - s[3]), 0.0)
		var outside := Vector2(dx, dz).length() + _noise.get_noise_2d(x, z) * 2.2  # the edge wanders
		var base: float = s[5] if s.size() > 5 else 4.0
		var width := base * (1.0 + 0.4 * _noise.get_noise_2d(z * 1.7 + 50.0, x * 1.7))  # and so does the slope
		for r in ramps:
			width = lerpf(width, maxf(width, 9.0), clampf(1.0 - Vector2(x - r[0], z - r[1]).length() / r[2], 0.0, 1.0))
		var t := clampf(1.0 - outside / width, 0.0, 1.0)
		h = lerpf(h, s[4], t * t * (3.0 - 2.0 * t))
	return h


func _build() -> void:
	if shelves.is_empty():
		return
	for child in get_children():
		child.free()
	var cols := int(bounds.size.x / step) + 1
	var rows := int(bounds.size.y / step) + 1
	var heights := PackedFloat32Array()
	heights.resize(cols * rows)
	for r in rows:
		for c in cols:
			heights[r * cols + c] = height(bounds.position.x + c * step, bounds.position.y + r * step)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var at := func(c: int, r: int) -> Vector3:
		return Vector3(bounds.position.x + c * step, heights[r * cols + c], bounds.position.y + r * step)
	for r in rows - 1:
		for c in cols - 1:
			var a: Vector3 = at.call(c, r)
			var b: Vector3 = at.call(c + 1, r)
			var d: Vector3 = at.call(c, r + 1)
			var e: Vector3 = at.call(c + 1, r + 1)
			for v in [a, b, e, a, e, d]:
				st.add_vertex(v)
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = "Ground"
	mesh.mesh = st.commit()
	mesh.material_override = surface
	add_child(mesh)
	var shape := HeightMapShape3D.new()
	shape.map_width = cols
	shape.map_depth = rows
	shape.map_data = heights
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	collision.scale = Vector3(step, 1, step)
	collision.position = Vector3(bounds.position.x + bounds.size.x / 2.0, 0, bounds.position.y + bounds.size.y / 2.0)
	add_child(collision)
