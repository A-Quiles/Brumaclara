extends CharacterBody3D
## Walks on the ground with gravity (so stairs and ramps work): free 8-way motion,
## 4-direction billboard sprite (right = mirrored left).

const SPEED := 5.0  # world units per second
const GRAVITY := 30.0

var _facing := Vector2.DOWN

@onready var _sprite: AnimatedSprite3D = $Sprite


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity.x = input.x * SPEED
	velocity.z = input.y * SPEED
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	if input != Vector2.ZERO:
		_facing = input
	_update_animation(input != Vector2.ZERO)


func _update_animation(moving: bool) -> void:
	var direction := "side" if absf(_facing.x) > absf(_facing.y) else ("up" if _facing.y < 0.0 else "down")
	_sprite.flip_h = direction == "side" and _facing.x > 0.0
	_sprite.play(("walk_" if moving else "idle_") + direction)
