extends Hitbox
## One explosion: the hit of strikes, lines, chains, rains, embers and explosions. Active for a moment
## (after an optional warning), then gone when its sprite finishes.

var delay := 0.0
var warning: Node3D  ## a mark on the ground shown during the delay
## A big blast is drawn as several explosions at the game's pixel size round the centre, never as one
## enlarged sprite (docs/plan_unificacion_artistica.md, 3.5): how many, and how far from the centre.
var extra := 0
var extra_radius := 0.0


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
	for i in extra:
		var piece := sprite.duplicate() as AnimatedSprite3D
		var angle := TAU * i / extra + randf_range(-0.3, 0.3)
		piece.position += Vector3(cos(angle), 0.0, sin(angle) * 0.7) * extra_radius
		piece.speed_scale = randf_range(0.85, 1.15)
		add_child(piece)
		piece.play()
	set_active(true)
	await get_tree().create_timer(0.12, false).timeout
	set_active(false)
