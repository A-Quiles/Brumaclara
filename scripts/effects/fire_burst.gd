extends Hitbox
## An area skill (Estallido and every other AREA skill): a ring of explosions around the caster.
## Hurts everything inside for a moment, then the explosion sprites finish on their own.


func _ready() -> void:
	super()
	set_active(true)
	get_tree().create_timer(0.12).timeout.connect(set_active.bind(false))
	for sprite in find_children("*", "AnimatedSprite3D", false):
		sprite.sprite_frames = Affinity.frames(sprite.sprite_frames, affinity)
		sprite.play()
	$Sprite.animation_finished.connect(queue_free)
