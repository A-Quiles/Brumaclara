extends AnimatedSprite3D
## A sprite animation that plays once where it was spawned and then removes itself.


func _ready() -> void:
	animation_finished.connect(queue_free)
	play()
