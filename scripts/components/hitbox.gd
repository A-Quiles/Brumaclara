class_name Hitbox
extends Area3D
## Strikes every Hurtbox it overlaps while active, each one once per activation. Collision masks
## decide who can be hit (the hero's attacks only see enemy hurtboxes and the other way round).

signal landed(target: Hurtbox)

@export var damage := 10
@export var push := 6.0  ## knockback speed given to the target, away from the hitbox

var _struck: Array[Area3D] = []
var _active := false  # takes effect at once; `monitoring` itself only changes after the frame


func _ready() -> void:
	set_active(false)


func set_active(active: bool) -> void:
	_active = active
	_struck.clear()
	set_deferred("monitoring", active)


func _physics_process(_delta: float) -> void:
	if not (_active and monitoring):
		return
	for area in get_overlapping_areas():
		if area is Hurtbox and area not in _struck:
			_struck.append(area)
			var away := area.global_position - global_position
			away.y = 0.0
			area.receive(damage, away.normalized() * push)
			landed.emit(area)
