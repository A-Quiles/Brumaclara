extends Camera3D
## Fades the buildings that hide the hero: rays run from the camera to a grid of points on the
## hero (feet, waist, head; left, middle, right). An "occluder" turns see-through only when it
## blocks every point, that is, when it covers the hero completely; a partial cover stays opaque.

const HEIGHTS := [0.2, 1.0, 2.0]
const SIDES := [-0.35, 0.0, 0.35]

var _faded := {}  # occluder -> true


func _physics_process(_delta: float) -> void:
	var hero := get_parent() as Node3D
	if hero == null:
		return
	var space := get_world_3d().direct_space_state
	var side := global_basis.x
	var blocked := {}  # occluder -> how many points it blocks
	for height in HEIGHTS:
		for offset in SIDES:
			var target: Vector3 = hero.global_position + Vector3(0, height, 0) + side * offset
			var query := PhysicsRayQueryParameters3D.create(global_position, target, 1)
			var seen := {}
			for i in 4:  # see through up to four layers of buildings
				var result := space.intersect_ray(query)
				if result.is_empty():
					break
				if result.collider.is_in_group("occluder"):
					seen[result.collider] = true
				query.exclude = query.exclude + [result.rid]
			for node in seen:
				blocked[node] = blocked.get(node, 0) + 1
	var hit := {}
	for node in blocked:
		if blocked[node] == HEIGHTS.size() * SIDES.size():
			hit[node] = true
	for node in hit:
		if not _faded.has(node):
			node.set_faded(true)
	for node in _faded:
		if not hit.has(node) and is_instance_valid(node):
			node.set_faded(false)
	_faded = hit
