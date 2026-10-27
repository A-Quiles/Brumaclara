extends Node3D
## Development gallery of the bestiary: every enemy in data/enemies stands still in rows, with its name
## and numbers above it, and the hero can walk among them (open the scene in the editor and press F6).
## Not part of the game.

const ENEMY := preload("res://scenes/characters/enemies/wolf.tscn")
const DATA_DIR := "res://data/enemies/"
const COLUMNS := 6
const GAP := Vector2(4.6, 6.5)
const ATTACKS := {"pounce": "salto", "burst": "golpe en área", "volley": "disparos"}


func _ready() -> void:
	var files := Array(DirAccess.get_files_at(DATA_DIR)).filter(func(f: String) -> bool: return f.ends_with(".tres"))
	files.sort()
	for i in files.size():
		var data: EnemyData = load(DATA_DIR + files[i])
		var e: Node3D = ENEMY.instantiate()
		e.set("data", data)
		var at := Vector3((i % COLUMNS - (COLUMNS - 1) / 2.0) * GAP.x, 0, -2.0 - (i / COLUMNS) * GAP.y)
		$Exhibits.add_child(e)
		e.global_position = at
		e.set_physics_process(false)  # stuffed: no hunting in the gallery
		var label := Label3D.new()
		label.text = "%s\n%d PV · %s" % [data.display_name, data.max_hp, ATTACKS.get(data.attack_kind, data.attack_kind)]
		label.font_size = 22
		label.pixel_size = 0.012
		label.outline_size = 8
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		$Exhibits.add_child(label)
		label.global_position = at + Vector3(0, 0.05, 0.9)  # on the floor, in front of its feet
