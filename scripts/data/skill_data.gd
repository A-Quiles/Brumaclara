class_name SkillData
extends Resource
## One of the hero's skills (docs/diseno_combate.md). Skills of the same kind share their code, so a new
## one of an existing kind is just a new file in data/skills with other numbers.

enum Kind { PROJECTILE, AREA }  ## flies from the hero's hand / bursts around the hero

@export var id: StringName  ## key of its cooldown (the HUD slots use it)
@export var display_name := ""
@export var kind := Kind.PROJECTILE
@export var scene: PackedScene  ## the effect, a Hitbox
@export var mana_cost := 8.0
@export var cooldown := 0.5  ## seconds
@export var cast_seconds := 0.3  ## the hero stands casting this long
@export var release_at := 0.1  ## seconds into the cast when the effect comes out
@export var damage := 10
@export var push := 5.0  ## knockback given to what it hits
