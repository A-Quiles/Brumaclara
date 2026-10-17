@tool
extends StaticBody3D
## A villager standing still with a two-frame idle bob.
## `sheet` holds two 18x24 frames side by side (see tools/art_generator/village_sprites.py).

const FRAME := Vector2i(18, 24)

@export var sheet: Texture2D:
	set(value):
		sheet = value
		_apply()
@export var height := 1.6:  ## world units from the feet to the top of the head
	set(value):
		height = value
		_apply()
@export_range(0.0, 1.0) var phase := 0.0  ## offsets the bob so villagers don't breathe in sync


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_inside_tree() or sheet == null:
		return
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 1.6)
	for i in 2:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2(i * FRAME.x, 0), FRAME)
		frames.add_frame("default", atlas)
	var sprite: AnimatedSprite3D = $Sprite
	sprite.sprite_frames = frames
	sprite.pixel_size = height / FRAME.y
	sprite.play("default")
	sprite.frame_progress = phase
