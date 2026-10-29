class_name Exit
extends Area3D
## A way out of the map: when the hero walks in, the target scene loads and the hero appears at
## `arrival` there.

## where the hero appears in the next scene (read once by the hero when it loads)
static var pending_arrival := Vector3.INF

@export_file("*.tscn") var target_scene := ""
@export var arrival := Vector3.ZERO


func _ready() -> void:
	body_entered.connect(func(body: Node3D) -> void:
		if body.is_in_group("player"):
			Exit.pending_arrival = arrival
			body.set_physics_process(false)
			_fade_to_scene())


## Fades to black, loads the target scene and fades back in. The veil lives on the root, so it
## survives the scene change; its tween runs the whole sequence.
func _fade_to_scene() -> void:
	var tree := get_tree()
	var layer := CanvasLayer.new()
	layer.layer = 100
	var veil := ColorRect.new()
	veil.color = Color.BLACK
	veil.modulate.a = 0.0
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(veil)
	tree.root.add_child(layer)
	var tween := veil.create_tween()
	tween.tween_property(veil, "modulate:a", 1.0, 0.3)
	tween.tween_callback(func() -> void: tree.change_scene_to_file(target_scene))
	tween.tween_interval(0.2)  # the new scene's first, heavy frames pass under the black
	tween.tween_property(veil, "modulate:a", 0.0, 0.3)
	tween.tween_callback(layer.queue_free)
