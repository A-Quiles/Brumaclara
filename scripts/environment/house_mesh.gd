@tool
extends MeshInstance3D
## Builds a gabled house shell (four walls, two gable triangles, two roof slopes) from pixel-art textures.
## Origin: centre of the footprint at ground level. Faces: front +Z, back -Z, right +X, left -X.

@export var size := Vector3(4, 3, 4):  ## width (X), wall height (Y), depth (Z) in world units
	set(value):
		size = value
		_build()
@export var ridge_along_x := false:  ## false: gables face front/back; true: gables face left/right
	set(value):
		ridge_along_x = value
		_build()
@export var roof_height := 1.5:
	set(value):
		roof_height = value
		_build()
@export var overhang := 0.3:
	set(value):
		overhang = value
		_build()
@export var roof_tile := 0.0:  ## world size of one roof texture repeat; 0 stretches one image per slope
	set(value):
		roof_tile = value
		_build()
@export var front_texture: Texture2D
@export var back_texture: Texture2D
@export var left_texture: Texture2D
@export var right_texture: Texture2D
@export var gable_texture: Texture2D
@export var roof_texture: Texture2D  ## one slope, ridge at the top edge, eave at the bottom edge

const FULL_UV := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]


func _ready() -> void:
	_build()


func _build() -> void:
	if not is_inside_tree() or front_texture == null:
		return
	var out := ArrayMesh.new()
	_add_walls(out)
	_add_gables(out)
	_add_roof(out)
	mesh = out


func _add_walls(out: ArrayMesh) -> void:
	var w := size.x / 2.0
	var h := size.y
	var d := size.z / 2.0
	var side_tex := right_texture if right_texture else left_texture
	var walls := [
		[front_texture, [Vector3(-w, 0, d), Vector3(w, 0, d), Vector3(w, h, d), Vector3(-w, h, d)], Vector3.BACK],
		[back_texture if back_texture else side_tex, [Vector3(w, 0, -d), Vector3(-w, 0, -d), Vector3(-w, h, -d), Vector3(w, h, -d)], Vector3.FORWARD],
		[side_tex, [Vector3(w, 0, d), Vector3(w, 0, -d), Vector3(w, h, -d), Vector3(w, h, d)], Vector3.RIGHT],
		[left_texture if left_texture else side_tex, [Vector3(-w, 0, -d), Vector3(-w, 0, d), Vector3(-w, h, d), Vector3(-w, h, -d)], Vector3.LEFT],
	]
	for wall in walls:
		var st := _begin()
		_quad(st, wall[1], FULL_UV, wall[2])
		_commit(out, st, wall[0], false)


func _add_gables(out: ArrayMesh) -> void:
	if gable_texture == null:
		return
	var w := size.x / 2.0
	var h := size.y
	var d := size.z / 2.0
	var top := h + roof_height
	var tris := []
	if ridge_along_x:
		tris = [[Vector3(w, h, d), Vector3(w, h, -d), Vector3(w, top, 0), Vector3.RIGHT],
				[Vector3(-w, h, -d), Vector3(-w, h, d), Vector3(-w, top, 0), Vector3.LEFT]]
	else:
		tris = [[Vector3(-w, h, d), Vector3(w, h, d), Vector3(0, top, d), Vector3.BACK],
				[Vector3(w, h, -d), Vector3(-w, h, -d), Vector3(0, top, -d), Vector3.FORWARD]]
	var st := _begin()
	for t in tris:
		for v in [[t[0], Vector2(0, 1)], [t[2], Vector2(0.5, 0)], [t[1], Vector2(1, 1)]]:  # clockwise = front face
			st.set_normal(t[3])
			st.set_uv(v[1])
			st.add_vertex(v[0])
	_commit(out, st, gable_texture, false)


func _add_roof(out: ArrayMesh) -> void:
	if roof_texture == null:
		return
	var h := size.y
	var top := h + roof_height
	var half := size.z / 2.0 if ridge_along_x else size.x / 2.0   # horizontal distance eave -> ridge
	var length := (size.x if ridge_along_x else size.z) / 2.0 + overhang
	var drop := overhang * roof_height / half
	var e := half + overhang
	var y := h - drop
	var slopes := []  # each slope: eave-left, eave-right, ridge-right, ridge-left (seen from outside), normal
	if ridge_along_x:
		slopes.append([Vector3(-length, y, e), Vector3(length, y, e), Vector3(length, top, 0), Vector3(-length, top, 0), Vector3(0, half, roof_height)])
		slopes.append([Vector3(length, y, -e), Vector3(-length, y, -e), Vector3(-length, top, 0), Vector3(length, top, 0), Vector3(0, half, -roof_height)])
	else:
		slopes.append([Vector3(e, y, length), Vector3(e, y, -length), Vector3(0, top, -length), Vector3(0, top, length), Vector3(roof_height, half, 0)])
		slopes.append([Vector3(-e, y, -length), Vector3(-e, y, length), Vector3(0, top, length), Vector3(0, top, -length), Vector3(-roof_height, half, 0)])
	var uvs := FULL_UV
	if roof_tile > 0.0:
		var u := 2.0 * length / roof_tile
		var v := Vector2(e, roof_height + drop).length() / roof_tile
		uvs = [Vector2(0, v), Vector2(u, v), Vector2(u, 0), Vector2(0, 0)]
	var st := _begin()
	for s in slopes:
		_quad(st, [s[0], s[1], s[2], s[3]], uvs, (s[4] as Vector3).normalized())
	_commit(out, st, roof_texture, roof_tile > 0.0)


func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


func _commit(out: ArrayMesh, st: SurfaceTool, texture: Texture2D, repeat: bool) -> void:
	st.commit(out)
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.texture_repeat = repeat
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	out.surface_set_material(out.get_surface_count() - 1, material)


func _quad(st: SurfaceTool, corners: Array, uvs: Array, normal: Vector3) -> void:
	# corners/uvs: bottom-left, bottom-right, top-right, top-left (as seen from outside);
	# Godot treats clockwise triangles as front faces, so they get lit from their own side
	for i in [0, 2, 1, 0, 3, 2]:
		st.set_normal(normal)
		st.set_uv(uvs[i])
		st.add_vertex(corners[i])
