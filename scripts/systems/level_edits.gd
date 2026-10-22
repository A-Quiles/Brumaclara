class_name LevelEdits
extends Node
## The changes made to a level with the edit mode (scripts/tools/edit_mode): objects moved, turned,
## mirrored, resized, removed, added or copied, and the paths painted on its ground. They are saved
## in data/edits/<level>.json and applied every time the level loads, so they stay in the game when
## the edit mode is switched off. The level's own scene is never rewritten.
##
## Each object has a handle: its path in the level for the ones the level comes with, "+n" for the
## added ones. Its state is {key, pos, rot, scale, flip, solid}; null when it has been removed.

const DIR := "res://data/edits/"
const ADDED := "Colocados"  ## where added objects go
## the parts of a level whose children can be edited
const CONTAINERS := ["Buildings", "Props", "Nature", "People", "Enemies", ADDED]

## file the edits are read from and saved to (default: DIR + the level's name + ".json")
@export var file := ""

var level: Node3D
var entries := {}   ## handle -> {node, kind, original, state, source, parent}
var dirty := false  ## changed since the last save
var paths_image: Image  ## the painted mask of the ground's paths, once painted

var _orphans := {"changed": [], "added": []}  # saved changes whose object is gone, kept so nothing is lost
var _count := 0
var _paths: ImageTexture
var _backed_up := false


func _ready() -> void:
	level = get_parent() as Node3D
	if file == "":
		file = DIR + level.scene_file_path.get_file().get_basename() + ".json"
	for box_name in CONTAINERS:
		var box := level.get_node_or_null(NodePath(box_name))
		if box:
			for child in box.get_children():
				if child is Node3D:
					_register(str(level.get_path_to(child)), child, true)
	load_edits.call_deferred()  # the level can't take new children while it is getting ready


func _exit_tree() -> void:
	for handle in entries:  # removed objects were only taken out of the level
		var node: Variant = entries[handle].node
		if is_instance_valid(node) and node.get_parent() == null:
			node.free()
	SpriteCatalog.clear()


# --- states ---------------------------------------------------------------------------------------

## The state of an object as it is now.
func state_of(node: Node3D) -> Dictionary:
	var sprite := node.get_node_or_null("Sprite") as SpriteBase3D
	return {
		"key": String(node.get_meta("key", "")),
		"pos": node.global_position,
		"rot": snappedf(rad_to_deg(node.rotation.y), 0.01),
		"scale": snappedf(node.scale.x, 0.01),
		"flip": sprite != null and sprite.flip_h and node.has_meta("key"),
		"solid": _solid(node),
	}


## The shapes that make an object solid (not the ones of its areas: reach, hitboxes...).
func _body_shapes(node: Node3D) -> Array[CollisionShape3D]:
	var out: Array[CollisionShape3D] = []
	for child in node.get_children():
		if child is CollisionShape3D:
			out.append(child)
	return out


func _solid(node: Node3D) -> bool:
	for shape in _body_shapes(node):
		if not shape.disabled:
			return true
	return false


## Puts object `handle` in state `st` (null removes it) and returns its node (null once removed).
func apply(handle: String, st: Variant) -> Node3D:
	var e: Dictionary = entries[handle]
	var node: Node3D = e.node if is_instance_valid(e.node) else null  # creatures can die and be gone
	dirty = true
	if st == null:
		if node and node.get_parent():
			node.get_parent().remove_child(node)  # kept aside: undoing brings it back
		e.state = null
		return null
	if e.kind == "sprite" and (node == null or st.key != node.get_meta("key", "")):
		node = _rebuild(e, st.key)
	elif node == null:
		return null
	elif node.get_parent() == null:
		e.parent.add_child(node)
	if node.has_method("place"):  # people and creatures also move the spot they stroll around
		node.place(st.pos)
	else:
		node.global_position = st.pos
	node.rotation.y = deg_to_rad(st.rot)
	if e.kind == "sprite":
		SpriteCatalog.set_size(node, st.scale)
		var sprite := node.get_node_or_null("Sprite") as SpriteBase3D
		if sprite:
			sprite.flip_h = st.flip
	elif e.kind != "actor":  # people and creatures keep their size
		node.scale = Vector3.ONE * st.scale
	if _solid(node) != st.solid:
		for shape in _body_shapes(node):
			shape.disabled = not st.solid
	e.state = st.duplicate()
	return node


## Adds an object showing image `key` in state `st`; returns its handle.
func add(key: String, st: Dictionary) -> String:
	var box := level.get_node_or_null(ADDED)
	if box == null:
		box = Node3D.new()
		box.name = ADDED
		level.add_child(box)
	var node := SpriteCatalog.build(key)
	box.add_child(node, true)
	var handle := _new_handle()
	_register(handle, node, false)
	apply(handle, st)
	return handle


## Adds a copy of object `source` in state `st`; returns its handle. Sprites are rebuilt from their
## image; buildings, people and the rest are duplicated from the original the level came with.
func copy(source: String, st: Dictionary) -> String:
	var e: Dictionary = entries[source]
	if e.kind == "sprite":
		return add(st.key, st)
	var origin: String = e.source if e.source != "" else source
	if not is_instance_valid(entries[origin].node):
		return ""
	var node: Node3D = entries[origin].node.duplicate()
	entries[origin].parent.add_child(node, true)
	var handle := _new_handle()
	_register(handle, node, false)
	entries[handle].source = origin
	apply(handle, st)
	return handle


func _new_handle() -> String:
	_count += 1
	while entries.has("+%d" % _count):
		_count += 1
	return "+%d" % _count


func _register(handle: String, node: Node3D, original: bool) -> void:
	var kind := "node"
	var sprite := node.get_node_or_null("Sprite")
	if node.has_method("set_faded"):
		kind = "building"
	elif node is CharacterBody3D:
		kind = "actor"
	elif node.has_meta("key"):
		kind = "sprite"
	elif sprite is Sprite3D and SpriteCatalog.key_of(sprite.texture) != "":
		kind = "sprite"
		node.set_meta("key", SpriteCatalog.key_of(sprite.texture))
	node.set_meta("edit_handle", handle)
	var st := state_of(node)
	entries[handle] = {"node": node, "kind": kind, "original": st.duplicate() if original else null,
			"state": st, "source": "", "parent": node.get_parent()}


func _rebuild(e: Dictionary, key: String) -> Node3D:
	var old: Node3D = e.node if is_instance_valid(e.node) else null
	var node := SpriteCatalog.build(key)
	node.set_meta("edit_handle", old.get_meta("edit_handle") if old else "")
	e.parent.add_child(node, true)
	if old:
		if old.get_parent():
			e.parent.move_child(node, old.get_index())
			old.queue_free()
		else:
			old.free()
	e.node = node
	return node


# --- saving and loading ---------------------------------------------------------------------------

func save() -> Error:
	DirAccess.make_dir_recursive_absolute(file.get_base_dir())
	if not _backed_up and FileAccess.file_exists(file):  # the first save of a session keeps the last one
		DirAccess.copy_absolute(file, file + ".bak")
	_backed_up = true
	var out := FileAccess.open(file, FileAccess.WRITE)
	if out == null:
		push_error("Can't save the level edits to %s: %s" % [file, error_string(FileAccess.get_open_error())])
		return FileAccess.get_open_error()
	out.store_string(JSON.stringify(to_doc(), "\t") + "\n")
	dirty = false
	return OK


func to_doc() -> Dictionary:
	var changed: Array = _orphans.changed.duplicate()
	var added: Array = _orphans.added.duplicate()
	for handle: String in entries:
		var e: Dictionary = entries[handle]
		if e.original != null:
			var where := {"id": handle, "at": _arr(e.original.pos), "sig": _sig(e)}
			if e.state == null:
				where["removed"] = true
				changed.append(where)
			elif not _same(e.state, e.original):
				changed.append(where.merged(_record(e.state)))
		elif e.state != null:
			var r := _record(e.state)
			if e.source != "":
				var origin: Dictionary = entries[e.source]
				r["copy_of"] = {"id": e.source, "at": _arr(origin.original.pos), "sig": _sig(origin)}
			added.append(r)
	var doc := {"version": 1, "changed": changed, "added": added}
	if paths_image:
		doc["paths"] = Marshalls.raw_to_base64(paths_image.save_png_to_buffer())
	return doc


func load_edits() -> void:
	if not FileAccess.file_exists(file):
		return
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
	if not doc is Dictionary:
		push_warning("Level edits in %s can't be read" % file)
		return
	for r: Dictionary in doc.get("added", []):  # copies first: they copy the originals as they came
		if r.has("copy_of"):
			var origin := _find(r.copy_of)
			if origin == "":
				_orphans.added.append(r)
			else:
				copy(origin, _state(r))
		elif SpriteCatalog.has_key(r.get("key", "")):
			add(r.key, _state(r))
		else:
			_orphans.added.append(r)
	for r: Dictionary in doc.get("changed", []):
		var handle := _find(r)
		if handle == "":
			_orphans.changed.append(r)
		else:
			apply(handle, null if r.get("removed", false) else _state(r))
	if doc.has("paths"):
		var img := Image.new()
		if img.load_png_from_buffer(Marshalls.base64_to_raw(doc.paths)) == OK:
			set_paths(img)
	if not (_orphans.changed.is_empty() and _orphans.added.is_empty()):
		push_warning("%d saved edits of %s no longer match anything in the level (kept in the file)"
				% [_orphans.changed.size() + _orphans.added.size(), file.get_file()])
	dirty = false


## The handle of the original object a saved record points at: by path, or else the same kind of
## object closest to where it stood (so edits survive the level being rebuilt).
func _find(r: Dictionary) -> String:
	var at := _vec(r.get("at", []))
	var handle: String = r.get("id", "")
	if entries.has(handle) and entries[handle].original != null and entries[handle].original.pos.distance_to(at) < 0.75:
		return handle
	var best := ""
	var best_d := 0.75
	for h: String in entries:
		var e: Dictionary = entries[h]
		if e.original != null and _sig(e) == r.get("sig", ""):
			var d: float = e.original.pos.distance_to(at)
			if d < best_d:
				best = h
				best_d = d
	return best


func _sig(e: Dictionary) -> String:
	if e.original != null and e.original.key != "":
		return e.original.key
	return e.node.name.rstrip("0123456789") if is_instance_valid(e.node) else ""


func _same(a: Dictionary, b: Dictionary) -> bool:
	return a.key == b.key and a.pos.distance_to(b.pos) < 0.002 and is_equal_approx(a.rot, b.rot) \
			and is_equal_approx(a.scale, b.scale) and a.flip == b.flip and a.solid == b.solid


func _record(st: Dictionary) -> Dictionary:
	var r := {"pos": _arr(st.pos), "rot": st.rot, "scale": st.scale, "flip": st.flip, "solid": st.solid}
	if st.key != "":
		r["key"] = st.key
	return r


func _state(r: Dictionary) -> Dictionary:
	return {"key": r.get("key", ""), "pos": _vec(r.get("pos", [])), "rot": float(r.get("rot", 0.0)),
			"scale": float(r.get("scale", 1.0)), "flip": bool(r.get("flip", false)), "solid": bool(r.get("solid", true))}


func _arr(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]


func _vec(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2]) if a.size() == 3 else Vector3.ZERO


# --- the ground's paths ---------------------------------------------------------------------------

## The ground's material if this level's ground has paintable paths (a TownTerrain), else null.
func ground() -> ShaderMaterial:
	var terrain := level.get_node_or_null("Ground")
	return terrain.surface if terrain is TownTerrain else null


## Where the paths mask lies on the ground (x, z, width, depth).
func paths_area() -> Rect2:
	var a: Vector4 = ground().get_shader_parameter("area")
	return Rect2(a.x, a.y, a.z, a.w)


## The paths mask, ready to paint (r cobble, g dirt, b garden soil, a forest floor).
func paint_image() -> Image:
	if paths_image == null:
		var source: Texture2D = ground().get_shader_parameter("paths")
		set_paths(source.get_image())
	return paths_image


func set_paths(img: Image) -> void:
	var material := ground()
	if material == null:
		return
	paths_image = img.duplicate()
	if paths_image.is_compressed():
		paths_image.decompress()
	paths_image.convert(Image.FORMAT_RGBA8)
	if _paths == null or _paths.get_size() != Vector2(paths_image.get_size()):
		_paths = ImageTexture.create_from_image(paths_image)
		material.set_shader_parameter("paths", _paths)
	else:
		_paths.update(paths_image)
	dirty = true


## Shows the painted mask after `paint_image()` was changed in place.
func paths_changed() -> void:
	_paths.update(paths_image)
	dirty = true
