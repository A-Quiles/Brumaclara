class_name Exit
extends Area3D
## A way out of the map (or a door): when the hero walks in, the target scene loads behind a fade
## (Transition) and the hero appears at `arrival` there.

## where the hero appears in the next scene (read once by the hero when it loads)
static var pending_arrival := Vector3.INF

@export_file("*.tscn") var target_scene := ""
@export var arrival := Vector3.ZERO


func _ready() -> void:
	body_entered.connect(func(body: Node3D) -> void:
		if body.is_in_group("player"):
			Transition.go(target_scene, arrival, body))
