extends SceneTree
## Dev tool: plays a short tour of the game by itself, to be recorded with Godot's movie maker:
##   xvfb-run godot --path . --write-movie /tmp/tour.avi --fixed-fps 30 --script res://tools/capture/gameplay_video.gd
## (tools/capture/make_video.sh turns it into docs/video/*.mp4 and the README's GIF). Shots: the town,
## into the inn, the Faro's hall with Iven, the skill tree, and a fight in the outskirts with skills.

const TOWN := "res://scenes/levels/brumaclara.tscn"
const OUTSKIRTS := "res://scenes/levels/afueras.tscn"

var _progress: Node
var _hero: CharacterBody3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_progress = root.get_node("Progress")
	_progress.save_enabled = false
	_progress.new_game()
	_progress.gain_xp(5200)  # a hero with a few levels and points to spend
	_progress.choose_principal(&"fuego")
	for id in [&"fuego.lanza_de_fuego", &"fuego.abanico_de_brasas", &"fuego.latigo_igneo", &"fuego.brasero",
			&"fuego.carga_ignea", &"fuego.erupcion", &"fuego.chispa_doble", &"fuego.cometa"]:
		if _progress.can_learn(id) == "":
			_progress.learn(id)
	for slot_id in [[0, &"fuego.chispa"], [1, &"fuego.estallido"], [2, &"fuego.erupcion"], [3, &"fuego.carga_ignea"]]:
		if slot_id[1] in _progress.learned:
			_progress.equip(slot_id[0], slot_id[1])

	# 1. the town: up the main street toward the plaza
	await _load(TOWN, Vector3(-1, 0.3, 24))
	await _walk(Vector2.UP, 260)
	await _walk(Vector2(-0.6, -1), 90)
	# 2. into the inn: walk up to its door, look around inside
	await _load(TOWN, Vector3(-3.0, 0.3, -8.3))
	await _walk_to(Vector3(-9.5, 0, -8.3), 200)
	await _walk(Vector2.UP, 160, true)  # the door changes the scene
	await _wait(40)
	_hero = current_scene.get_node("Player")
	await _walk_to(Vector3(-2.6, 0, 8.0), 120)  # Lio, the guide, by the tables
	await _face_and_talk("People/Lio", 1)
	await _walk_to(Vector3(2.5, 0, 6.5), 120)
	await _walk(Vector2.RIGHT, 60)
	# 3. the Faro's hall: Iven by the contract board
	await _load("res://scenes/levels/interiors/sede_faro.tscn", Vector3(0, 0.1, 8.0))
	await _walk(Vector2(-0.5, -1), 100)
	await _face_and_talk("People/Iven", 2)
	# 4. the skill tree
	_press_once("open_tree")
	await _wait(90)
	_press_once("move_right")
	await _wait(70)
	_press_once("move_right")
	await _wait(70)
	_press_once("open_tree")
	await _wait(10)
	# 5. a fight in the outskirts: sword, skills, a dodge
	await _load(OUTSKIRTS, Vector3(-3, 0.3, -6))
	await _wait(30)
	for round in 3:
		await _fight_round(round)
	# 6. the forest edge: spore volleys and the root guardian's slam
	await _load(OUTSKIRTS, Vector3(-11, 0.3, -9))
	await _wait(40)
	for round in 2:
		await _fight_round(round)
	await _wait(60)
	quit()


# --- helpers ----------------------------------------------------------------------------------------

func _load(scene: String, at: Vector3) -> void:
	change_scene_to_file(scene)
	await _wait(3)
	_hero = current_scene.get_node("Player")
	_hero.global_position = at
	if current_scene.has_node("LevelEdits"):
		current_scene.get_node("LevelEdits").set("dirty", false)
	await _wait(12)


func _wait(frames: int) -> void:  # physics frames: two per recorded frame at --fixed-fps 30
	for i in frames:
		await physics_frame


func _walk(dir: Vector2, frames: int, until_scene_change := false) -> void:
	var start := current_scene
	var keys := []
	if dir.x > 0.3:
		keys.append("move_right")
	elif dir.x < -0.3:
		keys.append("move_left")
	if dir.y > 0.3:
		keys.append("move_down")
	elif dir.y < -0.3:
		keys.append("move_up")
	for k in keys:
		Input.action_press(k)
	for i in frames:
		await physics_frame
		if until_scene_change and current_scene != start:
			break
	for k in keys:
		Input.action_release(k)
	if until_scene_change:
		await _wait(6)


func _walk_to(target: Vector3, frames: int) -> void:
	for i in frames:
		var d := Vector3(target.x - _hero.global_position.x, 0, target.z - _hero.global_position.z)
		for k in ["move_right", "move_left", "move_up", "move_down"]:
			Input.action_release(k)
		if d.length() < 0.25:
			break
		var s := View.to_screen(d)
		if s.x > 0.15: Input.action_press("move_right")
		elif s.x < -0.15: Input.action_press("move_left")
		if s.y > 0.15: Input.action_press("move_down")
		elif s.y < -0.15: Input.action_press("move_up")
		await physics_frame
	for k in ["move_right", "move_left", "move_up", "move_down"]:
		Input.action_release(k)


func _press_once(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func _face_and_talk(path: String, times: int) -> void:
	var who := current_scene.get_node_or_null(path) as Node3D
	if who == null:
		return
	for t in times:
		_press_once("interact")
		await _wait(75)


func _nearest_enemy() -> Node3D:
	var best: Node3D = null
	for e in current_scene.get_tree().get_nodes_in_group("enemies"):
		if e.has_method("is_alive") and e.is_alive():
			if best == null or e.global_position.distance_to(_hero.global_position) < best.global_position.distance_to(_hero.global_position):
				best = e
	return best


func _aim() -> void:
	var e := _nearest_enemy()
	if e:
		var d := Vector3(e.global_position.x - _hero.global_position.x, 0, e.global_position.z - _hero.global_position.z)
		_hero.set("_facing", View.to_screen(d).normalized())


func _approach(frames: int) -> void:
	for i in frames:
		var e := _nearest_enemy()
		if e == null:
			return
		var d := Vector3(e.global_position.x - _hero.global_position.x, 0, e.global_position.z - _hero.global_position.z)
		if d.length() < 2.6:
			break
		var s := View.to_screen(d).normalized()
		for k in ["move_right", "move_left", "move_up", "move_down"]:
			Input.action_release(k)
		if s.x > 0.35: Input.action_press("move_right")
		elif s.x < -0.35: Input.action_press("move_left")
		if s.y > 0.35: Input.action_press("move_down")
		elif s.y < -0.35: Input.action_press("move_up")
		await physics_frame
	for k in ["move_right", "move_left", "move_up", "move_down"]:
		Input.action_release(k)


func _fight_round(round: int) -> void:
	await _approach(120)
	_aim()
	for i in 3:  # a sword combo
		_press_once("attack")
		await _wait(9)
	await _wait(10)
	_aim()
	_press_once("skill_1")  # Chispa
	await _wait(18)
	_aim()
	_press_once("skill_2")  # Estallido
	await _wait(30)
	_press_once("dodge")
	await _wait(20)
	_aim()
	_press_once("skill_3")  # Erupción
	await _wait(35)
	if round == 1:
		_aim()
		_press_once("skill_4")  # Carga ígnea
		await _wait(25)
	if round == 2 and _progress.ultimate != &"":
		_press_once("ultimate")
		await _wait(40)
	await _wait(25)
