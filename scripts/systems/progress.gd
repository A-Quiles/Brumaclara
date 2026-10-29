extends Node
## The hero's progress in the current game (autoload "Progress"): level and experience, learning
## points (PA) and attributes, the affinity chosen at the shrine, the tree nodes learned and the skills
## in each slot. It also turns all that into the hero's numbers. Rules: docs/arbol_habilidades.md.
## Saved in user://partida.json every time something changes.

signal changed

const FILE := "user://partida.json"
const MAX_LEVEL := 40
const SLOTS := 4  ## skill slots (Q, E, R, C); the ultimate has its own (X)
const PA_PER_LEVEL := 2
const TREE_IDS: Array[StringName] = [&"fuego", &"hielo", &"rayo", &"sombra", &"tierra", &"luz", &"tronco"]
const TIER_PA := [0, 0, 4, 10, 18, 28]  ## PA spent in a tree to open each tier (index = tier)
const SECONDARY_TIER := 3  ## secondary affinities stop here
const ULTIMATE_NEEDS := 3  ## nodes of tier IV or V before the ultimate
const ATTRS := ["vitalidad", "poder", "control", "agilidad"]
const ATTR_CAP := {"vitalidad": 999, "poder": 25, "control": 25, "agilidad": 15}
## level at which the Brumaclara shrine can awaken each secondary affinity (stand-in for the
## shrines of chapters 3 and 5, which do not exist yet)
const SECONDARY_LEVELS := [10, 20]
## what the hero can carry (the inventory, Tab): name, description, what using it restores, and its icon
## in the adventurer's icon sheet ("icon") or a skill's icon ("skill_icon"); "tint" colours the icon
const ITEMS := {
	&"pocion": {"name": "Poción de vida", "text": "Recupera 40 PV al momento.", "hp": 40, "icon": 17},
	&"tonico": {"name": "Tónico de maná", "text": "Recupera 30 PM al momento.", "mp": 30, "icon": 18},
	&"cristal": {"name": "Cristal de Fractura", "text": "Un fragmento violeta que dejan las criaturas tocadas por la grieta. Neris quiere estudiarlos.",
			"skill_icon": &"hielo.barrera_cristalina", "tint": Color(0.85, 0.6, 1.0)},
	&"monedas": {"name": "Monedas", "text": "Dinero del reino.", "icon": 26},
}
const START_ITEMS := {&"pocion": 3, &"tonico": 1}

var save_enabled := true  ## tests switch it off so they never touch the player's game

var trees := {}  ## tree id -> {"name", "nodes": [...]}
var nodes := {}  ## node id -> node dictionary (with "tree")

var level := 1
var xp := 0
var pa := 0
var attr_points := 0
var attrs := {"vitalidad": 0, "poder": 0, "control": 0, "agilidad": 0}
var principal: StringName = &""
var awakened: Array[StringName] = []  ## secondary affinities
var learned: Array[StringName] = []
var free_nodes: Array[StringName] = []  ## given with the affinity: never refunded
var equipped: Array[StringName] = [&"", &"", &"", &""]
var ultimate: StringName = &""
var inventory := {}  ## item id -> how many

var _stats := {}
var _skills := {}


func _ready() -> void:
	for id in TREE_IDS:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/trees/%s.json" % id))
		trees[id] = data
		for n: Dictionary in data.nodes:
			n["tree"] = id
			nodes[StringName(n.id)] = n
	load_game()


# --- game -------------------------------------------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(FILE)


func new_game() -> void:
	level = 1
	xp = 0
	pa = 0
	attr_points = 0
	attrs = {"vitalidad": 0, "poder": 0, "control": 0, "agilidad": 0}
	principal = &""
	awakened.clear()
	learned.clear()
	free_nodes.clear()
	equipped = [&"", &"", &"", &""]
	ultimate = &""
	inventory = START_ITEMS.duplicate()
	_changed()


func load_game() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE)) if has_save() else null
	if not data is Dictionary:
		return
	level = clampi(int(data.get("level", 1)), 1, MAX_LEVEL)
	xp = int(data.get("xp", 0))
	pa = int(data.get("pa", 0))
	attr_points = int(data.get("attr_points", 0))
	for a in ATTRS:
		attrs[a] = int(data.get("attrs", {}).get(a, 0))
	principal = StringName(data.get("principal", ""))
	awakened.assign(data.get("awakened", []).map(func(x: String) -> StringName: return StringName(x)))
	learned.assign(_known(data.get("learned", [])))
	free_nodes.assign(_known(data.get("free_nodes", [])))
	var slots: Array = data.get("equipped", [])
	for i in SLOTS:
		equipped[i] = StringName(slots[i]) if i < slots.size() and StringName(slots[i]) in learned else &""
	ultimate = StringName(data.get("ultimate", ""))
	if ultimate not in learned:
		ultimate = &""
	inventory.clear()
	var saved: Dictionary = data.get("inventory", START_ITEMS)  # saves from before the inventory get the starting items
	for id in saved:
		var item := StringName(id)
		if ITEMS.has(item) and int(saved[id]) > 0:
			inventory[item] = int(saved[id])
	_invalidate()


func save_game() -> void:
	if not save_enabled:
		return
	var f := FileAccess.open(FILE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"level": level, "xp": xp, "pa": pa, "attr_points": attr_points,
				"attrs": attrs, "principal": principal, "awakened": awakened, "learned": learned,
				"free_nodes": free_nodes, "equipped": equipped, "ultimate": ultimate, "inventory": inventory}, "\t"))


# --- inventory --------------------------------------------------------------------------------

func count(item: StringName) -> int:
	return int(inventory.get(item, 0))


func add_item(item: StringName, amount := 1) -> void:
	inventory[item] = count(item) + amount
	_changed()


## Takes one `item` away; false if there is none.
func take_item(item: StringName) -> bool:
	if count(item) <= 0:
		return false
	inventory[item] = count(item) - 1
	if inventory[item] == 0:
		inventory.erase(item)
	_changed()
	return true


# --- experience -------------------------------------------------------------------------------

func xp_next() -> int:
	return 60 + 40 * (level - 1)


## Adds experience (with the hero's bonus); returns how many levels were gained.
func gain_xp(amount: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	xp += roundi(amount * (1.0 + stat("xp_pct")))
	var gained := 0
	while xp >= xp_next() and level < MAX_LEVEL:
		xp -= xp_next()
		level += 1
		pa += PA_PER_LEVEL
		attr_points += 1
		gained += 1
	if level >= MAX_LEVEL:
		xp = 0
	_changed()
	return gained


# --- affinities and trees ---------------------------------------------------------------------

## The highest tier the hero may learn in a tree (0: locked).
func tree_access(tree: StringName) -> int:
	if tree == &"tronco" or tree == principal:
		return 5
	return SECONDARY_TIER if tree in awakened else 0


func choose_principal(affinity: StringName) -> void:
	assert(principal == &"" and affinity in Affinity.ALL)
	principal = affinity
	# the affinity comes with the first skill of its first two branches
	for branch in [0, 1]:
		for n: Dictionary in trees[affinity].nodes:
			if n.branch == branch and n.type == "activa" and n.tier == 1:
				var id := StringName(n.id)
				learned.append(id)
				free_nodes.append(id)
				_equip_free_slot(id)
				break
	_changed()


## How many secondary affinities the hero may awaken now.
func secondary_allowed() -> int:
	return SECONDARY_LEVELS.filter(func(l: int) -> bool: return level >= l).size()


func can_awaken(affinity: StringName) -> String:
	if principal == &"":
		return "Primero elige tu afinidad principal"
	if affinity == principal or affinity in awakened:
		return "Ya despertada"
	if awakened.size() >= secondary_allowed():
		var next: int = SECONDARY_LEVELS[mini(awakened.size(), SECONDARY_LEVELS.size() - 1)]
		return "Necesitas nivel %d" % next if awakened.size() < SECONDARY_LEVELS.size() else "No quedan despertares"
	return ""


func awaken(affinity: StringName) -> void:
	assert(can_awaken(affinity) == "")
	awakened.append(affinity)
	_changed()


## PA invested in a tree (the skills that came with the affinity count).
func spent_in(tree: StringName) -> int:
	var total := 0
	for id in learned:
		if nodes[id].tree == tree:  # the starting skills count: they are PA invested too
			total += int(nodes[id].cost)
	return total


## "" if the node can be learned now; otherwise the reason, ready to show.
func can_learn(id: StringName) -> String:
	var n: Dictionary = nodes[id]
	if id in learned:
		return "Aprendido"
	if n.get("implemented", true) == false:
		return "Próximamente"
	var access := tree_access(n.tree)
	if access == 0:
		return "Afinidad sin despertar" if principal != &"" else "Elige tu afinidad en el santuario"
	if n.tier > access:
		return "Las afinidades secundarias llegan al nivel III"
	if spent_in(n.tree) < TIER_PA[n.tier]:
		return "Gasta %d PA en este árbol para abrir el nivel %s" % [TIER_PA[n.tier], roman(n.tier)]
	var missing := requirement(id)
	if missing != "":
		return missing
	if n.type == "definitiva":
		var high := learned.filter(func(l: StringName) -> bool: return nodes[l].tree == n.tree and int(nodes[l].tier) >= 4).size()
		if high < ULTIMATE_NEEDS:
			return "Requiere %d nodos de nivel IV o V" % ULTIMATE_NEEDS
	if pa < int(n.cost):
		return "Faltan PA (%d de %d)" % [pa, n.cost]
	return ""


## What still keeps a node locked by the nodes before it ("" if nothing): its own list (`requires`:
## all of them; `requires_any`: one of them, the branch's lower skills) or, in trees without lists,
## the previous node of its branch.
func requirement(id: StringName) -> String:
	var n: Dictionary = nodes[id]
	for need in n.get("requires", []):
		if StringName(need) not in learned:
			return "Requiere «%s»" % nodes[StringName(need)].name
	var any: Array = n.get("requires_any", [])
	if not any.is_empty():
		for need in any:
			if StringName(need) in learned:
				return ""
		return "Requiere una habilidad de su rama de nivel inferior (p. ej. «%s»)" % nodes[StringName(any[0])].name
	if n.has("requires"):
		return ""
	var before := previous(id)
	if before != &"" and before not in learned:
		return "Requiere «%s»" % nodes[before].name
	return ""


## The node a node needs: the previous one of its branch that can be learned at all.
func previous(id: StringName) -> StringName:
	var n: Dictionary = nodes[id]
	if n.branch < 0:
		return &""
	var before: StringName = &""
	for other: Dictionary in trees[n.tree].nodes:
		if other.id == n.id:
			return before
		if other.branch == n.branch and other.get("implemented", true) != false:
			before = StringName(other.id)
	return before


func learn(id: StringName) -> void:
	assert(can_learn(id) == "")
	pa -= int(nodes[id].cost)
	learned.append(id)
	if nodes[id].type == "activa":
		_equip_free_slot(id)
	elif nodes[id].type == "definitiva" and ultimate == &"":
		ultimate = id
	_changed()


## Gives back every PA and attribute point (the starting skills stay).
func respec() -> void:
	for id in learned.duplicate():
		if id not in free_nodes:
			pa += int(nodes[id].cost)
			learned.erase(id)
	for i in SLOTS:
		if equipped[i] not in learned:
			equipped[i] = &""
	if ultimate not in learned:
		ultimate = &""
	for a in ATTRS:
		attr_points += attrs[a]
		attrs[a] = 0
	_changed()


func equip(slot: int, id: StringName) -> void:
	assert(id == &"" or (id in learned and nodes[id].type == "activa"))
	for i in SLOTS:
		if equipped[i] == id:
			equipped[i] = equipped[slot]  # swap if it was in another slot
	equipped[slot] = id
	_changed()


func equip_ultimate(id: StringName) -> void:
	assert(id == &"" or (id in learned and nodes[id].type == "definitiva"))
	ultimate = id
	_changed()


func add_attr(attr: String) -> void:
	assert(attr_points > 0 and attr in ATTRS)
	attr_points -= 1
	attrs[attr] += 1
	_changed()


func _equip_free_slot(id: StringName) -> void:
	for i in SLOTS:
		if equipped[i] == &"":
			equipped[i] = id
			return


# --- the hero's numbers -----------------------------------------------------------------------

## A number from the learned passives: modifiers add up ("thorns_status" and the like hold names).
func stat(name: String, default: Variant = 0.0) -> Variant:
	if _stats.is_empty():
		_build_stats()
	return _stats.get(name, default)


func max_hp() -> int:
	var base := 100 + 10 * (level - 1) + 12 * attr("vitalidad") + int(stat("max_hp"))
	return roundi(base * (1.0 + stat("max_hp_pct")))


func max_mp() -> float:
	return 50.0 + 5.0 * (level - 1) + stat("max_mp")


func attr(name: String) -> int:
	return mini(attrs[name], ATTR_CAP[name])


## The skill in a tree node with every learned improvement applied (cached until something changes).
func skill(id: StringName) -> SkillData:
	if _skills.has(id):
		return _skills[id]
	var n: Dictionary = nodes[id]
	var s := SkillData.from_dict(id, n.name, n.tree, n.skill)
	for l in learned:
		for m: Dictionary in nodes[l].get("mods", []):
			if m.get("skill", "") == String(id) or (m.has("skills_of") and m.skills_of == String(n.tree) \
					and (m.kind == "" or SkillData.Kind[m.kind] == s.kind)):
				for op in ["set", "add", "mul", "merge_mods"]:
					if m.has(op):
						s.apply(m[op], op)
	_skills[id] = s
	return s


## The "on" passives learned: what happens when the hero dodges, falls or runs low on health.
func triggers(event: String) -> Array:
	var out := []
	for l in learned:
		for m: Dictionary in nodes[l].get("mods", []):
			if m.get("on", "") == event:
				out.append(m)
	return out


static func roman(tier: int) -> String:
	return ["", "I", "II", "III", "IV", "V"][tier]


func _build_stats() -> void:
	_stats = {"_built": true}
	for l in learned:
		for m: Dictionary in nodes[l].get("mods", []):
			if not m.has("stat"):
				continue
			if m.has("set"):
				_stats[m.stat] = m.set
			else:
				_stats[m.stat] = _stats.get(m.stat, 0.0) + m.add


func _known(ids: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for x in ids:
		if nodes.has(StringName(x)):
			out.append(StringName(x))
	return out


func _invalidate() -> void:
	_stats.clear()
	_skills.clear()


func _changed() -> void:
	_invalidate()
	save_game()
	changed.emit()
