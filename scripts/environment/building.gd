extends StaticBody3D
## A building made of house shells and roof ornaments. It turns a little see-through while it hides
## the hero completely (see occlusion_fader.gd).

const FADED_ALPHA := 0.55  # only a little see-through: the hero shows, the building still reads


func _ready() -> void:
	add_to_group("occluder")


func set_faded(faded: bool) -> void:
	for node in find_children("*", "GeometryInstance3D", true, false):
		if node is MeshInstance3D and node.mesh:
			for i in node.mesh.get_surface_count():
				var mat := node.mesh.surface_get_material(i) as BaseMaterial3D
				if mat == null:  # stone plinths and steps keep their shader
					continue
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if faded else BaseMaterial3D.TRANSPARENCY_DISABLED
				mat.albedo_color.a = FADED_ALPHA if faded else 1.0
		elif node is SpriteBase3D:
			node.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED if faded else SpriteBase3D.ALPHA_CUT_DISCARD
			node.modulate.a = FADED_ALPHA if faded else 1.0
