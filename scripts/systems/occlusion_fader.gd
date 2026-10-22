extends Camera3D
## Fades the buildings that hide the hero: rays run from the camera to the hero's feet, waist and
## head, and every "occluder" they cross turns see-through until it no longer covers the hero.

var _faded := {}  # occluder -> true


func _physics_process(_delta: float) -> void:
	var hero := get_parent() as Node3D
	if hero == null:
		return
	var space := get_world_3d().direct_space_state
	var hit := {}
	for height in [0.2, 1.0, 2.0]:
		var target := hero.global_position + Vector3(0, height, 0)
		var query := PhysicsRayQueryParameters3D.create(target + global_basis.z * 60.0, target, 1)
		for i in 4:  # see through up to four layers of buildings
			var result := space.intersect_ray(query)
			if result.is_empty():
				break
			if result.collider.is_in_group("occluder"):
				hit[result.collider] = true
			query.exclude = query.exclude + [result.rid]
	for node in hit:
		if not _faded.has(node):
			node.set_faded(true)
	for node in _faded:
		if not hit.has(node) and is_instance_valid(node):
			node.set_faded(false)
	_faded = hit
