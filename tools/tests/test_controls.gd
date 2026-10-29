extends SceneTree
## Headless checks of the hero's controls: running (Shift) is faster than walking, the sword swings
## while walking (the hero keeps moving), never while running, and the inventory (Tab) opens, uses a
## potion and closes. Run: godot --headless --path . --script res://tools/tests/test_controls.gd

var _failures := 0
var _hero: CharacterBody3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var progress: Node = root.get_node("Progress")
	progress.save_enabled = false
	progress.new_game()
	change_scene_to_file("res://scenes/levels/afueras.tscn")
	for i in 600:
		if current_scene and current_scene.scene_file_path.ends_with("afueras.tscn"):
			break
		await process_frame
	for e in current_scene.get_node("Enemies").get_children():
		e.queue_free()
	_hero = current_scene.get_node("Player")
	await _frames(3)

	# walking and running
	var walked := await _distance(["move_right"], 30)
	var ran := await _distance(["move_right", "run"], 30)
	_check(ran > walked * 1.4, "running goes further than walking (%.2f vs %.2f)" % [ran, walked])

	# the sword while walking: the swing starts and the hero keeps moving
	Input.action_press("move_left")
	await _frames(10)
	var start := _hero.global_position
	await _tap("attack")
	await _frames(1)
	_check(int(_hero.get("_state")) == 1, "the sword swings while walking")
	await _frames(12)
	_check(_hero.global_position.distance_to(start) > 0.6, "the hero keeps walking during the swing")
	Input.action_release("move_left")
	await _tap("attack")
	Input.action_press("move_right")  # turning round in the middle of a swing
	await _frames(4)
	var spr: AnimatedSprite3D = _hero.get_node("Sprite")
	_check(int(_hero.get("_state")) != 1 or (spr.animation == &"attack_side" and not spr.flip_h),
			"a swing turns to face the way the hero walks (%s, flip %s)" % [spr.animation, spr.flip_h])
	Input.action_release("move_right")
	await _frames(30)

	# no sword while running
	Input.action_press("move_left")
	Input.action_press("run")
	await _frames(10)
	await _tap("attack")
	await _frames(1)
	_check(int(_hero.get("_state")) == 0, "no sword while running")
	Input.action_release("run")
	Input.action_release("move_left")
	await _frames(5)

	# the inventory: Tab opens it, a potion heals, Tab closes it
	var health: Node = _hero.get_node("Health")
	health.current = 10
	var potions: int = progress.count(&"pocion")
	_check(potions == 3, "a new game starts with 3 potions")
	await _tap_event("inventory")
	var screen: Node = current_scene.get_node("HUD").get("_inventory")
	_check(screen != null and paused, "Tab opens the inventory and the game waits")
	if screen:
		_check(screen.use_selected(), "the first item (a potion) can be used")
		_check(health.current == 50 and progress.count(&"pocion") == potions - 1, "the potion heals 40 and is used up (hp %d)" % health.current)
	await _tap_event("inventory")
	await _frames(2)
	_check(current_scene.get_node("HUD").get("_inventory") == null and not paused, "Tab closes it again")

	print("controls checks: %s" % ("all passed" if _failures == 0 else "%d FAILED" % _failures))
	quit(1 if _failures else 0)


func _distance(actions: Array, frames: int) -> float:
	var from := _hero.global_position
	for a in actions:
		Input.action_press(a)
	await _frames(frames)
	for a in actions:
		Input.action_release(a)
	var d := Vector2(_hero.global_position.x - from.x, _hero.global_position.z - from.z).length()
	await _frames(20)
	return d


func _tap(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)


func _tap_event(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventAction.new()
	up.action = action
	Input.parse_input_event(up)
	await process_frame


func _frames(count: int) -> void:
	for i in count:
		await physics_frame


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failures += 1
