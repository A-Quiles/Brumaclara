extends Node3D
## El Patio de pruebas del Faro: a fenced sand ring next to the town where any creature of the bestiary
## can be called to practise the combat. The board at the north (F) lists every enemy drawn so far:
## choosing one brings a group of it (a boss comes alone), "Oleada" brings one of each from a zone, and
## "Limpiar" sends them all away. Creatures called here never come back once beaten.
## The level is built here from the props and textures of the town, so it needs no layout file.

const ENEMY_SCENE := preload("res://scenes/characters/enemies/wolf.tscn")
const ORB := preload("res://scenes/effects/xp_orb.tscn")
const DEATH := preload("res://scenes/effects/rift_burst.tscn")
const TEXT := preload("res://scenes/effects/floating_text.tscn")
const BLOCK := preload("res://shaders/terrain_block.gdshader")
const STRIP := preload("res://shaders/ground_strip.gdshader")
const GRASS := preload("res://assets/environment/textures/grass.png")
const DIRT := preload("res://assets/environment/textures/dirt.png")
const CLIFF := preload("res://assets/environment/textures/cliff.png")
const SIZE := 44.0  ## the meadow, a square
const RING := Vector2(26.0, 20.0)  ## the sand ring (x, z)
const PROPS := "res://scenes/environment/props/%s.tscn"
const NATURE := "res://scenes/environment/nature/%s.tscn"

## zone -> enemy files (data/enemies), in the bestiary's order; anything else drawn goes to "Otras".
const ZONES := {
	"Zona 1 · Afueras": ["roedor_bruma", "wolf", "jabali_espinoso", "cuervo_bruma", "lobezno", "alfa", "gris", "madre"],
	"Zona 2 · Bosque": ["polilla_luminica", "hongo", "sporineo", "guardian_raices", "hongo_f"],
	"Variantes de lobo": ["brasa", "escarcha", "tormenta", "umbral", "pedrero", "sacro"],
	"Ruinas y cuevas": ["murcielago", "esqueleto", "espectro", "golem", "murcielago_f", "esqueleto_f", "espectro_f", "golem_f"],
}

var _called: Array[Node] = []
var _reach: Area3D


func _ready() -> void:
	_build_ground()
	_build_border()
	_build_props()
	_build_board()


## Every enemy that has its numbers written, grouped by zone: [[zone, [EnemyData...]]...]
static func roster() -> Array:
	var out := []
	var seen := {}
	for zone: String in ZONES:
		var list: Array[EnemyData] = []
		for id: String in ZONES[zone]:
			var path := "res://data/enemies/%s.tres" % id
			if ResourceLoader.exists(path):
				list.append(load(path))
				seen[id] = true
		out.append([zone, list])
	var others: Array[EnemyData] = []
	for file in DirAccess.get_files_at("res://data/enemies"):
		var id := file.get_basename().trim_suffix(".tres")
		if file.ends_with(".tres") or file.ends_with(".tres.remap"):
			if not seen.has(id):
				others.append(load("res://data/enemies/%s.tres" % id))
	if not others.is_empty():
		out.append(["Otras", others])
	return out


## Brings `count` of this enemy into the ring, spread around its middle.
func call_enemy(data: EnemyData, count: int) -> void:
	for i in count:
		var e: CharacterBody3D = ENEMY_SCENE.instantiate()
		e.set("data", data)
		e.set("orb_scene", ORB)
		e.set("death_effect", DEATH)
		e.set("text_scene", TEXT)
		e.set_meta("summoned", true)  # gone for good once beaten (wolf.gd)
		e.collision_layer = 4
		e.collision_mask = 7
		var angle := TAU * (float(i) / maxf(count, 1) + randf() * 0.1)
		e.position = Vector3(cos(angle) * 4.5, 0.2, -2.0 + sin(angle) * 3.5)
		$Enemies.add_child(e)
		_called.append(e)
		_spawn_flash(e.position)


func call_wave(list: Array) -> void:
	for d: EnemyData in list:
		call_enemy(d, 1)


func clear_enemies() -> void:
	for e in _called:
		if is_instance_valid(e):
			e.queue_free()
	_called.clear()


func _spawn_flash(at: Vector3) -> void:
	var fx: Node3D = DEATH.instantiate()
	$Enemies.add_child(fx)
	fx.position = at + Vector3(0, 0.6, 0)


# --- the place ----------------------------------------------------------------------------------

func _build_ground() -> void:
	var meadow := _block(Vector3(0, -1.0, 0), Vector3(SIZE, 2.0, SIZE), GRASS)
	meadow.name = "Meadow"
	var sand := MeshInstance3D.new()  # the ring: packed earth with a ragged oval edge
	var plane := PlaneMesh.new()
	plane.size = RING
	sand.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = STRIP
	mat.set_shader_parameter("surface", DIRT)
	mat.set_shader_parameter("size", RING)
	mat.set_shader_parameter("tile", 5.45)
	mat.set_shader_parameter("oval", true)
	mat.set_shader_parameter("ragged", 0.8)
	sand.material_override = mat
	sand.position = Vector3(0, 0.015, -1.0)
	add_child(sand)


func _block(pos: Vector3, size: Vector3, top: Texture2D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := ShaderMaterial.new()
	mat.shader = BLOCK
	mat.set_shader_parameter("top_texture", top)
	mat.set_shader_parameter("side_texture", CLIFF)
	mat.set_shader_parameter("top_size", Vector2(10.9, 10.9))
	mat.set_shader_parameter("side_size", Vector2(5.45, 5.45))
	mesh.material_override = mat
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = size
	shape.shape = col
	body.add_child(shape)
	add_child(body)
	return body


func _build_border() -> void:
	var half := SIZE / 2.0 - 1.5
	for x in range(-int(half), int(half) + 1, 3):  # woods to the north, east and west
		_put(NATURE % ["tree_fir" if x % 2 == 0 else "tree_oak"], Vector3(x + randf_range(-0.6, 0.6), 0, -half + randf_range(-0.8, 0.4)))
	for z in range(-int(half) + 3, int(half) - 4, 3):
		_put(NATURE % "tree_oak", Vector3(-half + randf_range(-0.4, 0.6), 0, z))
		_put(NATURE % "tree_fir", Vector3(half + randf_range(-0.6, 0.4), 0, z))
	for x in range(-int(half), int(half) + 1, 2):  # a fence along the south, open in the middle
		if absf(x) > 2.5:
			_put(PROPS % "fence", Vector3(x, 0, half))
	for x: float in [-half - 1.0, half + 1.0]:  # invisible walls round the meadow
		_wall(Vector3(x, 1.5, 0), Vector3(0.5, 3, SIZE))
	for z: float in [-half - 1.0, half + 1.0]:
		_wall(Vector3(0, 1.5, z), Vector3(SIZE, 3, 0.5))


func _build_props() -> void:
	var r := RING / 2.0 + Vector2(1.6, 1.4)
	for i in 8:  # lamps round the ring (lit at night)
		var a := TAU * i / 8.0 + 0.2
		_put(PROPS % "street_lamp", Vector3(cos(a) * r.x, 0, -1.0 + sin(a) * r.y))
	for p: Array in [["training_dummy", Vector3(-10, 0, 8)], ["training_dummy", Vector3(-8, 0, 9)],
			["archery_target", Vector3(11, 0, 8)], ["weapon_rack", Vector3(9, 0, -12.5)],
			["weapon_rack", Vector3(-9, 0, -12.5)], ["barrel_stack", Vector3(-14, 0, -11)], ["crate", Vector3(14, 0, -11)],
			["banner", Vector3(-4, 0, -13)], ["banner", Vector3(4, 0, -13)], ["bench", Vector3(13, 0, 6)],
			["hay_bale", Vector3(-15, 0, 4)], ["bucket", Vector3(15.5, 0, -6)], ["trough", Vector3(-15.5, 0, -6)]]:
		_put(PROPS % p[0], p[1])


func _build_board() -> void:
	var board := _put(PROPS % "notice_board", Vector3(0, 0, -12.5))
	var label := Label3D.new()
	label.text = "Patio de pruebas\n[F] llamar criaturas"
	label.font_size = 56
	label.pixel_size = 0.012
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 3.0, 0)
	board.add_child(label)
	var reach := Area3D.new()
	_reach = reach
	reach.collision_layer = 0
	reach.collision_mask = 2
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.4
	shape.shape = sphere
	reach.add_child(shape)
	board.add_child(reach)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or get_tree().paused:
		return
	if _reach and _reach.get_overlapping_bodies().any(func(b: Node) -> bool: return b.is_in_group("player")):
		get_viewport().set_input_as_handled()
		open_menu()


func open_menu() -> void:
	var menu := ArenaMenu.new()
	menu.arena = self
	$HUD.add_child(menu)


func _put(path: String, at: Vector3) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var node: Node3D = load(path).instantiate()
	node.position = at
	$Props.add_child(node)
	return node


func _wall(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = at
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
