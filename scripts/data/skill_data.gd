class_name SkillData
extends Resource
## One of the hero's skills (docs/arbol_habilidades.md). The skill trees in data/trees/*.json hold the
## numbers; `from_dict` turns an entry into this resource and SkillCaster runs it by its kind. Skills
## of the same kind share their code, so a new skill of an existing kind is just data.

enum Kind {
	PROJECTILE,  ## flies from the hero's hand (count, spread, volleys, pierce, bounce, explosion)
	AREA,        ## bursts around the hero
	STRIKE,      ## hits a spot ahead (or the nearest enemy) after an optional warning
	ZONE,        ## lies on the ground for a while, hurting or slowing what is inside
	LINE,        ## a row of bursts in the facing direction
	CHAIN,       ## jumps from enemy to enemy
	BEAM,        ## a continuous line while the hero keeps moving slowly
	DASH,        ## the hero rushes forward, hitting what is on the way
	BLINK,       ## the hero appears behind a marked enemy
	PULL,        ## drags the nearest enemy ahead to the hero
	RAIN,        ## many strikes over a while (on an area or on marked enemies)
	BUFF,        ## changes the hero's numbers for a while
	SHIELD,      ## absorbs damage or blocks hits
	HEAL,        ## heals, restores mana or makes the hero invulnerable
	WALL,        ## a row of blocking rocks or crystals
}

@export var id: StringName  ## node id in the tree; also the key of its cooldown
@export var display_name := ""
@export var affinity: StringName  ## fuego, hielo... (empty: the adventurer's own techniques)
@export var kind := Kind.PROJECTILE
@export var mana_cost := 0.0
@export var cooldown := 1.0
@export var cast_seconds := 0.3  ## the hero stands casting this long
@export var release_at := 0.1  ## seconds into the cast when the effect comes out
@export var damage := 0
@export var push := 5.0
@export var status: StringName  ## applied on hit (quemadura, frio, marca_electrica...)
@export var stacks := 1
@export var status_seconds := 0.0  ## 0: the status's own duration
@export var scale := 1.0  ## size of the effect (and its hit area)
@export var offset := 0.0  ## how far ahead it lands, or the reach when it looks for a target
@export var radius := 1.5
@export var length := 0.0  ## of lines, beams, dashes and walls
@export var line := 0.0  ## a zone stretched into a line across the facing direction
@export var duration := 0.0
@export var tick := 0.5
@export var delay := 0.0  ## warning before a strike or line lands
@export var count := 1  ## projectiles, bursts of a line, jumps of a chain, strikes of a rain
@export var interval := 0.0  ## between volleys or strikes
@export var step_delay := 0.0  ## between the bursts of a line
@export var spread_deg := 15.0
@export var speed := 14.0
@export var pierce := false
@export var bounce := 0
@export var explode_radius := 0.0
@export var split := 0
@export var split_damage := 0
@export var embers := 0
@export var ember_damage := 0
@export var once := false  ## a line hits each enemy once
@export var slow := 1.0  ## speed factor inside a zone
@export var stun_once := 0.0
@export var single_target := false  ## a zone that zaps one enemy per tick
@export var follow := false  ## a zone that moves with the hero
@export var marks := 0  ## extra marks of the affinity applied by a zone, once per enemy
@export var self_mods := {}  ## numbers changed for the hero while inside the zone
@export var mods := {}  ## BUFF: the hero's numbers changed for `duration`
@export var shield := 0  ## SHIELD: damage absorbed
@export var hits := 0  ## SHIELD: hits blocked; WALL: hits each piece takes
@export var thorns := 0  ## SHIELD: damage dealt to who breaks a block
@export var break_status: StringName  ## SHIELD: applied around when it breaks
@export var heal_pct := 0.0
@export var heal_if_hits := 0  ## heal only if the area struck at least this many enemies
@export var invulnerable := 0.0  ## HEAL: seconds; DASH: any value = during the dash
@export var interruptible := false
@export var hp_cost_pct := 0.0
@export var restore_mp := false
@export var target: StringName  ## "nearest": aims at the nearest enemy
@export var on_marked: StringName  ## only on enemies with this status
@export var consume: StringName  ## removes this status from the target...
@export var per_stack := 0  ## ...adding this damage per stack removed
@export var bonus_vs := {}  ## status -> damage factor against enemies that have it
@export var stun_if: StringName  ## stuns enemies that have this status
@export var stack_status: StringName  ## the status counted by the two below
@export var mp_per_stack := 0
@export var hp_per_stack := 0
@export var aoe_marked := 0.0  ## also hits every enemy with marks within this radius
@export var charges := 1
@export var double_every := 0  ## every Nth cast fires twice
@export var repeat_after := 0.0  ## fires again after this many seconds
@export var trail_status: StringName  ## DASH: leaves a short zone applying this
@export var shatter_damage := 0  ## WALL: bursts when a piece breaks
@export var prop := "boulder"  ## WALL: the prop drawn for each piece
@export var fx := ""  ## AREA: another effect instead of the affinity's explosion


static func from_dict(node_id: StringName, name: String, tree: StringName, data: Dictionary) -> SkillData:
	var s := SkillData.new()
	s.id = node_id
	s.display_name = name
	s.affinity = tree if tree in Affinity.ALL else &""
	s.apply(data, "set")
	return s


## Applies a block of changes: "set" replaces, "add" sums, "mul" multiplies, "merge_mods" adds buff numbers.
func apply(values: Dictionary, op: String) -> void:
	for key: String in values:
		if key == "kind":
			kind = Kind[values[key]]
			continue
		var value: Variant = values[key]
		var current: Variant = get(key)
		match op:
			"set":
				if current is StringName:
					value = StringName(str(value))
				elif current is int and value is float:
					value = int(value)
				set(key, value)
			"add":
				set(key, current + value)
			"mul":
				var v: Variant = current * value
				set(key, int(round(v)) if current is int else v)
			"merge_mods":
				var merged: Dictionary = mods.duplicate()
				merged[key] = merged.get(key, 0.0) + value
				mods = merged
