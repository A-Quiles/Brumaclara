extends CanvasLayer
## On-screen HUD: HP/MP bars, a live top-down minimap with the player's marker and the message bar.

@export var player_path: NodePath
@export var map_center := Vector2(0.0, -7.0)  ## world (x, z) at the centre of the minimap
@export var map_height := 40.0  ## world units shown from top to bottom of the minimap

@onready var _player: Node3D = get_node_or_null(player_path)
@onready var _map: SubViewportContainer = %MapContainer
@onready var _view: SubViewport = %MapViewport
@onready var _camera: Camera3D = %MapCamera
@onready var _marker: TextureRect = %PlayerMarker


func _ready() -> void:
	_camera.size = map_height
	_camera.position = Vector3(map_center.x, 60.0, map_center.y)


func _process(_delta: float) -> void:
	if _player == null:
		return
	var px_per_unit := _view.size.y / map_height
	var offset := Vector2(_player.global_position.x, _player.global_position.z) - map_center
	var centre := Vector2(_view.size) / 2.0
	_marker.position = (_map.position + centre + offset * px_per_unit - _marker.size / 2.0).round()
	_marker.visible = Rect2(Vector2.ZERO, Vector2(_view.size)).has_point(centre + offset * px_per_unit)


func say(text: String) -> void:
	%Message.text = text
