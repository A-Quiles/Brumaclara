class_name SpriteCatalog
extends RefCounted
## Every sprite the levels can be decorated with, read from the asset folders each time the edit
## mode opens, so a new image shows up without touching any code. File names say what an image is:
##   <name>.png                    the object as drawn (facing the camera unless vistas.json says otherwise)
##   <name>__<dir>.png             the object turned: <dir> is where it faces on screen (s towards the
##                                 camera, then sw, w, nw, n, ne, e, se); a missing side is the mirror
##                                 image of its opposite (w of e, ne of nw...)
##   <name>__<model>[__<dir>].png  another model of the same object (horse__grazing)
## Images in assets/nuevos are raw (straight from an image generator, any size, on a flat background):
## they are cut out of their background and brought down to the game's pixel size.
## An object is built from the prefab of its name when there is one (with its collision, shadow and
## light) or else from the image alone. Resizing redraws the image at the new size, so its pixels
## stay as big as everyone else's.

const PX := 0.0449  # world units per sprite pixel (docs/guia_de_arte.md)
const FOLDERS := {
	"props": "res://assets/environment/props",
	"nature": "res://assets/environment/nature",
	"nuevos": "res://assets/nuevos",
}
const LABELS := {"props": "Objetos", "nature": "Naturaleza", "nuevos": "Nuevos"}
const DIRS: Array[String] = ["s", "sw", "w", "nw", "n", "ne", "e", "se"]  # clockwise, seen from above
const MIRROR := {"s": "s", "sw": "se", "w": "e", "nw": "ne", "n": "n", "ne": "nw", "e": "w", "se": "sw"}
const DIR_NAMES := {"s": "S", "sw": "SO", "w": "O", "nw": "NO", "n": "N", "ne": "NE", "e": "E", "se": "SE"}
## turn of a box-shaped collision for each direction (a fence facing s runs along x)
const BOX_TURN := {"s": 0.0, "n": 0.0, "e": 90.0, "w": 90.0, "se": 45.0, "nw": 45.0, "sw": -45.0, "ne": -45.0}
const FACING_FILE := "res://assets/environment/vistas.json"
const SHADOW := "res://assets/environment/textures/blob_shadow.png"
const RAW_HEIGHT := 48  # height in pixels of a raw image whose pixel size can't be read from it
const BIG := 256  # an image taller than this is not game-sized yet: it is adapted like a raw one
const LIGHTS := ["lantern", "lamp", "torch", "candle", "farol", "lampara", "antorcha", "vela"]
const NAMES := {
	"archery_target": "diana", "banner": "estandarte", "barrel": "barril", "barrel_stack": "barriles y cajas",
	"bench": "banco", "bread_stool": "puesto de pan", "bucket": "cubo", "chalkboard": "pizarra", "chest": "cofre",
	"chimney": "chimenea", "crate": "caja", "crystal": "cristal", "cypress_pot": "ciprés en maceta",
	"dormer": "buhardilla", "fence": "valla", "fence_gate": "portón", "firewood": "leña", "flower_bed": "parterre",
	"flower_cart": "carro de flores", "fountain": "fuente", "hay_bale": "paca de heno", "hay_cart": "carro de heno",
	"hay_pile": "montón de heno", "horse": "caballo", "lantern": "farolillo", "low_wall": "muro bajo",
	"notice_board": "tablón", "pillar": "pilar", "planter": "jardinera", "rift_crack": "grieta de la Fractura",
	"rift_crystals": "cristales de la Fractura", "rose_bush": "rosal", "rune_stone": "piedra rúnica",
	"sacks": "sacos", "signpost": "poste indicador", "stall_blue": "puesto azul", "stall_green": "puesto verde",
	"stall_red": "puesto rojo", "street_lamp": "farola", "town_gate": "puerta de la muralla",
	"training_dummy": "muñeco de práctica", "tree_planter": "árbol en jardinera", "trough": "abrevadero",
	"wagon": "carreta", "merchant_wagon": "carromato de mercader", "cloth_cart": "carretilla de telas",
	"potion_stall": "puesto de pociones", "smith_stall": "puesto de herrero", "food_stall": "puesto de comida",
	"fortune_tent": "tienda de la adivina", "wall_lantern": "farol de pared", "weapon_rack": "armero", "well": "pozo",
	"boulder": "roca", "bush": "arbusto", "bush_berries": "arbusto con bayas", "flowers": "flores",
	"mushrooms": "setas", "rift_bramble": "zarza de la Fractura", "rocks": "piedras", "stump": "tocón",
	"tall_grass": "hierba alta", "tree_dead": "árbol seco", "tree_fir": "abeto", "tree_oak": "roble",
	"tree_young": "arbolillo", "town_arch": "arco",
}
const MODEL_NAMES := {"grazing": "pastando", "lying": "tumbado", "tipped": "volcado", "rolled": "en rollos",
	"upright": "de pie", "tall": "alta", "post": "poste", "alazan": "alazán"}

static var _facing := {}   # sprite without a direction in its name -> where it faces (vistas.json)
static var _files := {}    # key ("props/bench__w") -> image file
static var _groups := {}   # folder -> {group ("props/bench") -> {model -> {dir -> key}}}
static var _images := {}   # texture instance id -> Image (picking and resizing)
static var _sized := {}    # "key|scale" -> Texture2D
static var _raw := {}      # key -> {image, native, time}: raw images cut out (assets/nuevos)


## Reads the folders again: images added since the last scan appear, removed ones go.
static func scan() -> void:
	_files.clear()
	_groups.clear()
	_sized.clear()
	_facing = {}
	if FileAccess.file_exists(FACING_FILE):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FACING_FILE))
		if parsed is Dictionary:
			_facing = parsed
	for folder: String in FOLDERS:
		var groups := {}
		for file in _image_files(FOLDERS[folder]):
			var key: String = folder + "/" + file.get_basename()
			_files[key] = FOLDERS[folder] + "/" + file
			var i := info(key)
			groups.get_or_add(i.group, {}).get_or_add(i.model, {})[i.dir] = key
		_groups[folder] = groups


## Forgets the images it keeps (they load again when needed).
static func clear() -> void:
	_files.clear()
	_groups.clear()
	_images.clear()
	_sized.clear()
	_raw.clear()


static func _ready_scan() -> void:
	if _files.is_empty():
		scan()


static func has_key(key: String) -> bool:
	_ready_scan()
	return _files.has(key)


## {group ("props/bench") -> {model -> {dir -> key}}} of a folder
static func groups(folder: String) -> Dictionary:
	_ready_scan()
	return _groups.get(folder, {})


## group, model and direction of an image key ("props/horse__grazing" -> props/horse, grazing, e)
static func info(key: String) -> Dictionary:
	var folder := key.get_slice("/", 0)
	var parts := key.get_slice("/", 1).split("__")
	var dir := ""
	if parts.size() > 1 and parts[parts.size() - 1] in DIRS:
		dir = parts[parts.size() - 1]
		parts.remove_at(parts.size() - 1)
	if dir == "":
		dir = _facing.get(folder + "/" + "__".join(parts), "s")
	return {"group": folder + "/" + parts[0], "model": "__".join(parts.slice(1)), "dir": dir}


## The image a group starts with: its main model, facing the camera if it has that view.
static func default_key(group: String) -> String:
	var models: Dictionary = groups(group.get_slice("/", 0)).get(group, {})
	if models.is_empty():
		return ""
	var names := models.keys()
	names.sort()
	var drawn: Dictionary = models["" if models.has("") else names[0]]
	for d in DIRS:
		if drawn.has(d):
			return drawn[d]
	return ""


## What each direction of a model shows: dir -> [image key, mirrored]
static func views(group: String, model: String) -> Dictionary:
	var drawn: Dictionary = groups(group.get_slice("/", 0)).get(group, {}).get(model, {})
	var out := {}
	for d in DIRS:
		if drawn.has(d):
			out[d] = [drawn[d], false]
		elif drawn.has(MIRROR[d]):
			out[d] = [drawn[MIRROR[d]], true]
	return out


## The view after turning the object one step clockwise (step 1) or anticlockwise (-1): [key, mirrored].
## An object drawn from one side only is mirrored instead.
static func turn(key: String, flip: bool, step: int) -> Array:
	var i := info(key)
	var available := views(i.group, i.model)
	var now: String = MIRROR[i.dir] if flip else i.dir
	var at := DIRS.find(now)
	for k in range(1, DIRS.size()):
		var d: String = DIRS[posmod(at + step * k, DIRS.size())]
		if available.has(d):
			return available[d]
	return [key, not flip]


## The next model of the object (step 1 or -1), turned the same way if it can be: [key, mirrored].
static func next_model(key: String, flip: bool, step: int) -> Array:
	var i := info(key)
	var models: Array = groups(i.group.get_slice("/", 0)).get(i.group, {}).keys()
	models.sort()
	if models.size() < 2:
		return [key, flip]
	var model: String = models[posmod(models.find(i.model) + step, models.size())]
	var available := views(i.group, model)
	var now: String = MIRROR[i.dir] if flip else i.dir
	if available.has(now):
		return available[now]
	return [available.values()[0][0], false]


## "caballo pastando · E": what the object is and where it faces
static func label(key: String, flip := false) -> String:
	if key == "":
		return ""
	var i := info(key)
	var stem: String = i.group.get_slice("/", 1)
	var text: String = NAMES.get(stem, stem.replace("_", " "))
	if i.model != "":
		for part: String in i.model.split("_"):  # "negro_grazing" -> "negro pastando"
			text += " " + MODEL_NAMES.get(part, part)
	return "%s · %s" % [text, DIR_NAMES[MIRROR[i.dir] if flip else i.dir]]


static func group_label(group: String) -> String:
	var stem := group.get_slice("/", 1)
	return NAMES.get(stem, stem.replace("_", " "))


## The image of a key at `scale` times its size, redrawn so that its pixels keep the game's size.
static func sized(key: String, scale := 1.0) -> Texture2D:
	scale = snappedf(scale, 0.01)
	var id := "%s|%s" % [key, scale]
	if _sized.has(id):
		return _sized[id]
	_ready_scan()
	var path: String = _files.get(key, "")
	if path == "":
		return null
	var tex: Texture2D
	var base: Texture2D = null if key.begins_with("nuevos/") else _load_texture(path)
	if base == null or base.get_height() > BIG:  # not game-sized yet: cut it out and bring it down
		var raw := _raw_source(key, path)
		var img := shrink(raw.image, maxi(2, roundi(raw.native * scale)))
		if raw.background != null:
			_defringe(img, raw.background)
		tex = ImageTexture.create_from_image(img)
	elif is_equal_approx(scale, 1.0):
		tex = base
	else:
		var img := image_of(base)
		tex = ImageTexture.create_from_image(shrink(img, maxi(1, roundi(img.get_height() * scale))))
	_sized[id] = tex
	return tex


## A still picture of a key (the first frame of an animated object), for the palette.
static func preview(key: String) -> Texture2D:
	var frames_path: String = _files.get(key, "").get_basename() + "_frames.tres"
	if ResourceLoader.exists(frames_path):
		var frames: SpriteFrames = load(frames_path)
		return frames.get_frame_texture(frames.get_animation_names()[0], 0)
	return sized(key)


## The pixels of a texture (cached; used to pick objects by their visible pixels and to resize them).
static func image_of(tex: Texture2D) -> Image:
	var id := tex.get_instance_id()
	if not _images.has(id):
		var img := tex.get_image()
		if img and img.is_compressed():
			img.decompress()
		_images[id] = img
	return _images[id]


## The image key a texture was loaded from ("" if it is not one of the catalog's folders).
static func key_of(tex: Texture2D) -> String:
	if tex == null:
		return ""
	var path := tex.resource_path
	for folder: String in FOLDERS:
		if path.get_base_dir() == FOLDERS[folder]:
			return folder + "/" + path.get_file().get_basename()
	return ""


# --- building objects -----------------------------------------------------------------------------

## A new object showing image `key`, standing on its origin.
static func build(key: String) -> Node3D:
	_ready_scan()
	var i := info(key)
	var node: Node3D
	var prefab := "res://scenes/environment/%s.tscn" % key
	var base := "res://scenes/environment/%s.tscn" % i.group
	if not key.begins_with("nuevos/") and ResourceLoader.exists(prefab):
		node = load(prefab).instantiate()
	elif not key.begins_with("nuevos/") and ResourceLoader.exists(base):
		node = load(base).instantiate()
		node.scene_file_path = ""  # no longer that prefab: a level saving it keeps the new image
		_reskin(node, key, i.dir, info(i.group).dir)
	else:
		node = _generic(key)
	node.set_meta("key", key)
	return node


## Resizes an object built from a sprite: its body (collision, shadow, light) scales with it, while
## its image is redrawn at the new size so that its pixels keep the game's size.
static func set_size(node: Node3D, scale: float) -> void:
	node.scale = Vector3.ONE * scale
	var sprite := node.get_node_or_null("Sprite") as Sprite3D
	var key: String = node.get_meta("key", "")
	if sprite == null or key == "":
		return
	if not sprite.has_meta("offset_y"):
		sprite.set_meta("offset_y", sprite.offset.y)
	var tex := sized(key, scale)
	if tex == null:
		return
	sprite.texture = tex
	sprite.offset = Vector2(-tex.get_width() / 2.0, float(sprite.get_meta("offset_y")) * scale)
	sprite.scale = Vector3.ONE / scale


## A soft round shadow on the ground, `width` units wide.
static func blob(width: float) -> Sprite3D:
	var shadow := Sprite3D.new()
	shadow.name = "Shadow"
	shadow.texture = load(SHADOW)
	shadow.pixel_size = width / 16.0
	shadow.axis = Vector3.AXIS_Y
	shadow.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shadow.position = Vector3(0.05, 0.02, -width * 0.18)  # under the drawn footprint
	return shadow


static func _generic(key: String) -> Node3D:
	var body := StaticBody3D.new()
	body.name = key.get_slice("/", 1).to_pascal_case()
	var frames_path: String = _files.get(key, "").get_basename() + "_frames.tres"
	var sprite: SpriteBase3D
	var size := Vector2.ONE
	if ResourceLoader.exists(frames_path):  # an animated object (fountain): plays its first animation
		var anim := AnimatedSprite3D.new()
		anim.sprite_frames = load(frames_path)
		anim.autoplay = anim.sprite_frames.get_animation_names()[0]
		anim.animation = anim.autoplay
		size = anim.sprite_frames.get_frame_texture(anim.animation, 0).get_size()
		sprite = anim
	else:
		var still := Sprite3D.new()
		still.texture = sized(key)
		if still.texture:
			size = still.texture.get_size()
		sprite = still
	sprite.name = "Sprite"
	sprite.pixel_size = PX
	sprite.centered = false
	sprite.offset = Vector2(-size.x / 2.0, 0)
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD  # solid pixels sort exactly against each other
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(sprite)
	var flat := size.y < 14.0  # flowers, cracks, puddles: no shadow and nobody bumps into them
	if not flat:
		body.add_child(blob(size.x * PX * 0.75))
	var cylinder := CylinderShape3D.new()
	cylinder.radius = clampf(size.x * PX * 0.3, 0.12, 1.4)
	cylinder.height = 1.6
	var shape := CollisionShape3D.new()
	shape.name = "Collision"
	shape.shape = cylinder
	shape.position.y = 0.8
	shape.disabled = flat
	body.add_child(shape)
	var stem := key.get_slice("/", 1).to_lower()
	for word: String in LIGHTS:
		if word in stem:  # lanterns, lamps and torches light their surroundings
			var glow := OmniLight3D.new()
			glow.name = "Glow"
			glow.light_color = Color("ffc76a")
			glow.light_energy = 0.9
			glow.omni_range = 3.2
			glow.position = Vector3(0, size.y * PX * 0.8, 0.3)
			body.add_child(glow)
			break
	return body


## Makes a prefab show another view or model of its object: the image changes, and the shadow and
## collision follow its new width and direction.
static func _reskin(node: Node3D, key: String, dir: String, base_dir: String) -> void:
	var sprite := node.get_node_or_null("Sprite") as Sprite3D
	var tex := sized(key)
	if sprite == null or tex == null:
		return
	var ratio := tex.get_width() / maxf(sprite.texture.get_width(), 1.0)
	sprite.texture = tex
	sprite.offset = Vector2(-tex.get_width() / 2.0, sprite.offset.y)
	var shadow := node.get_node_or_null("Shadow") as Sprite3D
	if shadow:
		shadow.pixel_size *= clampf(ratio, 0.5, 1.5)
		shadow.position.z *= clampf(ratio, 0.5, 1.5)
	for shape: CollisionShape3D in node.find_children("*", "CollisionShape3D", true, false):
		if shape.shape is CylinderShape3D:
			shape.shape = shape.shape.duplicate()  # the prefab's shape is shared by all its copies
			shape.shape.radius *= clampf(ratio, 0.6, 1.3)
		elif shape.shape is BoxShape3D:
			shape.rotation.y = deg_to_rad(BOX_TURN[dir] - BOX_TURN[base_dir])


# --- images ---------------------------------------------------------------------------------------

static func _image_files(dir: String) -> PackedStringArray:
	if not DirAccess.dir_exists_absolute(dir):
		return PackedStringArray()
	var names := {}
	for file in DirAccess.get_files_at(dir):  # exported games list "x.png.import" for "x.png"
		file = file.trim_suffix(".import").trim_suffix(".remap")
		if file.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"]:
			names[file] = true
	var out := PackedStringArray(names.keys())
	out.sort()
	return out


static func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var img := Image.load_from_file(path)  # added while the game runs: not imported by Godot yet
	return ImageTexture.create_from_image(img) if img else null


static func _load_image(path: String) -> Image:
	var tex := _load_texture(path)
	if tex == null:
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	return img


static func _raw_source(key: String, path: String) -> Dictionary:
	var time := FileAccess.get_modified_time(path)
	if _raw.has(key) and _raw[key].time == time:
		return _raw[key]
	var source := adapt(_load_image(path))
	source["time"] = time
	_raw[key] = source
	return source


## A raw image made usable: its flat background removed (edges unmixed from it, so no coloured
## fringe is left), cropped to the object, and its size in game pixels worked out from the size of
## the pixel blocks it was drawn with ({"image": the cut-out, "native": its height in game pixels}).
static func adapt(source: Image) -> Dictionary:
	var img := source.duplicate() as Image
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var longest := maxi(img.get_width(), img.get_height())
	if longest > 512:  # plenty for anything the game shows, and quick to go through
		var f := 512.0 / longest
		img.resize(maxi(1, roundi(img.get_width() * f)), maxi(1, roundi(img.get_height() * f)), Image.INTERPOLATE_BILINEAR)
	var background: Variant = _cut_out(img)
	var block := _block_size(img)
	var used := img.get_used_rect()
	if used.size.x > 0 and used.size.y > 0:
		img = img.get_region(used)
	var native := img.get_height()
	if block >= 2:
		native = roundi(img.get_height() / float(block))
	elif native > 160:
		native = RAW_HEIGHT
	return {"image": img, "native": maxi(4, native), "background": background}


## Size of the blocks of equal colour a pixel-art image was enlarged with: the largest size that
## the runs of equal colour across the object are (nearly) multiples of; 0 if it doesn't look enlarged.
static func _block_size(img: Image) -> int:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var runs := PackedInt32Array()
	runs.resize(65)
	for y in range(0, h, maxi(1, h >> 6)):
		var run := 0
		for x in w:
			var i := (y * w + x) * 4
			var same := run > 0 and absi(data[i] - data[i - 4]) + absi(data[i + 1] - data[i - 3]) \
					+ absi(data[i + 2] - data[i - 2]) < 24
			if data[i + 3] < 128 or not same:  # a run ends; only runs between solid pixels count
				if run > 0 and run <= 64 and data[i + 3] >= 128:
					runs[run] += 1
				run = 1 if data[i + 3] >= 128 else 0
			else:
				run += 1
	var total := 0
	for n in range(2, 65):
		total += runs[n]
	if total < 12 or runs[1] > total:
		return 0
	for f in range(16, 1, -1):
		var fits := 0
		for n in range(maxi(2, f - 1), 65):
			var r := n % f
			if r <= 1 or r >= f - 1:
				fits += runs[n]
		if fits >= total * 0.8:
			return f
	return 0


## Turns the flat colour most of the border has into transparency (an image already cut out only
## gets its half-transparent pixels settled). Returns that colour (null if there was none).
static func _cut_out(img: Image) -> Variant:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var counts := {}
	var border := 0
	var clear := 0
	var points: Array[Vector2i] = []
	for x in range(0, w, 2):
		points.append(Vector2i(x, 0))
		points.append(Vector2i(x, h - 1))
	for y in range(0, h, 2):
		points.append(Vector2i(0, y))
		points.append(Vector2i(w - 1, y))
	for p in points:
		var i := (p.y * w + p.x) * 4
		border += 1
		if data[i + 3] < 250:
			clear += 1
			continue
		var q := (data[i] >> 4) << 8 | (data[i + 1] >> 4) << 4 | data[i + 2] >> 4
		counts[q] = counts.get(q, 0) + 1
	var bg := Color()
	var keyed := false
	if clear < border / 2 and not counts.is_empty():
		var top: int = counts.keys()[0]
		for q in counts:
			if counts[q] > counts[top]:
				top = q
		if counts[top] >= border * 0.4:
			keyed = true
			bg = Color8(((top >> 8) & 15) * 16 + 8, ((top >> 4) & 15) * 16 + 8, (top & 15) * 16 + 8)
	var br := bg.r8
	var bgg := bg.g8
	var bb := bg.b8
	for i in range(0, data.size(), 4):
		var a := data[i + 3] / 255.0
		if keyed:
			var dr := data[i] - br
			var dg := data[i + 1] - bgg
			var db := data[i + 2] - bb
			a = clampf((sqrt(dr * dr + dg * dg + db * db) - 40.0) / 60.0, 0.0, 1.0)
			if a > 0.0 and a < 1.0:  # an edge pixel: take the background's share out of its colour
				data[i] = clampi(roundi((data[i] - (1.0 - a) * br) / a), 0, 255)
				data[i + 1] = clampi(roundi((data[i + 1] - (1.0 - a) * bgg) / a), 0, 255)
				data[i + 2] = clampi(roundi((data[i + 2] - (1.0 - a) * bb) / a), 0, 255)
		if a <= 0.0:
			data[i] = 0
			data[i + 1] = 0
			data[i + 2] = 0
		data[i + 3] = roundi(a * 255.0)
	img.set_data(w, h, false, Image.FORMAT_RGBA8, data)
	return bg if keyed else null


## Pixels on the rim of a cut-out that still carry the background's colour (blurred or compressed
## images mix it into their edges) become dark outline, as the game's sprites have.
static func _defringe(img: Image, background: Color) -> void:
	var tint := Vector3(background.r, background.g, background.b)
	tint -= Vector3.ONE * (tint.x + tint.y + tint.z) / 3.0
	var plain := tint.length() < 0.1  # white, grey or black background: compare brightness instead
	var light := background.get_luminance()
	var out := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var hue := Vector3(c.r, c.g, c.b)
			hue -= Vector3.ONE * (hue.x + hue.y + hue.z) / 3.0
			var toward := 0.0 if plain or hue.length() < 0.001 else hue.normalized().dot(tint.normalized())
			if not plain and hue.length() > 0.18 and toward > 0.8:  # background seen through a gap
				out.set_pixel(x, y, Color(0, 0, 0, 0))
			elif _on_rim(img, x, y) and (absf(c.get_luminance() - light) < 0.2 if plain else hue.length() > 0.06 and toward > 0.6):
				out.set_pixel(x, y, Color(0.15, 0.1, 0.09))
	img.copy_from(out)


static func _on_rim(img: Image, x: int, y: int) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var p: Vector2i = Vector2i(x, y) + d
		if p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height() or img.get_pixelv(p).a < 0.5:
			return true
	return false


## `source` redrawn `height` pixels tall: smaller by averaging its pixels (weighted by how opaque
## they are), larger by repeating them; every pixel ends either solid or transparent, like the rest
## of the game's sprites.
static func shrink(source: Image, height: int) -> Image:
	var img := source.duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	var w := maxi(1, roundi(img.get_width() * float(height) / img.get_height()))
	if height >= img.get_height():
		img.resize(w, height, Image.INTERPOLATE_NEAREST)
		return img
	img.premultiply_alpha()
	img.resize(w, height, Image.INTERPOLATE_TRILINEAR)
	var data := img.get_data()
	for i in range(0, data.size(), 4):
		var a := data[i + 3]
		if a < 128:
			data[i] = 0
			data[i + 1] = 0
			data[i + 2] = 0
			data[i + 3] = 0
		else:
			var k := 255.0 / a
			data[i] = mini(255, roundi(data[i] * k))
			data[i + 1] = mini(255, roundi(data[i + 1] * k))
			data[i + 2] = mini(255, roundi(data[i + 2] * k))
			data[i + 3] = 255
	img.set_data(w, height, false, Image.FORMAT_RGBA8, data)
	return img
