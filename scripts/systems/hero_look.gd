class_name HeroLook
## The hero's look chosen in the character creator: a drawn model (gender and hairstyle) and the
## colours of the hair, skin, clothes and cape. The colours are painted over the model's sprite
## sheet with its group mask (built by tools/art_pipeline/build.py), keeping the drawing's shading.
## The look is saved in user://personaje.json.

const FILE := "user://personaje.json"

## Drawn models. A new hairstyle or outfit drawing is one more entry (and its sprite set + mask).
const MODELS := [
	{"gender": "Hombre", "hair": "Puntas", "set": "hero"},
	{"gender": "Mujer", "hair": "Coleta", "set": "heroine"},
]

## Colour choices; "" keeps the drawing's own colour.
const HAIR := [["Original", ""], ["Negro", "2a2630"], ["Castaño", "6b3f24"], ["Rubio", "e8c25a"],
		["Pelirrojo", "c2482a"], ["Blanco", "e8e6ee"], ["Azul", "3d5fb0"], ["Rosa", "e07aa8"],
		["Verde", "4f9a5a"], ["Morado", "7a4fb0"]]
const SKIN := [["Original", ""], ["Clara", "f6d2bc"], ["Media", "e0aa86"], ["Morena", "b57a52"],
		["Oscura", "7a4a32"]]
## Outfits: [name, clothes colour, cape and scarf colour]
const OUTFITS := [["Aventurero", "", ""], ["Explorador", "4f7a3a", "7a5230"], ["Arcano", "5a3f9a", "d0a03a"],
		["Guardián", "6e7888", "2f4f8a"], ["Sombra", "34343c", "1e1e24"], ["Real", "e6e2d8", "9a1e2e"],
		["Brasa", "b8462a", "3a2a24"], ["Bruma", "6aa0b8", "e6e6ee"]]

const GROUPS := {1: "hair", 2: "skin", 3: "clothes", 4: "cape"}

static var _frames_cache := {}


static func default_look() -> Dictionary:
	return {"model": 0, "hair": 0, "skin": 0, "outfit": 0}


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
	look.model = posmod(look.model, MODELS.size())
	look.hair = posmod(look.hair, HAIR.size())
	look.skin = posmod(look.skin, SKIN.size())
	look.outfit = posmod(look.outfit, OUTFITS.size())
	return look


## Target colour per group id for a look (null keeps the drawn colour).
static func targets(look: Dictionary) -> Dictionary:
	var hex := {1: HAIR[look.hair][1], 2: SKIN[look.skin][1], 3: OUTFITS[look.outfit][1], 4: OUTFITS[look.outfit][2]}
	var out := {}
	for id: int in hex:
		out[id] = Color(hex[id]) if hex[id] != "" else null
	return out


## The model's sprite frames painted with the look's colours.
static func frames(look: Dictionary) -> SpriteFrames:
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
		var id := groups[i] / 50
		if id == 0 or target.get(id) == null:
			continue
		var c := Color8(data[i * 4], data[i * 4 + 1], data[i * 4 + 2])
		sum[id] = sum.get(id, 0.0) + c.v
		count[id] = count.get(id, 0) + 1
	var memo := {}
	for i in groups.size():
		var id := groups[i] / 50
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
