extends SceneTree
## Dev tool: renders the demo level from a few spots and saves PNGs in docs/screenshots.
## Also dumps walk-cycle frames to user://walk_frames (assembled into a GIF outside Godot).
## Needs a display; on a server use: xvfb-run godot --path . --script res://tools/capture/screenshot_tour.gd

const LEVEL := "res://scenes/levels/demo_cottage.tscn"
const OUT := "res://docs/screenshots/"
const SCALE := 3

var _player: CharacterBody3D
var _camera: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level: Node = load(LEVEL).instantiate()
	root.add_child(level)
	_player = level.get_node("World/Player")
	_camera = _player.get_node("Camera")
	var default_camera := _camera.position

	await _shot("01_casa_y_jardin", Vector3(19, 0, 17.5), Vector2.DOWN)
	_camera.position = default_camera * 0.6
	await _shot("02_detalle_casa", Vector3(19, 0, 15.2), Vector2.UP)
	await _shot("03_escaleras_y_terraza", Vector3(27.5, 0, 9), Vector2.RIGHT)
	await _shot("04_huerto_y_estanque", Vector3(29, 0, 23.5), Vector2.UP)
	_camera.position = default_camera * 1.6
	await _shot("05_vista_completa", Vector3(22, 0, 16), Vector2.DOWN)
	_camera.position = default_camera
	await _walk_frames()
	quit()


func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame
	await RenderingServer.frame_post_draw


func _shot(file_name: String, player_pos: Vector3, facing: Vector2) -> void:
	_player.position = player_pos
	_player.set("_facing", facing)
	await _wait_frames(4)
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + file_name + ".png")
	print("saved ", file_name)


func _walk_frames() -> void:
	DirAccess.make_dir_recursive_absolute("user://walk_frames")
	_player.position = Vector3(19, 0, 24)
	var route := [["move_up", 70], ["move_left", 55], ["move_down", 30], ["move_right", 50], ["move_up", 20]]
	var frame := 0
	for step in route:
		Input.action_press(step[0])
		for i in step[1]:
			await physics_frame
			if i % 2 == 0:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("user://walk_frames/%03d.png" % frame)
				frame += 1
		Input.action_release(step[0])
	print("walk frames: ", ProjectSettings.globalize_path("user://walk_frames"))
