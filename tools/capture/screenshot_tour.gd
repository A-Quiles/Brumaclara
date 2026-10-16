extends SceneTree
## Dev tool: renders the demo level from a few camera spots and saves PNGs in docs/screenshots.
## Also dumps walk-cycle frames to user://walk_frames (assembled into a GIF outside Godot).
## Needs a display; on a server use: xvfb-run godot --path . --script res://tools/capture/screenshot_tour.gd

const LEVEL := "res://scenes/levels/demo_cottage.tscn"
const OUT := "res://docs/screenshots/"

var _player: CharacterBody2D
var _camera: Camera2D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level: Node = load(LEVEL).instantiate()
	root.add_child(level)
	_player = level.get_node("World/Player")
	_camera = _player.get_node("Camera")

	await _shot("01_casa_y_jardin", Vector2(304, 286), Vector2.DOWN, 1.0, 3, Vector2(330, 196))
	await _shot("02_detalle_casa", Vector2(300, 246), Vector2.UP, 2.0, 3, Vector2(304, 190))
	await _shot("03_detras_del_arbol", Vector2(194, 228), Vector2.LEFT, 2.0, 3, Vector2(190, 236))
	await _shot("04_huerto_y_estanque", Vector2(464, 376), Vector2.UP, 2.0, 3, Vector2(400, 316))
	await _overview()
	await _walk_frames()
	quit()


func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame
	await RenderingServer.frame_post_draw


func _save(file_name: String, scale: int) -> void:
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * scale, image.get_height() * scale, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + file_name + ".png")
	print("saved ", file_name)


func _shot(file_name: String, player_pos: Vector2, facing: Vector2, zoom: float, scale: int, focus := Vector2.INF) -> void:
	_player.position = player_pos
	_player.set("_facing", facing)
	_camera.zoom = Vector2(zoom, zoom)
	_camera.top_level = focus != Vector2.INF
	if _camera.top_level:
		_camera.global_position = focus
	else:
		_camera.position = Vector2.ZERO
	await _wait_frames(4)
	_save(file_name, scale)


func _overview() -> void:
	var previous := root.content_scale_size
	root.content_scale_size = Vector2i(704, 416)  # the whole level at 1:1 pixels
	await _shot("05_vista_completa", Vector2(304, 286), Vector2.DOWN, 1.0, 2, Vector2(352, 208))
	root.content_scale_size = previous


func _walk_frames() -> void:
	DirAccess.make_dir_recursive_absolute("user://walk_frames")
	_player.position = Vector2(304, 380)
	_camera.top_level = false
	_camera.position = Vector2.ZERO
	_camera.zoom = Vector2(2, 2)
	var route := [["move_up", 70], ["move_left", 55], ["move_down", 30], ["move_right", 50], ["move_up", 20]]
	var frame := 0
	for step in route:
		Input.action_press(step[0])
		for i in step[1]:
			await physics_frame
			if i % 2 == 0:
				await RenderingServer.frame_post_draw
				var image := root.get_texture().get_image()
				image.save_png("user://walk_frames/%03d.png" % frame)
				frame += 1
		Input.action_release(step[0])
	print("walk frames: ", ProjectSettings.globalize_path("user://walk_frames"))
