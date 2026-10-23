extends SceneTree
## Self-check for the hero controller in the greybox test room: every flight of stairs and every
## ramp under 50° must be climbable, steeper ramps must block. Exit code 0 = pass.
## Run: godot --headless --path . --script res://tests/test_climb.gd

const ROOM := "res://scenes/dev/test_room.tscn"
## [lane x, should reach the 1.8 landing]
const CASES := [[-9.0, true], [-6.0, true], [-3.0, true], [3.0, true], [6.0, true], [9.0, false]]


func _initialize() -> void:
	var failed := 0
	for c in CASES:
		var peak: float = await _climb(c[0])
		var ok: bool = (peak > 1.7) == c[1]
		print("%s lane x=%s peak=%.2f" % ["OK  " if ok else "FAIL", c[0], peak])
		failed += 0 if ok else 1
	print("RESULT %s" % ("PASS" if failed == 0 else "%d FAILED" % failed))
	quit(failed)


func _climb(x: float) -> float:
	var room: Node = load(ROOM).instantiate()
	root.add_child(room)
	var hero: CharacterBody3D = room.get_node("Player")
	await physics_frame
	hero.global_position = Vector3(x, 0.1, 5.0)
	var peak := 0.0
	Input.action_press("move_up")
	for i in 150:  # 2.5 s, enough to reach every landing
		await physics_frame
		peak = maxf(peak, hero.global_position.y)
	Input.action_release("move_up")
	room.free()
	return peak
