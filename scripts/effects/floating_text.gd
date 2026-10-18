extends Label3D
## A damage number or short word that pops above a character, rises and fades.


func _ready() -> void:
	var rise := create_tween().set_parallel()
	rise.tween_property(self, "position:y", position.y + 0.9, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	rise.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.35)
	rise.tween_property(self, "outline_modulate:a", 0.0, 0.3).set_delay(0.35)
	rise.chain().tween_callback(queue_free)
