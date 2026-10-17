extends SceneTree
## Dev tool: renders the village from a few spots and saves PNGs in docs/screenshots.
## Also dumps walk-cycle frames to user://walk_frames (assembled into a GIF outside Godot).
## Needs a display; on a server use: xvfb-run godot --path . --script res://tools/capture/screenshot_tour.gd

const LEVEL := "res://scenes/levels/village.tscn"
const OUT := "res://docs/screenshots/"
const SCALE := 4  # 480x270 -> 1920x1080

var _player: CharacterBody3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level: Node = load(LEVEL).instantiate()
	root.add_child(level)
	_player = level.get_node("Player")
	var only := OS.get_cmdline_user_args()
	var shots := [
		["01_plaza", Vector3(0, 0, 0), Vector2.DOWN],
		["02_fuente_y_puestos", Vector3(2.5, 0, -3.5), Vector2.UP],
		["03_casas_del_fondo", Vector3(-1.5, 0, -8.0), Vector2.UP],
		["04_escaleras_derecha", Vector3(8.4, 2.2, -10.6), Vector2.LEFT],
		["05_jardin_y_torre", Vector3(-4.0, 0, 5.0), Vector2.DOWN],
	]
	for shot in shots:
		if only.is_empty() or shot[0] in only:
			await _shot(shot[0], shot[1], shot[2])
	if only.is_empty() or "walk" in only:
		await _walk_frames()
	quit()


func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame
	await RenderingServer.frame_post_draw


func _shot(file_name: String, pos: Vector3, facing: Vector2) -> void:
	_player.global_position = pos
	_player.set("_facing", facing)
	await _wait_frames(8)
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + file_name + ".png")
	print("saved ", file_name)


func _walk_frames() -> void:
	DirAccess.make_dir_recursive_absolute("user://walk_frames")
	_player.global_position = Vector3(0, 0, 3)
	var route := [["move_up", 80], ["move_left", 40], ["move_right", 70], ["move_down", 30]]
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
