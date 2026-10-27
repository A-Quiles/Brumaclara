class_name Affinity
## The six magic affinities (docs/arbol_habilidades.md): names, their status, colour and the art of
## their effects. Effects are drawn once for fire; the other affinities use the repainted copies that
## tools/art_pipeline/build.py (affinity_fx) leaves next to each original, in an affinity/ folder.

const ALL: Array[StringName] = [&"fuego", &"hielo", &"rayo", &"sombra", &"tierra", &"luz"]
const NAMES := {&"fuego": "Fuego", &"hielo": "Hielo", &"rayo": "Rayo", &"sombra": "Sombra",
		&"tierra": "Tierra", &"luz": "Luz"}
const ROLES := {&"fuego": "Presión y daño", &"hielo": "Control y supervivencia",
		&"rayo": "Velocidad y cadenas", &"sombra": "Engaño y debilitación",
		&"tierra": "Peso, defensa y terreno", &"luz": "Protección, curación y revelación"}
## the status each affinity applies with its own skills
const STATUS := {&"fuego": &"quemadura", &"hielo": &"frio", &"rayo": &"marca_electrica",
		&"sombra": &"marca_sombra", &"tierra": &"fisura", &"luz": &"deslumbrado"}
const COLORS := {&"fuego": Color("ff8a1c"), &"hielo": Color("8fd8ff"), &"rayo": Color("b4b8ff"),
		&"sombra": Color("a87ae0"), &"tierra": Color("c09060"), &"luz": Color("ffe880"), &"": Color("f4e9c8")}

static var _frames_cache := {}


## The affinity's version of a fire texture (the same texture for fire or no affinity).
static func texture(base: Texture2D, affinity: StringName) -> Texture2D:
	if affinity == &"" or affinity == &"fuego" or base == null:
		return base
	var path := base.resource_path.get_base_dir().path_join("affinity/%s_%s" % [affinity, base.resource_path.get_file()])
	return load(path) if ResourceLoader.exists(path) else base


## A copy of fire sprite frames drawing with the affinity's textures.
static func frames(base: SpriteFrames, affinity: StringName) -> SpriteFrames:
	if affinity == &"" or affinity == &"fuego":
		return base
	var key := "%s|%s" % [base.get_instance_id(), affinity]
	if _frames_cache.has(key):
		return _frames_cache[key]
	var out := base.duplicate(true) as SpriteFrames
	for anim in out.get_animation_names():
		for i in out.get_frame_count(anim):
			var atlas := out.get_frame_texture(anim, i) as AtlasTexture
			if atlas:
				atlas.atlas = texture(atlas.atlas, affinity)
	_frames_cache[key] = out
	return out


static func color(affinity: StringName) -> Color:
	return COLORS.get(affinity, COLORS[&""])
