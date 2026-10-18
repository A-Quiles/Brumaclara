class_name GameFeel
## Small touches that make hits read: a freeze of a few frames on impact.


static func hitstop(seconds := 0.05) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	Engine.time_scale = 0.05
	await tree.create_timer(seconds, true, false, true).timeout  # real time, not scaled
	Engine.time_scale = 1.0
