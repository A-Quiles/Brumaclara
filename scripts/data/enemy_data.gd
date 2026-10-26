class_name EnemyData
extends Resource
## Numbers of one kind of enemy (docs/diseno_combate.md): the enemy's script reads them, so balancing
## is editing a file in data/enemies.

@export var display_name := ""
@export var max_hp := 40
@export var damage := 14  ## of its attack
@export var push := 8.0  ## knockback of its attack
@export var speed := 4.0  ## chasing
@export var attack_speed := 12.5  ## lunging
@export var detect_radius := 7.5
@export var give_up_radius := 13.0
@export var attack_range := 3.6
@export var windup_seconds := 0.6  ## the warning before the attack
@export var xp_reward := 30
@export var respawn_seconds := 12.0
