extends CanvasLayer
## Going through a door or a map exit: the hero walks into it and fades, the screen fades to black, the
## next scene loads and the screen fades back in while the hero appears (player.gd).

const SECONDS := 0.4

var busy := false
var _black := ColorRect.new()


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_black.color = Color(0, 0, 0, 0)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_black)


## Loads `scene` with the hero arriving at `arrival` (see Exit).
func go(scene: String, arrival: Vector3, hero: Node3D = null) -> void:
	if busy:
		return
	busy = true
	if hero and hero.has_method("walk_through_door"):
		hero.walk_through_door(SECONDS)
	await _fade(1.0)
	Exit.pending_arrival = arrival
	get_tree().change_scene_to_file(scene)
	await get_tree().scene_changed
	busy = false
	await _fade(0.0)


func _fade(alpha: float) -> void:
	await create_tween().tween_property(_black, "color:a", alpha, SECONDS).finished
