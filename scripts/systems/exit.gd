class_name Exit
extends Area3D
## A way out of the map (or a door): when the hero walks in, the target scene loads behind a fade
## (Transition) and the hero appears at `arrival` there. A door (`push` set) only takes the hero while
## it walks into it, so passing in front of one does nothing.

## where the hero appears in the next scene (read once by the hero when it loads)
static var pending_arrival := Vector3.INF

@export_file("*.tscn") var target_scene := ""
@export var arrival := Vector3.ZERO
## a door: the way the hero must walk to go through, in the door's own axes (into the building);
## zero for the edges of a map, which take the hero as soon as it steps in
@export var push := Vector3.ZERO


func _ready() -> void:
	set_physics_process(push != Vector3.ZERO)
	body_entered.connect(func(body: Node3D) -> void:
		if push == Vector3.ZERO and body.is_in_group("player"):
			Transition.go(target_scene, arrival, body))


func _physics_process(_delta: float) -> void:
	var into := (global_basis * push).normalized()
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and (body as CharacterBody3D).velocity.dot(into) > 1.5:
			Transition.go(target_scene, arrival, body)
