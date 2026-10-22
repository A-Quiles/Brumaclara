extends CanvasLayer
## Developer edit mode. F1 (or F4) switches between playing and editing the current level: the game pauses,
## the camera flies free, and objects can be placed from a palette of every sprite in the asset
## folders, then selected, moved, turned (through the views drawn for each direction), mirrored,
## resized, raised, copied or removed; the paths on the ground can be painted. Every change is saved
## at once in data/edits/<level>.json, which LevelEdits applies whenever the level loads, so leaving
## the edit mode plays the level as edited. The help sheet (H) lists the keys.
##
## Development only: exported release games never have it, and it can be switched off by setting
## brumaclara/modo_edicion to false in project.godot or removing the EditMode autoload. What has
## been edited stays in the game either way.

const EditPanel := preload("res://scripts/tools/edit_mode/edit_panel.gd")
const PAN_SPEED := 14.0  # world units per second at zoom 1
const BRUSHES := [["adoquín", 0], ["tierra", 1], ["huerto", 2], ["bosque", 3]]  # name, channel of the paths mask
const MERGE := ["scale", "lift", "nudge", "turn"]  # repeated changes of these join into one undo step

var active := false
var edits: LevelEdits

var _level: Node3D
var _camera: Camera3D
var _hero: Node3D
var _cam_local := Vector3.ZERO  # the camera's place on the hero
var _cam_far := 160.0
var _cam_top := false
var _target := Vector3.ZERO  # point of the ground the camera looks at
var _zoom := 1.0
var _panel: EditPanel
var _tool := {}  # state of the object being placed, plus its "lift"; empty when not placing
var _ghost: Node3D
var _selected := ""
var _hovered := ""
var _press := {}  # the mouse drag in progress
var _undo: Array[Dictionary] = []
var _redo: Array[Dictionary] = []
var _grid := false
var _xray := false
var _painting := false
var _brush := 1
var _radius := 1.5
var _stroke: Image  # the paths before the stroke in progress
var _erase := false
var _last_mouse := Vector2.INF
var _was_paused := false


func _ready() -> void:
	if not OS.is_debug_build() or not ProjectSettings.get_setting("brumaclara/modo_edicion", true):
		queue_free()
		return
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = EditPanel.new()
	_panel.visible = false
	add_child(_panel)
	_panel.picked.connect(_on_picked)
	_panel.overlay.draw.connect(_draw_overlay)


func _exit_tree() -> void:
	SpriteCatalog.clear()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_F1, KEY_F4]:
		set_active(not active)
		get_viewport().set_input_as_handled()
		return
	if not active:
		return
	get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed:
		_key(event)
	elif event is InputEventMouseButton:
		_button(event)
	elif event is InputEventMouseMotion:
		_motion(event)


func set_active(on: bool) -> void:
	if on == active:
		return
	if on:
		_level = get_tree().current_scene as Node3D
		_camera = get_viewport().get_camera_3d()
		if _level == null or _camera == null:
			return
		edits = _level.get_node_or_null("LevelEdits") as LevelEdits
		if edits == null:  # a level made without one: it gets one now (and keeps it while it runs)
			edits = LevelEdits.new()
			edits.name = "LevelEdits"
			_level.add_child(edits)
		SpriteCatalog.scan()
		_hero = get_tree().get_first_node_in_group("player") as Node3D
		_cam_top = _camera.top_level
		_cam_local = _camera.position
		_cam_far = _camera.far
		_target = _hero.global_position if _hero else _camera.global_position - _cam_local
		_camera.top_level = true
		_camera.h_offset = 0.0
		_camera.v_offset = 0.0
		_was_paused = get_tree().paused
		get_tree().paused = true
		_set_hud(false)
		get_tree().call_group("occluder", "set_faded", false)
		_undo.clear()
		_redo.clear()
		active = true
		_panel.open(_level.name)
		_panel.say("F1: volver a jugar · H: ayuda")
	else:
		_press = {}
		_drop_tool()
		_select("")
		_set_painting(false)
		_set_xray(false)
		_camera.top_level = _cam_top
		_camera.position = _cam_local
		_camera.far = _cam_far
		_set_hud(true)
		_panel.visible = false
		active = false
		get_tree().paused = _was_paused
		if edits and edits.dirty:
			edits.save()


func _process(delta: float) -> void:
	if not active:
		return
	var mouse := _mouse()
	var pan := Vector2.ZERO
	var typing := get_viewport().gui_get_focus_owner() is LineEdit
	if not typing and not Input.is_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_META):
		pan.x = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
		pan.y = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		if _selected == "":  # with something selected the arrows move it instead
			pan.x += float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT))
			pan.y += float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP))
	if pan != Vector2.ZERO:
		_target += Vector3(pan.x, 0, pan.y).limit_length(1.0) * PAN_SPEED * _zoom * delta
		var ground: Variant = _ground_y(_target.x, _target.z)
		if ground != null:  # the view follows the hills
			_target.y = lerpf(_target.y, ground, minf(1.0, delta * 6.0))
	_camera.global_position = _target + _cam_local * _zoom
	_camera.far = _cam_far * _zoom
	var over_panel := _panel.covers(mouse)
	if mouse != _last_mouse:
		_last_mouse = mouse
		_hovered = "" if over_panel or not _tool.is_empty() or _painting or _press.has("drag") else _pick(mouse)
	if _ghost:
		var hit: Variant = null if over_panel else _ground(mouse)
		_ghost.visible = hit != null
		if hit != null:
			_ghost.global_position = _snap(hit) + Vector3(0, _tool.lift, 0)
	_panel.info(_describe())
	_panel.overlay.queue_redraw()


# --- keys and mouse -------------------------------------------------------------------------------

func _key(e: InputEventKey) -> void:
	var k := e.physical_keycode
	if e.ctrl_pressed or e.meta_pressed:
		match k:
			KEY_Z:
				_step_history(not e.shift_pressed)
			KEY_Y:
				_step_history(false)
			KEY_S:
				_save(true)
			KEY_D:
				_duplicate()
			KEY_C:
				_pipette()
			KEY_R:
				SpriteCatalog.scan()
				_panel.open(_level.name)
				_panel.say("Sprites releídos")
		return
	var repeatable := k in [KEY_Q, KEY_E, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_PAGEUP, KEY_PAGEDOWN, KEY_R]
	if e.echo and not repeatable:
		return
	var more := 5 if e.shift_pressed else 1
	match k:
		KEY_ESCAPE:
			if _painting:
				_set_painting(false)
			elif not _tool.is_empty():
				_drop_tool()
			else:
				_select("")
		KEY_H:
			_panel.toggle_help()
		KEY_TAB:
			_panel.toggle_side()
		KEY_G:
			_grid = not _grid
			_panel.say("Rejilla de 0,5 activada" if _grid else "Rejilla desactivada")
		KEY_B:
			_set_xray(not _xray)
		KEY_P:
			_set_painting(not _painting)
		KEY_T:
			_teleport_hero()
		KEY_DELETE, KEY_BACKSPACE, KEY_X:
			_delete()
		KEY_R:
			if e.alt_pressed:
				_modify("spin", -1 if e.shift_pressed else 1)
			else:
				_modify("turn", -1 if e.shift_pressed else 1)
		KEY_V:
			_modify("model", -1 if e.shift_pressed else 1)
		KEY_F:
			_modify("flip", 0)
		KEY_Q:
			_modify("scale", -1)
		KEY_E:
			_modify("scale", 1)
		KEY_0:
			_modify("scale", 0)
		KEY_C:
			_modify("solid", 0)
		KEY_PAGEUP:
			_modify("lift", more)
		KEY_PAGEDOWN:
			_modify("lift", -more)
		KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT:
			if _selected != "":
				var dir := {KEY_UP: Vector2.UP, KEY_DOWN: Vector2.DOWN, KEY_LEFT: Vector2.LEFT, KEY_RIGHT: Vector2.RIGHT}
				_modify("nudge", dir[k] * more)
		KEY_1, KEY_2, KEY_3, KEY_4:
			if _painting:
				_brush = k - KEY_1
				_panel.say("Pincel: " + BRUSHES[_brush][0])


func _button(e: InputEventMouseButton) -> void:
	if not e.pressed and e.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		_release()
		return
	if not e.pressed:
		return
	match e.button_index:
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
			var step := 1 if e.button_index == MOUSE_BUTTON_WHEEL_UP else -1
			if e.ctrl_pressed:
				_modify("scale", step)
			else:
				_zoom = clampf(_zoom * (0.9 if step > 0 else 1.1), 0.5, 3.0)
		MOUSE_BUTTON_MIDDLE:
			_press = {"pan": true, "at": e.position}
		MOUSE_BUTTON_RIGHT:
			if _painting:
				_begin_stroke(true)
			elif not _tool.is_empty():
				_drop_tool()
			else:
				_select("")
		MOUSE_BUTTON_LEFT:
			get_viewport().gui_release_focus()
			if _painting:
				_begin_stroke(false)
			elif not _tool.is_empty():
				_place()
			else:
				var handle := _pick(e.position)
				_select(handle)
				if handle == "":
					_press = {"pan": true, "at": e.position}
				else:
					var st: Dictionary = _state(handle)
					var hit: Variant = _ground(e.position)
					var under: Variant = _ground_y(st.pos.x, st.pos.z)
					_press = {"drag": handle, "at": e.position, "before": st.duplicate(), "moved": false,
							"offset": Vector3.ZERO if hit == null else Vector3(st.pos.x - hit.x, 0, st.pos.z - hit.z),
							"lift": 0.0 if under == null else st.pos.y - under}


func _motion(e: InputEventMouseMotion) -> void:
	if _press.has("pan"):
		var a := _plane_point(e.position - e.relative)
		var b := _plane_point(e.position)
		_target += Vector3(a.x - b.x, 0, a.z - b.z)
	elif _press.has("drag"):
		if not _press.moved and e.position.distance_to(_press.at) < 3.0:
			return
		_press.moved = true
		var hit: Variant = _ground(e.position)
		if hit == null:
			return
		var st: Dictionary = _state(_press.drag)
		st.pos = _on_ground(_snap(hit + _press.offset), _press.lift)
		edits.apply(_press.drag, st)
	elif _press.has("paint"):
		var hit: Variant = _ground(e.position)
		if hit != null:
			var from: Vector3 = _press.paint
			var steps := maxi(1, ceili(from.distance_to(hit) / (_radius * 0.4)))
			for i in steps:
				_paint_at(from.lerp(hit, (i + 1.0) / steps))
			_press.paint = hit


func _release() -> void:
	if _press.has("drag") and _press.moved:
		_record(_press.drag, _press.before, edits.entries[_press.drag].state, "move")
		_save()
	elif _press.has("paint"):
		_undo.append({"paths": true, "before": _stroke, "after": edits.paths_image.duplicate(), "op": "paint"})
		_redo.clear()
		_save()
	_press = {}


# --- placing --------------------------------------------------------------------------------------

func _on_picked(group: String) -> void:
	if group == "":
		_drop_tool()
		return
	_set_painting(false)
	_select("")
	var key := SpriteCatalog.default_key(group)
	if key == "":
		return
	_tool = {"key": key, "pos": Vector3.ZERO, "rot": 0.0, "scale": 1.0, "flip": false, "solid": true, "lift": 0.0}
	_refresh_ghost()


func _place() -> void:
	var hit: Variant = _ground(_mouse())
	if hit == null or _panel.covers(_mouse()):
		return
	var st := _tool.duplicate()
	st.erase("lift")
	st.pos = _snap(hit) + Vector3(0, _tool.lift, 0)
	var handle := edits.add(st.key, st)
	_record(handle, null, edits.entries[handle].state, "add")
	_save()
	_panel.say("Colocado")


func _drop_tool() -> void:
	_tool = {}
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	if _panel:
		_panel.release()


func _refresh_ghost() -> void:
	if _ghost:
		_ghost.queue_free()
		_ghost = null
	if _tool.is_empty():
		return
	_ghost = SpriteCatalog.build(_tool.key)
	for shape: CollisionShape3D in _ghost.find_children("*", "CollisionShape3D", true, false):
		shape.disabled = true
	for sprite: SpriteBase3D in _ghost.find_children("*", "SpriteBase3D", true, false):
		if sprite.name != "Shadow":
			sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
			sprite.modulate.a = 0.7
	_level.add_child(_ghost)
	SpriteCatalog.set_size(_ghost, _tool.scale)
	(_ghost.get_node("Sprite") as SpriteBase3D).flip_h = _tool.flip
	_ghost.visible = false


func _pipette() -> void:
	if _selected == "" or edits.entries[_selected].kind != "sprite":
		_panel.say("Selecciona un objeto de la paleta para usarlo")
		return
	var st: Dictionary = edits.entries[_selected].state.duplicate()
	var under: Variant = _ground_y(st.pos.x, st.pos.z)
	st["lift"] = 0.0 if under == null else st.pos.y - under
	_select("")
	_tool = st
	_refresh_ghost()
	_panel.say("Clic para colocar más")


func _duplicate() -> void:
	if _selected == "":
		return
	var st: Dictionary = edits.entries[_selected].state.duplicate()
	var under: Variant = _ground_y(st.pos.x, st.pos.z)
	var lift: float = 0.0 if under == null else st.pos.y - under
	var hit: Variant = null if _panel.covers(_mouse()) else _ground(_mouse())
	st.pos = _on_ground(_snap(hit), lift) if hit != null else st.pos + Vector3(1.0, 0, 1.0)
	var handle := edits.copy(_selected, st)
	_record(handle, null, edits.entries[handle].state, "add")
	_select(handle)
	_save()
	_panel.say("Duplicado")


func _delete() -> void:
	if _selected == "":
		return
	_change(_selected, null, "delete")
	_select("")
	_panel.say("Borrado (Ctrl+Z lo recupera)")


## Changes the selected object, or the one about to be placed.
func _modify(op: String, amount: Variant) -> void:
	if _painting and op == "scale":
		_radius = clampf(_radius + 0.5 * amount, 0.5, 6.0)
		_panel.say("Grosor del pincel: %.1f" % _radius)
		return
	if _selected == "" and _tool.is_empty():
		return
	var kind: String = "sprite" if _selected == "" else edits.entries[_selected].kind
	var st: Dictionary = _tool.duplicate() if _selected == "" else _state(_selected)
	match op:
		"turn", "model":
			if kind == "sprite":
				var view := SpriteCatalog.turn(st.key, st.flip, amount) if op == "turn" else SpriteCatalog.next_model(st.key, st.flip, amount)
				st.key = view[0]
				st.flip = view[1]
			elif kind == "building" and op == "turn":
				st.rot = wrapf(st.rot - 90.0 * amount, -180.0, 180.0)  # clockwise seen from above
			else:
				_panel.say("Esto no se puede girar")
				return
		"spin":
			if kind != "building":
				_panel.say("Solo los edificios giran libremente")
				return
			st.rot = wrapf(st.rot - 15.0 * amount, -180.0, 180.0)
		"flip":
			if kind != "sprite":
				_panel.say("Esto no tiene espejo")
				return
			st.flip = not st.flip
		"scale":
			if kind == "actor":
				_panel.say("Los personajes no cambian de tamaño")
				return
			st.scale = 1.0 if amount == 0 else clampf(snappedf(st.scale + 0.1 * amount, 0.05), 0.3, 4.0)
		"solid":
			st.solid = not st.solid
			_panel.say("Sólido" if st.solid else "Se puede atravesar")
		"lift":
			if _selected == "":
				_tool.lift += 0.05 * amount
				return
			st.pos.y += 0.05 * amount
		"nudge":
			var step := 0.5 if _grid else SpriteCatalog.PX * 2.0
			var under: Variant = _ground_y(st.pos.x, st.pos.z)
			var lift: float = 0.0 if under == null else st.pos.y - under
			st.pos = _on_ground(st.pos + Vector3(amount.x, 0, amount.y) * step, lift)
	if _selected == "":
		_tool = st
		_refresh_ghost()
	else:
		_change(_selected, st, op)


## A copy of an object's state; people and creatures are where they have walked to, not their spot.
func _state(handle: String) -> Dictionary:
	var e: Dictionary = edits.entries[handle]
	var st: Dictionary = e.state.duplicate()
	if e.kind == "actor" and is_instance_valid(e.node):
		st.pos = e.node.global_position
	return st


func _change(handle: String, st: Variant, op: String) -> void:
	var before: Variant = edits.entries[handle].state
	edits.apply(handle, st)
	_record(handle, null if before == null else before.duplicate(), st, op)
	_save()


func _record(handle: String, before: Variant, after: Variant, op: String) -> void:
	var now := Time.get_ticks_msec()
	if op in MERGE and not _undo.is_empty():
		var last: Dictionary = _undo.back()
		if last.get("handle", "") == handle and last.op == op and now - last.time < 800:
			last.after = after.duplicate() if after != null else null
			last.time = now
			return
	_undo.append({"handle": handle, "before": before, "after": after.duplicate() if after != null else null,
			"op": op, "time": now})
	if _undo.size() > 300:
		_undo.pop_front()
	_redo.clear()


## Undoes (back) or redoes the last change.
func _step_history(back: bool) -> void:
	var from := _undo if back else _redo
	if from.is_empty():
		_panel.say("Nada que deshacer" if back else "Nada que rehacer")
		return
	var act: Dictionary = from.pop_back()
	if act.has("paths"):
		edits.set_paths(act.before if back else act.after)
	else:
		edits.apply(act.handle, act.before if back else act.after)
		if _selected == act.handle and edits.entries[act.handle].state == null:
			_select("")
	(_redo if back else _undo).append(act)
	_save()
	_panel.say("Deshecho" if back else "Rehecho")


func _save(loud := false) -> void:
	var err := edits.save()
	if err != OK:
		_panel.say("No se pudo guardar (%s)" % error_string(err))
	elif loud:
		_panel.say("Guardado en " + edits.file.trim_prefix("res://"))


func _select(handle: String) -> void:
	_selected = handle


func _set_painting(on: bool) -> void:
	if on and (edits == null or edits.ground() == null):
		_panel.say("Este nivel no tiene caminos que pintar")
		return
	_painting = on
	if on:
		_drop_tool()
		_select("")
		_panel.say("Pincel de caminos: " + BRUSHES[_brush][0])


func _set_xray(on: bool) -> void:
	_xray = on
	get_tree().call_group("occluder", "set_faded", on)
	if on:
		_panel.say("Edificios transparentes: no se pueden seleccionar")


func _set_hud(shown: bool) -> void:
	if not is_instance_valid(_level):
		return
	var hud := _level.get_node_or_null("HUD") as CanvasLayer
	if hud:
		hud.visible = shown


func _teleport_hero() -> void:
	var hit: Variant = _ground(_mouse())
	if _hero and hit != null:
		_hero.global_position = hit + Vector3(0, 0.2, 0)
		_panel.say("El héroe está aquí")


# --- painting paths -------------------------------------------------------------------------------

func _begin_stroke(erase: bool) -> void:
	var hit: Variant = _ground(_mouse())
	if hit == null:
		return
	_erase = erase
	_stroke = edits.paint_image().duplicate()
	_press = {"paint": hit}
	_paint_at(hit)


func _paint_at(world: Vector3) -> void:
	var img := edits.paint_image()
	var area := edits.paths_area()
	var per_unit := img.get_width() / area.size.x
	var centre := (Vector2(world.x, world.z) - area.position) * per_unit
	var r := _radius * per_unit
	var channel: int = BRUSHES[_brush][1]
	for y in range(maxi(0, floori(centre.y - r)), mini(img.get_height(), ceili(centre.y + r) + 1)):
		for x in range(maxi(0, floori(centre.x - r)), mini(img.get_width(), ceili(centre.x + r) + 1)):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(centre) / r
			if d > 1.0:
				continue
			var f := clampf((1.0 - d) * 3.0, 0.0, 1.0)  # full inside, softer at the rim
			var px := img.get_pixel(x, y)
			for c in 4:
				px[c] = maxf(px[c], f) if c == channel and not _erase else minf(px[c], 1.0 - f)
			img.set_pixel(x, y, px)
	edits.paths_changed()


# --- the world under the mouse --------------------------------------------------------------------

func _mouse() -> Vector2:
	return get_viewport().get_mouse_position()


## The point of the ground under a point of the screen (null if none): objects being edited,
## people and invisible walls are not ground.
func _ground(screen: Vector2) -> Variant:
	var from := _camera.project_ray_origin(screen)
	return _ray(from, from + _ray_dir(screen) * 600.0)


## Direction of the camera's ray through a point of the screen. Godot's own project_ray_normal()
## ignores the frustum offset of the shifted-lens camera, so it is worked out from the frustum.
func _ray_dir(screen: Vector2) -> Vector3:
	if _camera.projection != Camera3D.PROJECTION_FRUSTUM:
		return _camera.project_ray_normal(screen)
	var view := get_viewport().get_visible_rect().size
	var wide := _camera.keep_aspect == Camera3D.KEEP_HEIGHT
	var w := _camera.size * (view.x / view.y if wide else 1.0)
	var h := _camera.size / (1.0 if wide else view.x / view.y)
	var x := (screen.x / view.x - 0.5) * w + _camera.frustum_offset.x
	var y := (0.5 - screen.y / view.y) * h + _camera.frustum_offset.y
	return (_camera.global_basis * Vector3(x, y, -_camera.near)).normalized()


func _ground_y(x: float, z: float) -> Variant:
	var hit: Variant = _ray(Vector3(x, 120.0, z), Vector3(x, -60.0, z))
	return null if hit == null else hit.y


func _on_ground(p: Vector3, lift: float) -> Vector3:
	var under: Variant = _ground_y(p.x, p.z)
	return Vector3(p.x, (p.y if under == null else under) + lift, p.z)


func _ray(from: Vector3, to: Vector3) -> Variant:
	var space := _level.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	for i in 32:
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return null
		if _is_ground(hit.collider):
			return hit.position
		query.exclude = query.exclude + [hit.rid]
	return null


func _is_ground(body: Object) -> bool:
	if not body is Node3D or body is CharacterBody3D:
		return false
	var node := body as Node
	while node and node != _level:
		if node.has_meta("edit_handle") or node == _ghost:
			return false
		node = node.get_parent()
	return not (body as Node).find_children("*", "MeshInstance3D", true, false).is_empty()


func _plane_point(screen: Vector2) -> Vector3:
	var from := _camera.project_ray_origin(screen)
	var dir := _ray_dir(screen)
	return from + dir * ((_target.y - from.y) / minf(dir.y, -0.01))


func _snap(p: Vector3) -> Vector3:
	return Vector3(snappedf(p.x, 0.5), p.y, snappedf(p.z, 0.5)) if _grid else p


## The object whose visible pixels are under a point of the screen ("" if none): sprites are tested
## pixel by pixel, buildings triangle by triangle, and the nearest one wins.
func _pick(screen: Vector2) -> String:
	var from := _camera.project_ray_origin(screen)
	var dir := _ray_dir(screen)
	var best := ""
	var best_t := INF
	for handle: String in edits.entries:
		var e: Dictionary = edits.entries[handle]
		if not is_instance_valid(e.node):
			continue
		var node: Node3D = e.node
		if not node.is_inside_tree() or not node.visible or (_xray and e.kind == "building"):
			continue
		var t := INF
		for sprite: SpriteBase3D in node.find_children("*", "SpriteBase3D", true, false):
			if sprite.visible and sprite.axis == Vector3.AXIS_Z:
				t = minf(t, _sprite_hit(sprite, from, dir))
		if e.kind == "building":
			for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
				t = minf(t, _mesh_hit(mesh, from, dir))
		if t < best_t:
			best_t = t
			best = handle
	return best


func _sprite_hit(sprite: SpriteBase3D, from: Vector3, dir: Vector3) -> float:
	var tex: Texture2D
	if sprite is Sprite3D:
		tex = sprite.texture
	elif sprite is AnimatedSprite3D and sprite.sprite_frames:
		tex = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if tex == null:
		return INF
	var xf := sprite.global_transform
	var normal := xf.basis.z.normalized()
	var facing := dir.dot(normal)
	if absf(facing) < 0.0001:
		return INF
	var t := (xf.origin - from).dot(normal) / facing
	if t <= 0.0:
		return INF
	var local := xf.affine_inverse() * (from + dir * t)
	var size := tex.get_size()
	var corner := sprite.offset - (size / 2.0 if sprite.centered else Vector2.ZERO)
	var u := local.x / sprite.pixel_size - corner.x
	var v := local.y / sprite.pixel_size - corner.y
	if u < 0.0 or v < 0.0 or u >= size.x or v >= size.y:
		return INF
	var col := int(size.x - 1.0 - u) if sprite.flip_h else int(u)
	var row := int(size.y - v)  # rows count from the top of the image
	var img := SpriteCatalog.image_of(tex)
	if img == null:
		return t
	if img.get_pixel(clampi(col, 0, img.get_width() - 1), clampi(row, 0, img.get_height() - 1)).a < 0.5:
		return INF
	return t


func _mesh_hit(mesh: MeshInstance3D, from: Vector3, dir: Vector3) -> float:
	if mesh.mesh == null or mesh.name.contains("Shadow"):
		return INF
	var inv := mesh.global_transform.affine_inverse()
	var f := inv * from
	var d := inv.basis * dir
	if mesh.mesh.get_aabb().intersects_ray(f, d) == null:
		return INF
	var faces := mesh.mesh.get_faces()
	var best := INF
	for i in range(0, faces.size(), 3):
		var p: Variant = Geometry3D.ray_intersects_triangle(f, d, faces[i], faces[i + 1], faces[i + 2])
		if p != null:
			best = minf(best, (p - f).dot(d) / d.length_squared())
	return best


# --- what the screen shows ------------------------------------------------------------------------

func _draw_overlay() -> void:
	if not active:
		return
	var canvas := _panel.overlay
	if _hovered != "" and _hovered != _selected and _alive(_hovered):
		canvas.draw_rect(_screen_rect(edits.entries[_hovered].node), Color(1, 1, 1, 0.55), false, 1.0)
	if _selected != "" and _alive(_selected):
		canvas.draw_rect(_screen_rect(edits.entries[_selected].node), EditPanel.GOLD, false, 1.0)
	if _painting and not _panel.covers(_mouse()):
		var hit: Variant = _ground(_mouse())
		if hit != null:
			var ring := PackedVector2Array()
			for i in 33:
				var a := TAU * i / 32.0
				ring.append(_camera.unproject_position(hit + Vector3(cos(a), 0, sin(a)) * _radius))
			canvas.draw_polyline(ring, Color(1, 0.4, 0.3, 0.9) if _erase and _press.has("paint") else Color(1, 1, 1, 0.8), 1.0)


func _alive(handle: String) -> bool:
	var e: Dictionary = edits.entries.get(handle, {})
	return not e.is_empty() and e.state != null and is_instance_valid(e.node) and e.node.is_inside_tree()


func _screen_rect(node: Node3D) -> Rect2:
	var box := AABB()
	var first := true
	for part: VisualInstance3D in node.find_children("*", "VisualInstance3D", true, false):
		if part is Light3D or part.name.contains("Shadow") or not part.is_visible_in_tree():
			continue
		var b: AABB = part.global_transform * part.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first:
		box = AABB(node.global_position, Vector3.ZERO)
	var rect := Rect2(_camera.unproject_position(box.position), Vector2.ZERO)
	for i in 8:
		rect = rect.expand(_camera.unproject_position(box.get_endpoint(i)))
	return rect.grow(1.0)


## A readable name for an object that is not a plain sprite: "Casa De La Brasa", "fuente", "Mara"
func _name_of(node: Node) -> String:
	var anim := node.get_node_or_null("Sprite") as AnimatedSprite3D
	if anim and anim.sprite_frames:
		var key := SpriteCatalog.key_of(load(anim.sprite_frames.resource_path.trim_suffix("_frames.tres") + ".png")) \
				if ResourceLoader.exists(anim.sprite_frames.resource_path.trim_suffix("_frames.tres") + ".png") else ""
		if key != "" and not node is CharacterBody3D:
			return SpriteCatalog.group_label(key)
	var words := ""
	for c in str(node.name).rstrip("0123456789"):
		words += (" " if c == c.to_upper() and c != c.to_lower() and words != "" else "") + c
	return words


func _describe() -> String:
	var flags := ("  · rejilla" if _grid else "") + ("  · rayos X" if _xray else "")
	if _painting:
		return "Pincel de caminos: %s · grosor %.1f · clic: pintar · clic der.: hierba · 1-4 material · Q/E grosor · P: salir%s" % [
				BRUSHES[_brush][0], _radius, flags]
	if not _tool.is_empty():
		return "Colocando %s ×%.2f · clic: colocar · R girar · V modelo · F espejo · Q/E tamaño · clic der.: soltar%s" % [
				SpriteCatalog.label(_tool.key, _tool.flip), _tool.scale, flags]
	if _selected != "" and _alive(_selected):
		var e: Dictionary = edits.entries[_selected]
		var st: Dictionary = e.state
		var what: String = SpriteCatalog.label(st.key, st.flip) if e.kind == "sprite" else _name_of(e.node)
		if e.kind == "building":
			what += " · %d°" % roundi(st.rot)
		return "%s ×%.2f · %s · (%.1f, %.1f) · arrastra para mover · R girar · Supr borrar · Ctrl+D duplicar%s" % [
				what, st.scale, "sólido" if st.solid else "atravesable", st.pos.x, st.pos.z, flags]
	return "Clic: seleccionar · elige en el panel para colocar · WASD: cámara · rueda: zoom · H: ayuda · F1: jugar" + flags
