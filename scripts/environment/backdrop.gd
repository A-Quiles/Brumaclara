extends CanvasLayer
## Painted far-away scenery (sky, mountains, hills) drawn behind the 3D world; the level's
## Environment shows it with the Canvas background mode. Like real distant scenery it moves much
## less than the world: it slides sideways a little with the camera, and sinks a little as the
## camera heads north, so the mountains keep peeking over the forest.

## screen pixels the scenery moves per world unit the camera moves
@export var parallax := 4.0
## screen y of the scenery's top edge when the camera is at z = 0
@export var top_at_origin := 10.0

@onready var _scenery: Sprite2D = $Scenery


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera:
		_scenery.region_rect.position.x = roundf(camera.global_position.x * parallax)
		_scenery.position.y = roundf(top_at_origin - camera.global_position.z * parallax)
