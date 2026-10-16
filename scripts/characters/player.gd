extends CharacterBody3D
## Moves on the ground plane: free 8-way motion, 4-direction billboard sprite (right = mirrored left).

const SPEED := 5.0  # world units per second (1 unit = 16 texels)

var _facing := Vector2.DOWN

@onready var _sprite: AnimatedSprite3D = $Sprite


func _physics_process(_delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = Vector3(input.x, 0.0, input.y) * SPEED
	move_and_slide()
	if input != Vector2.ZERO:
		_facing = input
	_update_animation(input != Vector2.ZERO)


func _update_animation(moving: bool) -> void:
	var direction := "side" if absf(_facing.x) > absf(_facing.y) else ("up" if _facing.y < 0.0 else "down")
	_sprite.flip_h = direction == "side" and _facing.x > 0.0
	_sprite.play(("walk_" if moving else "idle_") + direction)
