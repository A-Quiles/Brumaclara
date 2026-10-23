@tool
class_name Stairs
extends StaticBody3D
## A flight of stairs climbing toward -z from its origin. The steps are only for the eye; the hero
## walks on one hidden ramp through the middle of the treads, so any riser height climbs smoothly
## (a capsule cannot step up real boxes). Keep rise/(steps*tread) under the hero's 50° floor limit.

@export var width := 3.0:
	set(v): width = v; _rebuild()
@export var rise := 1.8:  ## total height climbed
	set(v): rise = v; _rebuild()
@export_range(1, 40) var steps := 6:
	set(v): steps = v; _rebuild()
@export var tread := 0.5:  ## depth of each step
	set(v): tread = v; _rebuild()
@export var material: Material:  ## the steps' look; plain grey when empty (greybox)
	set(v): material = v; _rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		child.free()  # generated pieces are never saved in the scene
	var riser := rise / steps
	for i in steps:
		var h := (i + 1) * riser
		var mesh := MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		mesh.mesh.size = Vector3(width, h, tread)
		mesh.position = Vector3(0, h / 2.0, -tread * (i + 0.5))
		mesh.material_override = material
		add_child(mesh)
	# side profile of the ramp: through the middle of each tread, flat on top of the last step
	var run := steps * tread
	var profile := [Vector2(tread / 2.0, 0), Vector2(-run, 0), Vector2(-run, rise), Vector2(-(steps - 0.5) * tread, rise)]
	var points := PackedVector3Array()
	for side in [-width / 2.0, width / 2.0]:
		for p in profile:
			points.append(Vector3(side, p.y, p.x))
	var hull := ConvexPolygonShape3D.new()
	hull.points = points  # before attaching: an empty hull logs an error
	var shape := CollisionShape3D.new()
	shape.shape = hull
	add_child(shape)
