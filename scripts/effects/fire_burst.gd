extends Hitbox
## Estallido: a ring of fire around the caster. Hurts everything inside for a moment, then the
## explosion sprite finishes on its own.


func _ready() -> void:
	super()
	set_active(true)
	get_tree().create_timer(0.12).timeout.connect(set_active.bind(false))
	$Sprite.animation_finished.connect(queue_free)
	$Sprite.play()
