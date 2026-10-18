extends Area3D
## Experience left by a defeated enemy: bobs in place, drifts to the hero when close and is
## absorbed on touch.

@export var amount := 25

@onready var _sprite: AnimatedSprite3D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_sprite.play()


func _physics_process(delta: float) -> void:
	_sprite.position.y = 0.35 + sin(Time.get_ticks_msec() * 0.006) * 0.08
	var hero := get_tree().get_first_node_in_group("player") as Node3D
	if hero and global_position.distance_to(hero.global_position) < 3.0:
		global_position = global_position.move_toward(hero.global_position, 8.0 * delta)


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("gain_xp"):
		body.gain_xp(amount)
		queue_free()
