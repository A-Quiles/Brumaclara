class_name EnemyData
extends Resource
## Numbers of one kind of enemy (docs/bestiario.md): the enemy's script reads them, so balancing
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
@export_group("Combate")
@export var weak: Array[StringName] = []  ## affinities (or &"espada") that hurt it x1.5
@export var resist: Array[StringName] = []  ## affinities that hurt it x0.5
@export_range(0.0, 0.6) var defense := 0.0
@export var boss := false  ## never frozen; immune to stuns for 6 s after each one
@export var anomalous := false  ## a creature of the Fractura (light hurts it more)
@export_group("Ataque")
@export_enum("pounce", "burst", "volley") var attack_kind := "pounce"  ## lunge, area slam or a fan of shots
@export var burst_radius := 2.2  ## of the slam (burst)
@export var volley := 3  ## shots in the fan (volley)
@export var shot_speed := 9.0
@export var shot_affinity: StringName = &"sombra"  ## colour of its shots and slams
@export_group("Aspecto")
@export var frames: SpriteFrames  ## its sprite sheet (empty: the one in the scene)
@export var sprite_offset := Vector2.ZERO  ## where its feet are in the frames (zero: the wolf's)
@export var sprite_scale := 1.0  ## size of the sprite, the body and the bite
@export var attack_count := 1  ## pounces in a row before it recovers
@export var summons := 0  ## cubs it calls when it drops under half health (bosses)
