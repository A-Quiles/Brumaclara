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
			get_tree().change_scene_to_file.call_deferred(target_scene))
