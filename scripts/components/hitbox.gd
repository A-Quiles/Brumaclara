class_name Hitbox
extends Area3D
## Strikes every Hurtbox it overlaps while active, each one once per activation. Collision masks
## decide who can be hit (the hero's attacks only see enemy hurtboxes and the other way round).
## A hit carries what made it, so the one struck can apply affinities and statuses (StatusEffects).

signal landed(target: Hurtbox)

@export var damage := 10
@export var push := 6.0  ## knockback speed given to the target, away from the hitbox

var affinity: StringName  ## the hero's skills: fuego, hielo... ; &"espada" for the sword
var status: StringName  ## applied to what it hits
var stacks := 1
var status_seconds := 0.0
var skill: SkillData  ## the skill that made it, if any
var attacker: Node  ## whose attack it is
var from_hero := false
var origin := Vector3.INF  ## where a projectile started (for distance bonuses)
var once_group: Variant = null  ## a Dictionary shared by hitboxes that strike each target only once between them

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
			if once_group != null and once_group.has(area):
				continue
			if once_group != null:
				once_group[area] = true
			var away := area.global_position - global_position
			away.y = 0.0
			area.receive(damage, away.normalized() * push, self)
			landed.emit(area)
