extends Hitbox
## Chispa: a small fire bolt that flies straight and bursts on the first enemy, tree or wall it meets.

@export var speed := 14.0
@export var lifetime := 0.9
@export var impact: PackedScene  ## effect left where it bursts

var direction := Vector3.FORWARD


func _ready() -> void:
	super()
	set_active(true)
	landed.connect(_burst.unbind(1))
	body_entered.connect(_burst.unbind(1))
	get_tree().create_timer(lifetime).timeout.connect(_burst)
	$Sprite.flip_h = direction.x < 0.0
	$Sprite.play()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	super(delta)


func _burst() -> void:
	if is_queued_for_deletion():
		return
	if impact:
		var fx: Node3D = impact.instantiate()
		get_parent().add_child(fx)
		fx.global_position = global_position + Vector3(0, -0.3, 0.05)
	queue_free()
