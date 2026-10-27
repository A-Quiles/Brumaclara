class_name HeroLook
## The hero's look chosen in the character creator: a drawn model (gender and hairstyle) and the
## colours of the hair, skin, tunic and vest. The colours are painted over the model's sprite
## sheet with its group mask (built by tools/art_pipeline/build.py), keeping the drawing's shading.
## The look is saved in user://personaje.json.

const FILE := "user://personaje.json"

## Drawn models: each hairstyle is its own sprite set (and colour mask) built by
## tools/art_pipeline/build.py. A new hairstyle or outfit drawing is one more entry.
const MODELS := [
	{"gender": "Hombre", "hair": "Puntas", "set": "hero"},
	{"gender": "Hombre", "hair": "Puntas altas", "set": "hero__alto"},
	{"gender": "Hombre", "hair": "Cresta", "set": "hero__cresta"},
	{"gender": "Hombre", "hair": "Moño", "set": "hero__mono"},
	{"gender": "Hombre", "hair": "Largo", "set": "hero__largo"},
	{"gender": "Hombre", "hair": "Voluminoso", "set": "hero__volumen"},
	{"gender": "Mujer", "hair": "Coleta", "set": "heroine"},
	{"gender": "Mujer", "hair": "Coleta de puntas", "set": "heroine__alto"},
	{"gender": "Mujer", "hair": "Cresta", "set": "heroine__cresta"},
	{"gender": "Mujer", "hair": "Moño", "set": "heroine__mono"},
	{"gender": "Mujer", "hair": "Suelta", "set": "heroine__largo"},
	{"gender": "Mujer", "hair": "Voluminosa", "set": "heroine__volumen"},
]

## Colour choices; "" keeps the drawing's own colour.
const HAIR := [["Original", ""], ["Negro", "2a2630"], ["Carbón", "403c48"], ["Castaño oscuro", "4a2c1a"],
		["Castaño", "6b3f24"], ["Caoba", "8a3a22"], ["Cobrizo", "b5622e"], ["Pelirrojo", "c2482a"],
		["Rubio fresa", "d98c5a"], ["Rubio", "e8c25a"], ["Platino", "f0e6b8"], ["Blanco", "e8e6ee"],
		["Gris", "9a9aa6"], ["Plata", "c4cad6"], ["Azul", "3d5fb0"], ["Marino", "23346e"],
		["Celeste", "6fb8e8"], ["Turquesa", "2fb3a8"], ["Verde", "4f9a5a"], ["Esmeralda", "1f7a4a"],
		["Lima", "9ccf4a"], ["Morado", "7a4fb0"], ["Violeta", "a56ae0"], ["Rosa", "e07aa8"],
		["Fucsia", "c8307a"], ["Carmesí", "b01c2e"]]
const SKIN := [["Original", ""], ["Porcelana", "f8e0d0"], ["Clara", "f6d2bc"], ["Rosada", "f0b8a0"],
		["Dorada", "e8c08a"], ["Media", "e0aa86"], ["Aceituna", "c4946a"], ["Bronceada", "c08a58"],
		["Morena", "b57a52"], ["Canela", "9a5e3a"], ["Oscura", "7a4a32"], ["Ébano", "4e3024"]]
## Outfits: [name, tunic colour, vest colour]. A traveller's clothes, not a hero's (no cape).
const OUTFITS := [["Viajero", "", ""], ["Campesino", "d8cfb4", "7a5230"], ["Leñador", "4f7a3a", "6b3f24"],
		["Marinero", "e6e6ee", "2f4f8a"], ["Herrero", "6e6a66", "3a2a24"], ["Mercader", "c9a04a", "5a3f9a"],
		["Brasa", "b8462a", "3a2a24"], ["Bruma", "6aa0b8", "e6e6ee"], ["Noche", "34343c", "5a2030"],
		["Guardia", "3a5f9a", "d8b04a"], ["Cazador", "5a6a3a", "3a2a1a"], ["Alquimista", "7a3a8a", "d8cfb4"],
		["Costero", "3aa0a0", "e8d8a8"], ["Arcilla", "b8764a", "5a3a2a"], ["Orquídea", "c86aa0", "4a2a5a"],
		["Ceniza", "8a8a92", "3a3a42"], ["Dorado", "e0b84a", "7a2a2a"], ["Bosque", "2f5a3a", "a88a4a"],
		["Escarlata", "c0302a", "e8e0c8"]]
## Boots, belt and bracers.
const LEATHER := [["Original", ""], ["Castaño", "6b4430"], ["Negro", "2a2428"], ["Pizarra", "4a5060"],
		["Vino", "6a2a36"], ["Bosque", "3a5a3a"], ["Tinta", "2a3a6a"], ["Cuero claro", "a07a4a"],
		["Hueso", "c8bca0"], ["Rojo", "b03a2a"]]
const TROUSERS := [["Original", ""], ["Negro", "2a2a30"], ["Gris", "6a6a76"], ["Marrón", "5a4030"],
		["Marino", "2a3a6a"], ["Oliva", "5a6a3a"], ["Crema", "c8b890"], ["Burdeos", "6a2a3a"],
		["Verde oscuro", "2a4a3a"]]

const STEP := 30  ## the colour masks store group id * STEP
const GROUPS := {1: "hair", 2: "skin", 3: "clothes", 4: "vest", 5: "leather", 6: "trousers"}

static var _frames_cache := {}


static func default_look() -> Dictionary:
	return {"model": 0, "hair": 0, "skin": 0, "outfit": 0, "leather": 0, "trousers": 0}


static func load_look() -> Dictionary:
	var look := default_look()
	var text := FileAccess.get_file_as_string(FILE)
	var data: Variant = JSON.parse_string(text) if text != "" else null
	if data is Dictionary:
		for key: String in look:
			if data.has(key):
				look[key] = int(data[key])
	return clamp_look(look)


static func save_look(look: Dictionary) -> void:
	var f := FileAccess.open(FILE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(look))


static func clamp_look(look: Dictionary) -> Dictionary:
	for key: String in default_look():  # looks saved before a choice existed keep the drawn colour
		if not look.has(key):
			look[key] = 0
	look.model = posmod(look.model, MODELS.size())
	look.hair = posmod(look.hair, HAIR.size())
	look.skin = posmod(look.skin, SKIN.size())
	look.outfit = posmod(look.outfit, OUTFITS.size())
	look.leather = posmod(look.leather, LEATHER.size())
	look.trousers = posmod(look.trousers, TROUSERS.size())
	return look


## Target colour per group id for a look (null keeps the drawn colour).
static func targets(look: Dictionary) -> Dictionary:
	var hex := {1: HAIR[look.hair][1], 2: SKIN[look.skin][1], 3: OUTFITS[look.outfit][1], 4: OUTFITS[look.outfit][2],
			5: LEATHER[look.leather][1], 6: TROUSERS[look.trousers][1]}
	var out := {}
	for id: int in hex:
		out[id] = Color(hex[id]) if hex[id] != "" else null
	return out


## The model's sprite frames painted with the look's colours.
static func frames(look: Dictionary) -> SpriteFrames:
	look = clamp_look(look.duplicate())
	var key := JSON.stringify(look)
	if _frames_cache.has(key):
		return _frames_cache[key]
	var set_name: String = MODELS[look.model].set
	var base: SpriteFrames = load("res://assets/characters/hero/%s_frames.tres" % set_name)
	var tex := ImageTexture.create_from_image(paint(set_name, targets(look)))
	var out := base.duplicate(true) as SpriteFrames
	for anim in out.get_animation_names():
		for i in out.get_frame_count(anim):
			var atlas := out.get_frame_texture(anim, i) as AtlasTexture
			if atlas:
				atlas.atlas = tex
	_frames_cache[key] = out
	return out


## The model's sheet with each colour group moved to its target colour. The shading is kept: every
## shade keeps its brightness relative to the group's typical brightness.
static func paint(set_name: String, target: Dictionary) -> Image:
	var img: Image = load("res://assets/characters/hero/%s.png" % set_name).get_image()
	img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var mask: Image = load("res://assets/characters/hero/%s_mask.png" % set_name).get_image()
	mask.decompress()
	mask.convert(Image.FORMAT_L8)
	var data := img.get_data()
	var groups := mask.get_data()
	# typical brightness of each group: the mean value of its pixels
	var sum := {}
	var count := {}
	for i in groups.size():
		var id := groups[i] / STEP
		if id == 0 or target.get(id) == null:
			continue
		var c := Color8(data[i * 4], data[i * 4 + 1], data[i * 4 + 2])
		sum[id] = sum.get(id, 0.0) + c.v
		count[id] = count.get(id, 0) + 1
	var memo := {}
	for i in groups.size():
		var id := groups[i] / STEP
		if not count.has(id):
			continue
		var p := i * 4
		var src := (data[p] << 16) | (data[p + 1] << 8) | data[p + 2]
		var k := id * 16777216 + src
		if not memo.has(k):
			var c := Color8(data[p], data[p + 1], data[p + 2])
			var t: Color = target[id]
			var rel: float = c.v / (sum[id] / count[id])
			# darker shades a bit more saturated, lighter ones a bit less, like the drawn ramps
			var s := clampf(t.s * (1.15 - 0.25 * rel), 0.0, 1.0)
			memo[k] = Color.from_hsv(t.h, s, minf(t.v * rel, 1.0))
		var n: Color = memo[k]
		data[p] = n.r8
		data[p + 1] = n.g8
		data[p + 2] = n.b8
	return Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)
