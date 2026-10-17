extends SceneTree
# One-off scaffolding: builds materials, prefabs and the village level from the fitted layout.
# Not part of the project; the generated .tres/.tscn files are the source of truth.

const LAYOUT := "res://tools/plaza_layout/layout.json"
const ENV := "res://assets/environment/"
const SPRITE_STRETCH := 1.25  # upright billboards are seen from ~37 degrees above: undo the foreshortening

# name: [texture, sprite pixel size, collision radius, shadow width]
const SPRITE_PROPS := {
	"vegetation/pine_large": [0.058, 0.4, 2.0],
	"vegetation/pine_medium": [0.069, 0.35, 1.8],
	"vegetation/pine_small": [0.083, 0.25, 1.1],
	"vegetation/bush": [0.055, 0.55, 1.3],
	"props/barrel": [0.068, 0.38, 0.9],
	"props/crate": [0.07, 0.65, 1.4],
	"props/crate_stack": [0.068, 0.75, 1.7],
	"props/barrel_blue": [0.068, 0.35, 0.8],
	"props/basket": [0.068, 0.4, 0.9],
	"props/signpost": [0.068, 0.12, 0.7],
	"props/bollard": [0.07, 0.25, 0.6],
}

var _block_mats := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if "prefabs" in args:
		_build_materials()
		_build_prefabs()
	if "level" in args:
		_load_materials()
		_build_level()
	print("built ", args)
	quit()


# --- helpers ---------------------------------------------------------------------

func _save(node: Node, path: String) -> void:
	_own(node, node)
	var packed := PackedScene.new()
	packed.pack(node)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := ResourceSaver.save(packed, path)
	assert(err == OK, path)
	node.free()


func _own(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		if child.scene_file_path.is_empty():
			_own(child, owner)


func _save_res(res: Resource, path: String) -> Resource:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	assert(ResourceSaver.save(res, path) == OK, path)
	return load(path)


func _tex(path: String) -> Texture2D:
	return load(ENV + path + ".png")


func _std(texture: Texture2D, unshaded := false, triplanar_scale := Vector3.ZERO, cull := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = texture
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 1.0
	m.metallic_specular = 0.0
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if triplanar_scale != Vector3.ZERO:
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = triplanar_scale
	if not cull:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if texture and texture.get_image() and texture.get_image().detect_alpha() != Image.ALPHA_NONE:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	return m


func _box_mesh() -> BoxMesh:
	if ResourceLoader.exists("res://materials/blocks/unit_box.tres"):
		return load("res://materials/blocks/unit_box.tres")
	return _save_res(BoxMesh.new(), "res://materials/blocks/unit_box.tres")


func _block_node(node_name: String, size: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = _box_mesh()
	mi.scale = size
	mi.position = Vector3(0, size.y / 2.0, 0)
	mi.material_override = material
	return mi


func _shape(node_name: String, shape: Shape3D, pos := Vector3.ZERO) -> CollisionShape3D:
	var col := CollisionShape3D.new()
	col.name = node_name
	col.shape = shape
	col.position = pos
	return col


func _box_shape(size: Vector3) -> BoxShape3D:
	var s := BoxShape3D.new()
	s.size = size
	return s


func _cyl_shape(radius: float, height: float) -> CylinderShape3D:
	var s := CylinderShape3D.new()
	s.radius = radius
	s.height = height
	return s


func _blob(width: float) -> Sprite3D:
	var blob := Sprite3D.new()
	blob.name = "Shadow"
	blob.texture = _tex("textures/blob_shadow")
	blob.pixel_size = width / 16.0
	blob.axis = Vector3.AXIS_Y
	blob.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	blob.position = Vector3(0.12, 0.02, 0.05)
	return blob


func _billboard(texture: Texture2D, pixel_size: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.name = "Sprite"
	s.texture = texture
	s.pixel_size = pixel_size
	s.centered = false
	s.offset = Vector2(-texture.get_width() / 2.0, 0)
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED  # transparent: kept out of the outline pass
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.scale = Vector3(1, SPRITE_STRETCH, 1)
	return s


# --- materials -----------------------------------------------------------------

# name: [top texture, side texture, top tile size, side tile size, top in local coords, tint]
const BLOCK_MATERIALS := {
	"paving": ["paving", "stone_wall", Vector2(4, 4), Vector2(4, 2), false, 1.0],
	"paving_local": ["paving", "stone_wall", Vector2(4, 4), Vector2(4, 2), true, 1.0],
	"grass": ["grass", "stone_wall", Vector2(4, 4), Vector2(4, 2), false, 1.0],
	"grass_dark": ["grass_dark", "stone_wall", Vector2(4, 4), Vector2(4, 2), false, 1.0],
	"path": ["path", "stone_wall", Vector2(4, 4), Vector2(4, 2), true, 1.0],
	"stone_top": ["stone_top", "stone_wall", Vector2(2, 2), Vector2(4, 2), false, 1.0],
	"fountain": ["fountain_top", "fountain_stone", Vector2(2, 2), Vector2(2, 0.5), false, 1.0],
}


func _build_materials() -> void:
	var shader := load("res://shaders/terrain_block.gdshader")
	for key in BLOCK_MATERIALS:
		var d: Array = BLOCK_MATERIALS[key]
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("top_texture", _tex("textures/" + d[0]))
		m.set_shader_parameter("side_texture", _tex("textures/" + d[1]))
		m.set_shader_parameter("top_size", d[2])
		m.set_shader_parameter("side_size", d[3])
		m.set_shader_parameter("top_local", d[4])
		m.set_shader_parameter("tint", Color(d[5], d[5], d[5]))
		_save_res(m, "res://materials/blocks/%s.tres" % key)
	_save_res(_std(_tex("textures/wood_planks"), false, Vector3(0.5, 0.5, 0.5)), "res://materials/wood.tres")
	_save_res(_std(_tex("textures/backdrop"), true), "res://materials/backdrop.tres")
	for kind in ["rainbow", "green", "purple"]:
		_save_res(_std(_tex("textures/awning_" + kind), false, Vector3.ZERO, false), "res://materials/awning_%s.tres" % kind)
	var water := ShaderMaterial.new()
	water.shader = load("res://shaders/scrolling_water.gdshader")
	water.set_shader_parameter("water_texture", _tex("textures/water"))
	water.set_shader_parameter("flow", Vector2(0.03, 0.06))
	water.set_shader_parameter("tiling", Vector2(2, 2))
	_save_res(water, "res://materials/water.tres")


func _load_materials() -> void:
	for key in BLOCK_MATERIALS:
		_block_mats[key] = load("res://materials/blocks/%s.tres" % key)


# --- prefabs -----------------------------------------------------------------------

func _build_prefabs() -> void:
	_load_materials()
	for key in SPRITE_PROPS:
		var d: Array = SPRITE_PROPS[key]
		var body := StaticBody3D.new()
		body.name = key.get_file().to_pascal_case()
		body.add_child(_billboard(_tex(key), d[0]))
		body.add_child(_blob(d[2]))
		body.add_child(_shape("Collision", _cyl_shape(d[1], 1.0), Vector3(0, 0.5, 0)))
		_save(body, "res://scenes/environment/%s.tscn" % key)
	_build_villager()
	_build_player()
	_build_fountain()
	_build_stall("rainbow", 2.2, 1.4)
	_build_stall("green", 2.0, 1.4)
	_build_kiosk()
	_build_hud()


func _build_villager() -> void:
	var body := StaticBody3D.new()
	body.name = "Villager"
	body.set_script(load("res://scripts/characters/villager.gd"))
	var sprite := AnimatedSprite3D.new()
	sprite.name = "Sprite"
	sprite.centered = false
	sprite.offset = Vector2(-9, 0)
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED  # transparent: kept out of the outline pass
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.scale = Vector3(1, SPRITE_STRETCH, 1)
	body.add_child(sprite)
	body.add_child(_blob(1.0))
	body.add_child(_shape("Collision", _cyl_shape(0.35, 1.6), Vector3(0, 0.8, 0)))
	_save(body, "res://scenes/characters/villager.tscn")


func _build_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.set_script(load("res://scripts/characters/player.gd"))
	player.floor_max_angle = deg_to_rad(50)
	player.floor_snap_length = 0.4
	var sprite := AnimatedSprite3D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = load("res://assets/characters/hero/hero_frames.tres")
	sprite.animation = &"idle_down"
	sprite.pixel_size = 1.0 / 16.0
	sprite.centered = false
	sprite.offset = Vector2(-12, -1)
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED  # transparent: kept out of the outline pass
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.scale = Vector3(1, SPRITE_STRETCH, 1)
	player.add_child(sprite)
	player.add_child(_blob(1.1))
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.4
	player.add_child(_shape("Collision", capsule, Vector3(0, 0.7, 0)))
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.fov = 26.0
	camera.near = 1.0
	camera.far = 150.0
	camera.position = Vector3(0, 21.446, 28.052)
	camera.rotation_degrees = Vector3(-30, 0, 0)
	player.add_child(camera)
	var outline_mat := ShaderMaterial.new()
	outline_mat.shader = load("res://shaders/outline.gdshader")
	outline_mat.render_priority = -10  # before the sprites, so they cover the lines
	var outline := _quad("Outline", Vector2(1, 1), outline_mat)
	outline.layers = 2  # the minimap camera skips this layer
	outline.extra_cull_margin = 16384.0
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	outline.position = Vector3(0, 0, -2)
	camera.add_child(outline)
	_save(player, "res://scenes/characters/player.tscn")


func _quad(node_name: String, size: Vector2, mat: Material) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = size
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = q
	mi.material_override = mat
	return mi


func _build_fountain() -> void:
	var root := StaticBody3D.new()
	root.name = "Fountain"
	# octagonal basin from eight stone blocks; block 0 faces the camera
	var apothem := 1.78
	var thick := 0.18
	var rim_h := 0.6
	var side := 2.0 * apothem * tan(PI / 8.0)
	for i in 8:
		var piece := Node3D.new()
		piece.name = "Rim%d" % i
		piece.rotation.y = i * PI / 4.0
		var block := _block_node("Stone", Vector3(side, rim_h, thick), _block_mats["fountain"])
		block.position.z = apothem - thick / 2.0
		piece.add_child(block)
		root.add_child(piece)
	var surface := MeshInstance3D.new()
	surface.name = "Water"
	var disc := CylinderMesh.new()
	disc.top_radius = (apothem - thick) / cos(PI / 8.0)
	disc.bottom_radius = disc.top_radius
	disc.height = 0.02
	disc.radial_segments = 8
	disc.rings = 1
	surface.mesh = disc
	surface.material_override = load("res://materials/water.tres")
	surface.rotation.y = PI / 8.0
	surface.position.y = 0.5
	root.add_child(surface)
	# the stone tiers and their falling water are one painted billboard, 1:1 at the plaza's depth;
	# it stands a little in front of the centre so the basin water hides only its foam line
	var sheet := _tex("props/fountain_spray")
	var frames := SpriteFrames.new()
	frames.set_animation_speed(&"default", 6.0)
	for f in 3:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(f * 30, 0, 30, sheet.get_height())
		frames.add_frame(&"default", atlas)
	var spray := AnimatedSprite3D.new()
	spray.name = "Spray"
	spray.sprite_frames = frames
	spray.autoplay = "default"
	spray.pixel_size = 0.0722
	spray.centered = false
	spray.offset = Vector2(-15, 0)
	spray.position = Vector3(0, 0.335, 0.4)
	spray.scale = Vector3(1, 1.08, 1)  # ponytail: placement tuned for the pitched camera of this prototype
	spray.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spray.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spray.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED  # transparent: kept out of the outline pass
	spray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(spray)
	root.add_child(_shape("Collision", _cyl_shape(apothem, 1.0), Vector3(0, 0.5, 0)))
	_save(root, "res://scenes/environment/fountain.tscn")


func _build_stall(kind: String, width: float, depth: float) -> void:
	var wood: Material = load("res://materials/wood.tres")
	var root := StaticBody3D.new()
	root.name = "MarketStall" + kind.capitalize()
	for p in [[-1, -1, 2.1], [1, -1, 2.1], [-1, 1, 1.75], [1, 1, 1.75]]:
		var post := _block_node("Post", Vector3(0.12, p[2], 0.12), wood)
		post.material_override = wood
		post.position = Vector3(p[0] * (width / 2.0 - 0.08), p[2] / 2.0, p[1] * (depth / 2.0 - 0.08))
		root.add_child(post)
	var counter := _block_node("Counter", Vector3(width - 0.1, 0.8, 0.5), wood)
	counter.position = Vector3(0, 0.4, depth / 2.0 - 0.3)
	root.add_child(counter)
	var awning := _quad("Awning", Vector2(width + 0.3, depth + 0.6), load("res://materials/awning_%s.tres" % kind))
	var slope := atan2(0.45, depth + 0.4)
	awning.rotation = Vector3(-PI / 2.0 + slope, 0, 0)
	awning.position = Vector3(0, 1.95, 0.15)
	root.add_child(awning)
	var valance := _quad("Valance", Vector2(width + 0.3, 0.3), load("res://materials/awning_%s.tres" % kind))
	valance.position = Vector3(0, 1.6, depth / 2.0 + 0.45)
	root.add_child(valance)
	var produce := _billboard(_tex("props/produce"), 0.07)
	produce.name = "Produce"
	produce.position = Vector3(-0.3, 0.8, depth / 2.0 - 0.3)
	root.add_child(produce)
	root.add_child(_shape("Collision", _box_shape(Vector3(width, 1.0, depth)), Vector3(0, 0.5, 0)))
	_save(root, "res://scenes/environment/market_stall_%s.tscn" % kind)


func _build_kiosk() -> void:
	var wood: Material = load("res://materials/wood.tres")
	var roof := _std(load("res://assets/environment/houses/HouseBlueRoof/roof.png"), false, Vector3.ZERO, false)
	var root := StaticBody3D.new()
	root.name = "Kiosk"
	var w := 1.7
	var d := 1.3
	for p in [[-1, -1], [1, -1], [-1, 1], [1, 1]]:
		var post := _block_node("Post", Vector3(0.12, 1.9, 0.12), wood)
		post.position = Vector3(p[0] * (w / 2.0 - 0.08), 0.95, p[1] * (d / 2.0 - 0.08))
		root.add_child(post)
	var back := _block_node("BackWall", Vector3(w, 1.9, 0.1), wood)
	back.position = Vector3(0, 0.95, -d / 2.0 + 0.05)
	root.add_child(back)
	var counter := _block_node("Counter", Vector3(w, 0.85, 0.4), wood)
	counter.position = Vector3(0, 0.425, d / 2.0 - 0.2)
	root.add_child(counter)
	var top := _quad("Roof", Vector2(w + 0.4, d + 0.5), roof)
	top.rotation = Vector3(-PI / 2.0 + atan2(0.5, d + 0.4), 0, 0)
	top.position = Vector3(0, 2.15, 0.1)
	root.add_child(top)
	root.add_child(_shape("Collision", _box_shape(Vector3(w, 1.0, d)), Vector3(0, 0.5, 0)))
	_save(root, "res://scenes/environment/kiosk.tscn")


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	var settings := LabelSettings.new()
	settings.font = load("res://assets/fonts/pixelify_sans_medium.woff")
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = 0
	settings.shadow_size = 1
	settings.shadow_color = Color(0, 0, 0, 0.8)
	settings.shadow_offset = Vector2(1, 1)
	l.label_settings = settings
	return l


func _rect(node_name: String, texture_path: String, pos: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.name = node_name
	r.texture = load(texture_path)
	r.position = pos
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(load("res://scripts/ui/hud.gd"))
	var panel := _rect("HealthPanel", "res://assets/ui/hp_panel.png", Vector2(5, 5))
	hud.add_child(panel)
	for b in [["HPBar", "hp_fill", 5, 100.0], ["MPBar", "mp_fill", 15, 72.0]]:
		var bar := TextureProgressBar.new()
		bar.name = b[0]
		bar.texture_progress = load("res://assets/ui/%s.png" % b[1])
		bar.position = Vector2(23, b[2])
		bar.max_value = 100
		bar.value = b[3]
		panel.add_child(bar)
	var minimap := Control.new()
	minimap.name = "Minimap"
	minimap.position = Vector2(407, 3)
	minimap.size = Vector2(68, 58)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(minimap)
	var container := SubViewportContainer.new()
	container.name = "MapContainer"
	container.unique_name_in_owner = true
	container.position = Vector2(3, 3)
	container.size = Vector2(62, 52)
	container.stretch = true
	minimap.add_child(container)
	var view := SubViewport.new()
	view.name = "MapViewport"
	view.unique_name_in_owner = true
	view.size = Vector2i(62, 52)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(view)
	var cam := Camera3D.new()
	cam.name = "MapCamera"
	cam.unique_name_in_owner = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 40.0
	cam.near = 1.0
	cam.far = 120.0
	cam.rotation_degrees = Vector3(-90, 0, 0)
	cam.position = Vector3(0, 60, -7)
	cam.cull_mask = 1
	cam.current = true
	var map_env := Environment.new()  # flat, slightly muted look like a painted map
	map_env.background_mode = Environment.BG_COLOR
	map_env.background_color = Color("#5d8f4c")
	map_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	map_env.ambient_light_color = Color.WHITE
	map_env.ambient_light_energy = 0.7
	map_env.adjustment_enabled = true
	map_env.adjustment_saturation = 0.8
	cam.environment = map_env
	view.add_child(cam)
	var marker := _rect("PlayerMarker", "res://assets/ui/player_marker.png", Vector2(30, 24))
	marker.unique_name_in_owner = true
	minimap.add_child(marker)
	minimap.add_child(_rect("Frame", "res://assets/ui/minimap_frame.png", Vector2.ZERO))
	var bar_bg := ColorRect.new()
	bar_bg.name = "MessageBar"
	bar_bg.color = Color(0.02, 0.03, 0.05, 0.62)
	bar_bg.position = Vector2(0, 255)
	bar_bg.size = Vector2(480, 15)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(bar_bg)
	bar_bg.add_child(_rect("Arrow", "res://assets/ui/prompt_arrow.png", Vector2(5, 4)))
	var msg := _label("¡Bienvenido a Brumaclara! Explora la plaza del pueblo.", 13, Color("f2f2f2"))
	msg.name = "Message"
	msg.unique_name_in_owner = true
	msg.position = Vector2(13, -2)
	bar_bg.add_child(msg)
	bar_bg.add_child(_rect("KeyY", "res://assets/ui/key_y.png", Vector2(362, 2)))
	var ly := _label("Menú", 13, Color("f2f2f2"))
	ly.name = "MenuLabel"
	ly.position = Vector2(376, -2)
	bar_bg.add_child(ly)
	bar_bg.add_child(_rect("KeyX", "res://assets/ui/key_x.png", Vector2(418, 2)))
	var lx := _label("Mapa", 13, Color("f2f2f2"))
	lx.name = "MapLabel"
	lx.position = Vector2(432, -2)
	bar_bg.add_child(lx)
	_save(hud, "res://scenes/ui/hud.tscn")


# --- level -------------------------------------------------------------------------

func _yaw(deg: float) -> float:
	return deg_to_rad(deg)


func _add_block(parent: Node, o: Dictionary) -> void:
	var size := Vector3(o.size[0], o.size[1], o.size[2])
	var body := StaticBody3D.new()
	body.name = o.name
	body.position = Vector3(o.pos[0], o.pos[1], o.pos[2])
	body.rotation.y = _yaw(o.yaw)
	var key: String = o.top
	if key == "paving" and absf(o.yaw) > 0.1:
		key = "paving_local"
	body.add_child(_block_node("Mesh", size, _block_mats[key]))
	body.add_child(_shape("Collision", _box_shape(size), Vector3(0, size.y / 2.0, 0)))
	parent.add_child(body)


func _house_textures(house_name: String) -> Dictionary:
	var out := {}
	var dir := "res://assets/environment/houses/%s/" % house_name
	for part in ["front", "side", "roof", "gable", "dormer_front", "dormer_side", "dormer_gable", "dormer_roof"]:
		if ResourceLoader.exists(dir + part + ".png"):
			out[part] = load(dir + part + ".png")
	return out


func _house_mesh(node_name: String, size: Vector3, roof_h: float, along_x: bool, overhang: float,
		front: Texture2D, side: Texture2D, gable: Texture2D, roof: Texture2D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.set_script(load("res://scripts/environment/house_mesh.gd"))
	mi.front_texture = front
	mi.back_texture = side
	mi.left_texture = side
	mi.right_texture = side
	mi.gable_texture = gable
	mi.roof_texture = roof
	mi.size = size
	mi.ridge_along_x = along_x
	mi.roof_height = roof_h
	mi.overhang = overhang
	return mi


func _add_house(parent: Node, o: Dictionary) -> void:
	var tex := _house_textures(o.name)
	var size := Vector3(o.size[0], o.size[1], o.size[2])
	var body := StaticBody3D.new()
	body.name = o.name
	body.position = Vector3(o.pos[0], o.pos[1], o.pos[2])
	body.rotation.y = _yaw(o.yaw)
	var along_x: bool = o.ridge_along_x
	var roof_h: float = o.roof_h
	body.add_child(_house_mesh("Shell", size, roof_h, along_x, o.overhang,
			tex.front, tex.side, tex.get("gable"), tex.roof))
	body.add_child(_shape("Collision", _box_shape(size), Vector3(0, size.y / 2.0, 0)))
	if o.chimney:
		var ch: Dictionary = o.chimney
		var chim := _block_node("Chimney", Vector3(ch.size[0], ch.size[1] + roof_h, ch.size[2]), _block_mats["stone_top"])
		chim.position = Vector3(ch.pos[0], size.y + (ch.size[1] + roof_h) / 2.0, ch.pos[2])
		body.add_child(chim)
	if o.name == "HouseCornerBlue":
		(body.get_node("Shell") as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if o.roof == "flat":
		var cap := _block_node("StoneCap", Vector3(size.x * 0.62, 0.55, size.z * 0.5), _block_mats["stone_top"])
		cap.position = Vector3(-size.x * 0.1, size.y + 0.275, -size.z * 0.14)
		body.add_child(cap)
		var awning := _quad("Awning", Vector2(1.5, 0.9), load("res://materials/awning_purple.tres"))
		awning.rotation = Vector3(0, PI / 2.0, 0)
		awning.rotate_object_local(Vector3.RIGHT, -0.6)
		awning.position = Vector3(size.x / 2.0 + 0.35, 3.4, -1.3)
		body.add_child(awning)
	var big: bool = o.get("dormers").size() > 0 and o.name == "HouseBottomRight"
	var dsize := Vector3(2.0, 1.3, 2.2) if big else Vector3(1.3, 0.75, 1.6)
	var droof := 1.0 if big else 0.55
	var half := size.z / 2.0
	for dm in o.dormers:
		var z_front := half * (0.75 if big else 0.72)
		var y_slope := size.y + roof_h - roof_h * z_front / half
		var dormer := _house_mesh("Dormer", dsize, droof, false, 0.12, tex.dormer_front, tex.dormer_side,
				tex.dormer_gable, tex.dormer_roof)
		dormer.position = Vector3(dm.x, y_slope - 0.12, z_front - dsize.z / 2.0)
		body.add_child(dormer)
	parent.add_child(body)


func _add_stairs(parent: Node, o: Dictionary) -> void:
	var root := Node3D.new()
	root.name = o.name
	root.position = Vector3(o.pos[0], o.pos[1], o.pos[2])
	root.rotation.y = _yaw(o.yaw)
	var steps: int = o.steps
	var rise: float = o.rise
	var run: float = o.run
	var width: float = o.width
	for i in steps:
		var h := rise * (i + 1) / steps
		var step := _block_node("Step%d" % i, Vector3(width, h, run / steps), _block_mats["stone_top"])
		step.position = Vector3(0, h / 2.0, -run * (i + 0.5) / steps)
		root.add_child(step)
	for side in [-1, 1]:
		var wall := _block_node("Side" + ("L" if side < 0 else "R"), Vector3(0.3, rise + 0.35, run), _block_mats["stone_top"])
		wall.position = Vector3(side * (width / 2.0 + 0.15), (rise + 0.35) / 2.0, -run / 2.0)
		root.add_child(wall)
	var ramp := StaticBody3D.new()
	ramp.name = "Ramp"
	var length := sqrt(run * run + rise * rise)
	var col := _shape("Collision", _box_shape(Vector3(width, 0.2, length)))
	col.rotation.x = atan2(rise, run)
	col.position = Vector3(0, rise / 2.0 - 0.1, -run / 2.0)
	ramp.add_child(col)
	root.add_child(ramp)
	parent.add_child(root)


func _instance(parent: Node, path: String, node_name: String, pos: Vector3, yaw := 0.0) -> Node3D:
	var node: Node3D = load(path).instantiate()
	node.position = pos
	node.rotation.y = _yaw(yaw)
	var n := 1
	var base := node_name
	while parent.has_node(NodePath(node_name)):
		n += 1
		node_name = "%s%d" % [base, n]
	node.name = node_name
	parent.add_child(node)
	return node


const TREE_SCENES := {"pine": "vegetation/pine_large", "pine_mid": "vegetation/pine_medium",
		"pine_small": "vegetation/pine_small", "bush": "vegetation/bush"}
const VILLAGER_HEIGHTS := {"boy": 1.6, "oldman": 1.45, "woman_purple": 1.6, "woman_lilac": 1.5, "merchant": 1.5,
		"girl_orange": 1.75, "knight": 1.9, "guard": 1.6, "girl_brown": 1.4, "girl_red": 1.6, "boy_blue": 1.65,
		"kid_a": 1.6, "kid_b": 1.6, "vendor": 1.55}


func _build_level() -> void:
	var layout: Array = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	var root := Node3D.new()
	root.name = "Village"

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#5fb8ec")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	root.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-49, -32.5, 0)
	sun.light_energy = 0.105  # measured: tops ~1.0, fronts ~0.9, unlit sides ~0.6 of the texture colour
	sun.shadow_enabled = true
	sun.shadow_bias = 0.05
	sun.shadow_normal_bias = 1.0
	sun.directional_shadow_max_distance = 70.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	root.add_child(sun)

	var groups := {}
	for g in ["Terrain", "Buildings", "Plaza", "Vegetation", "Props", "Villagers"]:
		var n := Node3D.new()
		n.name = g
		root.add_child(n)
		groups[g] = n

	for o in layout:
		match o.type:
			"block":
				_add_block(groups.Terrain, o)
			"house":
				_add_house(groups.Buildings, o)
			"stairs":
				_add_stairs(groups.Terrain, o)
			"fountain":
				_instance(groups.Plaza, "res://scenes/environment/fountain.tscn", "Fountain", Vector3(o.pos[0], o.pos[1], o.pos[2]))
			"stall":
				_instance(groups.Plaza, "res://scenes/environment/market_stall_%s.tscn" % o.awning, o.name, Vector3(o.pos[0], o.pos[1], o.pos[2]))
			"kiosk":
				_instance(groups.Plaza, "res://scenes/environment/kiosk.tscn", o.name, Vector3(o.pos[0], o.pos[1], o.pos[2]))
			"tree":
				_instance(groups.Vegetation, "res://scenes/environment/%s.tscn" % TREE_SCENES[o.kind], o.name, Vector3(o.pos[0], o.pos[1], o.pos[2]))
			"prop":
				if o.kind == "dirt":
					var patch := Sprite3D.new()
					patch.name = "DirtPatch"
					patch.texture = _tex("textures/dirt")
					patch.pixel_size = 1.0 / 12.0
					patch.axis = Vector3.AXIS_Y
					patch.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					patch.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
					patch.position = Vector3(o.pos[0], o.pos[1] + 0.015, o.pos[2])
					var n := 1
					while groups.Props.has_node("DirtPatch%d" % n):
						n += 1
					patch.name = "DirtPatch%d" % n
					groups.Props.add_child(patch)
				else:
					_instance(groups.Props, "res://scenes/environment/props/%s.tscn" % o.kind, o.name, Vector3(o.pos[0], o.pos[1], o.pos[2]))
			"npc":
				var v := _instance(groups.Villagers, "res://scenes/characters/villager.tscn", o.name, Vector3(o.pos[0], o.pos[1], o.pos[2]))
				v.sheet = load("res://assets/characters/villagers/%s.png" % o.kind)
				v.height = VILLAGER_HEIGHTS[o.kind]
				v.phase = fposmod(o.pos[0] * 0.37 + o.pos[2] * 0.11, 1.0)
			"plaza_border":
				var plane := PlaneMesh.new()
				plane.size = Vector2(o.size[0], o.size[1])
				var band := MeshInstance3D.new()
				band.name = "PlazaBorder"
				band.mesh = plane
				band.material_override = _std(_tex("textures/plaza_border"))
				band.position = Vector3(o.pos[0], o.pos[1] + 0.006, o.pos[2])
				band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				groups.Plaza.add_child(band)

	var backdrop := _quad("Backdrop", Vector2(84, 16), load("res://materials/backdrop.tres"))
	backdrop.position = Vector3(0, 2.0, -21.0)
	backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(backdrop)

	_instance(root, "res://scenes/characters/player.tscn", "Player", Vector3.ZERO)
	var hud_node: CanvasLayer = load("res://scenes/ui/hud.tscn").instantiate()
	hud_node.name = "HUD"
	root.add_child(hud_node)
	hud_node.player_path = NodePath("../Player")

	_own(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	DirAccess.make_dir_recursive_absolute("res://scenes/levels")
	assert(ResourceSaver.save(packed, "res://scenes/levels/village.tscn") == OK)
	root.free()
