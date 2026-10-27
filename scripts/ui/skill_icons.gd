class_name SkillIcons
## The drawn icon of every skill (data/ui/skill_icons.json): one 5 x 5 sheet of 22 px icons per
## affinity. Skills of an affinity whose sheet is not drawn yet fall back to the HUD's generic icons.

const FILE := "res://data/ui/skill_icons.json"
const SIZE := 22

static var _data: Dictionary = {}
static var _cache := {}


static func _load() -> void:
	if _data.is_empty() and FileAccess.file_exists(FILE):
		_data = JSON.parse_string(FileAccess.get_file_as_string(FILE))


static func _icon(affinity: String, index: int) -> Texture2D:
	var key := "%s/%d" % [affinity, index]
	if _cache.has(key):
		return _cache[key]
	var entry: Dictionary = _data.get(affinity, {})
	var sheet: Texture2D = load(entry.sheet) if entry.has("sheet") and ResourceLoader.exists(entry.sheet) else null
	var atlas: AtlasTexture = null
	if sheet:
		atlas = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(index % 5 * SIZE, index / 5 * SIZE, SIZE, SIZE)
	_cache[key] = atlas
	return atlas


## The icon of an active skill or ultimate (null if its affinity has no drawn sheet yet).
static func for_skill(id: StringName) -> Texture2D:
	_load()
	var affinity := str(id).get_slice(".", 0)
	var entry: Dictionary = _data.get(affinity, {})
	if not entry.get("icons", {}).has(str(id)):
		return null
	return _icon(affinity, int(entry.icons[str(id)]))


## The affinity's emblem for passives (`alt` picks the second one, for variety).
static func passive(affinity: String, alt := false) -> Texture2D:
	_load()
	var entry: Dictionary = _data.get(affinity, {})
	var key := "pasiva2" if alt and entry.has("pasiva2") else "pasiva"
	return _icon(affinity, int(entry[key])) if entry.has(key) else null
