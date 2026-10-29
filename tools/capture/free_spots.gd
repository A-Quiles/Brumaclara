extends SceneTree
## Dev tool: for each wanted spot, the nearest place where a cylinder of the given radius fits on the
## ground without touching anything (props, buildings, people). Prints "name x y z".
##   godot --headless --path . --script res://tools/capture/free_spots.gd -- <scene> name:x:z:radius ...

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	root.get_node("Progress").save_enabled = false
	change_scene_to_file(args[0])
	for i in 600:
		if current_scene and current_scene.scene_file_path == args[0]:
			break
		await process_frame
	for i in 4:
		await physics_frame
	var space := (current_scene as Node3D).get_world_3d().direct_space_state
	for spec in args.slice(1):
		var p := (spec as String).split(":")
		var want := Vector3(float(p[1]), 0, float(p[2]))
		var r := float(p[3])
		var best := Vector3.INF
		for ring in 40:
			var d := ring * 0.5
			for k in maxi(1, ring * 6):
				var a := TAU * k / maxi(1, ring * 6)
				var at := want + Vector3(cos(a) * d, 0, sin(a) * d)
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3(0, 40, 0), at - Vector3(0, 40, 0), 1))
				if hit.is_empty() or hit.normal.y < 0.95 or not (hit.collider.name in ["Ground", "Meadow"]):
					continue
				var shape := CylinderShape3D.new()
				shape.radius = r
				shape.height = 1.4
				var q := PhysicsShapeQueryParameters3D.new()
				q.shape = shape
				q.collision_mask = 1 | 2 | 4
				q.transform = Transform3D(Basis(), hit.position + Vector3(0, 0.8, 0))
				if space.intersect_shape(q, 1).is_empty():
					best = hit.position
					break
			if best != Vector3.INF:
				break
		print("%s %.1f %.2f %.1f" % [p[0], best.x, best.y, best.z])
	quit()
