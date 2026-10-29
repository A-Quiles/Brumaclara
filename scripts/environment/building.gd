extends StaticBody3D
## A building made of house shells and roof ornaments. It turns see-through while it stands
## between the camera and the hero (see occlusion_fader.gd).

const FADED_ALPHA := 0.5


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
