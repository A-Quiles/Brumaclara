@tool
extends MeshInstance3D
## Builds a gabled house shell (walls, gables, roof) from pixel-art face textures.
## Origin: centre of the footprint at ground level. Ridge runs front-to-back (gable faces the camera).

@export var size := Vector3(6, 3, 5):  ## width, wall height, depth (world units, 16 texels each)
	set(value):
		size = value
		_build()
@export var roof_height := 2.5:
	set(value):
		roof_height = value
		_build()
@export var overhang := 0.35:
	set(value):
		overhang = value
		_build()
@export var front_texture: Texture2D
@export var side_texture: Texture2D
@export var gable_texture: Texture2D
@export var roof_texture: Texture2D


func _ready() -> void:
	_build()


func _material(texture: Texture2D, repeat := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.texture_repeat = repeat
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _quad(st: SurfaceTool, corners: Array, uvs: Array, normal: Vector3) -> void:
	# corners/uvs in order: bottom-left, bottom-right, top-right, top-left
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_normal(normal)
		st.set_uv(uvs[i])
		st.add_vertex(corners[i])


func _build() -> void:
	if not is_inside_tree() or front_texture == null:
		return
	var w := size.x / 2.0
	var h := size.y
	var d := size.z / 2.0
	var full := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	var built := ArrayMesh.new()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_quad(st, [Vector3(-w, 0, d), Vector3(w, 0, d), Vector3(w, h, d), Vector3(-w, h, d)], full, Vector3.BACK)
	st.commit(built)
	built.surface_set_material(0, _material(front_texture))

	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_quad(st, [Vector3(w, 0, d), Vector3(w, 0, -d), Vector3(w, h, -d), Vector3(w, h, d)], full, Vector3.RIGHT)
	_quad(st, [Vector3(-w, 0, -d), Vector3(-w, 0, d), Vector3(-w, h, d), Vector3(-w, h, -d)], full, Vector3.LEFT)
	_quad(st, [Vector3(w, 0, -d), Vector3(-w, 0, -d), Vector3(-w, h, -d), Vector3(w, h, -d)], full, Vector3.FORWARD)
	st.commit(built)
	built.surface_set_material(1, _material(side_texture))

	st = SurfaceTool.new()  # gable triangles, front and back
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in [d, -d]:
		var normal := Vector3.BACK if z > 0 else Vector3.FORWARD
		for v in [[Vector3(-w, h, z), Vector2(0, 1)], [Vector3(w, h, z), Vector2(1, 1)], [Vector3(0, h + roof_height, z), Vector2(0.5, 0)]]:
			st.set_normal(normal)
			st.set_uv(v[1])
			st.add_vertex(v[0])
	st.commit(built)
	built.surface_set_material(2, _material(gable_texture))

	st = SurfaceTool.new()  # roof slopes; UVs in world units so the shingles tile (2 units per texture)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var drop := overhang * roof_height / w
	var ridge := h + roof_height
	var length := Vector2(w + overhang, roof_height + drop).length() / 2.0
	var zf := d + overhang
	var span := (zf * 2.0) / 2.0
	for side in [-1.0, 1.0]:
		var eave := Vector3(side * (w + overhang), h - drop, 0)
		var normal := Vector3(side * roof_height, w, 0).normalized()
		_quad(st, [Vector3(eave.x, eave.y, zf), Vector3(0, ridge, zf), Vector3(0, ridge, -zf), Vector3(eave.x, eave.y, -zf)],
				[Vector2(0, length), Vector2(0, 0), Vector2(span, 0), Vector2(span, length)], normal)
	st.commit(built)
	built.surface_set_material(3, _material(roof_texture, true))
	mesh = built
