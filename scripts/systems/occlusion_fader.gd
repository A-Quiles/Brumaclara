extends Camera3D
## Fades the buildings that hide the hero completely: rays run from the camera to nine points of the
## hero's body (feet, waist and head, each at the left edge, centre and right edge as seen from the
## camera), and an "occluder" turns see-through only while it stands in front of all of them. One that
## covers just part of the hero stays opaque (the hero's silhouette shows the hidden part).

const HEIGHTS := [0.15, 1.0, 1.9]
const HALF_WIDTH := 0.35

var _faded := {}  # occluder -> true


func _physics_process(_delta: float) -> void:
	var hero := get_parent() as Node3D
	if hero == null:
		return
	var space := get_world_3d().direct_space_state
	var side := global_basis.x * HALF_WIDTH  # the camera's right, so the points span the hero on screen
	var covering := {}  # occluder -> how many of the rays it blocks
	var rays := 0
	for height: float in HEIGHTS:
		for k: float in [-1.0, 0.0, 1.0]:
			rays += 1
			var target := hero.global_position + Vector3(0, height, 0) + side * k
			var query := PhysicsRayQueryParameters3D.create(global_position, target, 1)
			var seen := {}
			for i in 4:  # see through up to four layers of buildings
				var result := space.intersect_ray(query)
				if result.is_empty():
					break
				if result.collider.is_in_group("occluder") and not seen.has(result.collider):
					seen[result.collider] = true
					covering[result.collider] = covering.get(result.collider, 0) + 1
				query.exclude = query.exclude + [result.rid]
	var hit := {}
	for node in covering:
		if covering[node] == rays:
			hit[node] = true
	for node in hit:
		if not _faded.has(node):
			node.set_faded(true)
	for node in _faded:
		if not hit.has(node) and is_instance_valid(node):
			node.set_faded(false)
	_faded = hit
