extends Hitbox
## One explosion: the hit of strikes, lines, chains, rains, embers and explosions. Active for a moment
## (after an optional warning), then gone when its sprite finishes.

var delay := 0.0
var warning: Node3D  ## a mark on the ground shown during the delay


func _ready() -> void:
	super()
	var sprite: AnimatedSprite3D = $Sprite
	sprite.visible = false
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
	if is_instance_valid(warning):
		warning.queue_free()
	sprite.visible = true
	sprite.animation_finished.connect(queue_free)
	sprite.play()
	set_active(true)
	await get_tree().create_timer(0.12, false).timeout
	set_active(false)
