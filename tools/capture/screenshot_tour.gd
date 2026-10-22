extends SceneTree
## Dev tool: renders the outskirts and the town from a few spots into docs/screenshots and records a fight
## (frames in user://combat_frames; tools/capture/make_gif.py turns them into the README's GIF).
## Needs a display; on a server use:
##   xvfb-run godot --path . --script res://tools/capture/screenshot_tour.gd -- [shot names | combat]

const LEVEL := "res://scenes/levels/demo_zone.tscn"
const TOWN := "res://scenes/levels/brumaclara.tscn"
const OUT := "res://docs/screenshots/"
const SCALE := 2  # 960x540 -> 1920x1080

var _player: CharacterBody3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var only := OS.get_cmdline_user_args()
	var shots := [  # [file, level, hero position, facing]
		["01_afueras", LEVEL, Vector3(-3.0, 0, -4.5), Vector2.RIGHT],
		["02_aldea", LEVEL, Vector3(-7.0, 1.8, -17.8), Vector2.DOWN],
		["03_guarida", LEVEL, Vector3(6.5, 0, -1.5), Vector2.UP],
		["05_plaza", TOWN, Vector3(0, 0, 8.0), Vector2.UP],
		["06_sede_del_faro", TOWN, Vector3(0, 2.4, -15.0), Vector2.UP],
		["07_calle_del_mercado", TOWN, Vector3(29.0, 0, 1.0), Vector2.UP],
		["08_barrio_oeste", TOWN, Vector3(-27.0, 0, 2.0), Vector2.UP],
		["09_establos", TOWN, Vector3(-4.0, 0, 26.0), Vector2.UP],
	]
	var level: Node = null
	for shot in shots:
		if not (only.is_empty() or shot[0] in only):
			continue
		if level == null or level.scene_file_path != shot[1]:
			if level:
				level.free()
			level = load(shot[1]).instantiate()
			root.add_child(level)
			_player = level.get_node("Player")
		await _shot(shot[0], shot[2], shot[3])
	if only.is_empty() or "combat" in only:
		if level == null or level.scene_file_path != LEVEL:
			if level:
				level.free()
			level = load(LEVEL).instantiate()
			root.add_child(level)
			_player = level.get_node("Player")
		await _combat()
	quit()


func _settle(frames: int) -> void:
	for i in frames:
		await physics_frame
	await RenderingServer.frame_post_draw


func _save(file_name: String) -> void:
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + file_name + ".png")
	print("saved ", file_name)


func _shot(file_name: String, pos: Vector3, facing: Vector2) -> void:
	_player.global_position = pos
	_player.set("_facing", facing)
	await _settle(10)
	_save(file_name)


## A short fight against the two wolves, played by a simple pilot: it dodges each pounce as it
## starts, strikes when a wolf is in reach, lines up to fire Chispa from a distance and uses
## Estallido when both wolves are close. Recording stops a moment after the last wolf falls.
func _combat() -> void:
	DirAccess.make_dir_recursive_absolute("user://combat_frames")
	_player.global_position = Vector3(-1.5, 0, -1.6)
	_player.set("_facing", Vector2.RIGHT)
	await _settle(4)
	var wolves := _player.get_parent().get_node("Enemies").get_children()
	var frame := 0
	var after := 0
	for step in 720:
		var alive := wolves.filter(func(w: Node) -> bool: return w.get("_state") != 6)  # 6: DEAD
		_pilot(alive)
		await physics_frame
		if Engine.get_physics_frames() % 2 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://combat_frames/%03d.png" % frame)
			frame += 1
		after = after + 1 if alive.is_empty() else 0
		if after > 80:  # long enough for the experience orbs to reach the hero
			break
	_pilot([])
	print("combat frames: ", frame, " in ", ProjectSettings.globalize_path("user://combat_frames"))


func _pilot(wolves: Array) -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "attack", "dodge", "skill_1", "skill_2"]:
		Input.action_release(action)
	if wolves.is_empty():
		return
	var hero := _player.global_position
	wolves.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return hero.distance_to(a.global_position) < hero.distance_to(b.global_position))
	for wolf: Node3D in wolves:  # a pounce is about to start: dodge across its path
		var from: Vector3 = hero - wolf.global_position
		if wolf.get("_state") == 2 and wolf.get("_timer") < 0.12 and from.length() < 4.5:
			_hold(Vector2(-from.z, from.x))
			Input.action_press("dodge")
			return
	var to: Vector3 = wolves[0].global_position - hero
	var flat := Vector2(to.x, to.z)
	if wolves.size() > 1 and hero.distance_to(wolves[1].global_position) < 2.6 and _player.mp >= 25.0 \
			and _player.cooldown_left(&"burst") == 0.0:
		Input.action_press("skill_2")
	elif flat.length() < 1.4:
		_hold(_axis(flat))
		Input.action_press("attack")
	elif flat.length() > 2.0 and flat.length() < 7.0 and _player.mp >= 8.0 and _player.cooldown_left(&"bolt") == 0.0:
		if absf(flat.y) < 0.6:
			_hold(Vector2(signf(flat.x), 0))
			Input.action_press("skill_1")
		else:  # step up or down onto the wolf's line
			_hold(Vector2(0, signf(flat.y)))
	else:
		_hold(flat)


## presses the movement keys toward `dir` (any length)
func _hold(dir: Vector2) -> void:
	dir = dir.normalized()
	Input.action_press("move_right" if dir.x > 0.0 else "move_left", absf(dir.x))
	Input.action_press("move_down" if dir.y > 0.0 else "move_up", absf(dir.y))


func _axis(dir: Vector2) -> Vector2:
	return Vector2(signf(dir.x), 0) if absf(dir.x) > absf(dir.y) else Vector2(0, signf(dir.y))
