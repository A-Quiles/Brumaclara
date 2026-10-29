extends Node
## Day and night in the outdoor levels (any scene with a "Sun" and a "WorldEnvironment"): the light
## dims and turns blue at dusk, and the lamps, lanterns, braziers and windows of the town light up,
## each one with a warm pool of light on the ground and a halo around its flame. Interiors keep their
## own lighting. N jumps to the next dusk or dawn (a few seconds of transition).
## The hour carries over between scenes (autoload) and is shown by the HUD.

signal hour_changed(hour: float)

const DAY_SECONDS := 480.0  ## a whole day, in real seconds
const DUSK := 19.0  ## hours: the light starts to go at DUSK and is gone an hour later
const DAWN := 6.0
const NIGHT_AMBIENT := Color(0.42, 0.5, 0.86)
const LAMP_WORDS := ["lamp", "lantern", "farol", "brazier", "torch", "fogata", "hoguera"]

var hour := 9.0  ## 0..24
var _skip_to := -1.0

var _scene: Node = null
var _env: Environment = null
var _sun: DirectionalLight3D = null
var _sun_energy := 0.0
var _sun_colour := Color.WHITE
var _ambient := 0.6
var _ambient_colour := Color.WHITE
var _lights: Array[Dictionary] = []  # {light, energy, range}
var _glows: Array[Node3D] = []  # pools and halos (their alpha follows the night)
var _sky: CanvasModulate = null
var _strength := 1.0  ## how much the night shows: less indoors, where candles and hearths keep it warm
var _pool_texture: GradientTexture2D
var _halo_texture: GradientTexture2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_pool_texture = _radial([Color(1.0, 0.78, 0.42, 0.55), Color(1.0, 0.62, 0.3, 0.22), Color(1.0, 0.5, 0.2, 0.0)])
	_halo_texture = _radial([Color(1.0, 0.92, 0.65, 0.9), Color(1.0, 0.72, 0.35, 0.35), Color(1.0, 0.6, 0.25, 0.0)])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("time_skip") and _env != null:
		_skip_to = DUSK + 1.2 if night() < 0.5 else DAWN + 1.2
		get_viewport().set_input_as_handled()


## 0 in full daylight, 1 in the middle of the night (smooth at dusk and dawn).
func night() -> float:
	return night_at(hour)


static func night_at(h: float) -> float:
	if h >= DUSK + 1.0 or h < DAWN - 1.0:
		return 1.0
	if h >= DUSK:
		return smoothstep(0.0, 1.0, h - DUSK)
	if h < DAWN:
		return 1.0 - smoothstep(0.0, 1.0, h - (DAWN - 1.0))
	return 0.0


## Jumps to an hour (the story's evening, tests).
func set_hour(h: float) -> void:
	hour = fposmod(h, 24.0)
	_skip_to = -1.0
	if _env:
		_apply(night() * _strength)


func outdoors() -> bool:
	return _env != null


func clock_text() -> String:
	return "%02d:%02d" % [int(hour), int(fmod(hour, 1.0) * 60.0)]


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != _scene:
		_bind(scene)
	if _env == null:
		return
	if _skip_to >= 0.0:  # a fast walk of the clock to the next dusk or dawn
		hour = fmod(hour + delta * 4.0, 24.0)
		if absf(hour - _skip_to) < delta * 4.0 + 0.01:
			_skip_to = -1.0
	else:
		hour = fmod(hour + delta * 24.0 / DAY_SECONDS, 24.0)
	hour_changed.emit(hour)
	_apply(night() * _strength)


func _apply(n: float) -> void:
	var dusk := clampf(1.0 - absf(n - 0.5) * 2.0, 0.0, 1.0)  # orange light in the middle of the change
	_env.ambient_light_energy = lerpf(_ambient, _ambient * 0.42, n)
	_env.ambient_light_color = _ambient_colour.lerp(NIGHT_AMBIENT, n).lerp(Color(1.0, 0.78, 0.6), dusk * 0.35)
	if _sun:
		_sun.light_energy = lerpf(_sun_energy, _sun_energy * 0.6, n)
		_sun.light_color = _sun_colour.lerp(Color(0.6, 0.7, 1.0), n).lerp(Color(1.0, 0.6, 0.35), dusk * 0.6)
	for l in _lights:
		var light: Light3D = l.light
		if is_instance_valid(light):
			light.light_energy = l.energy * lerpf(0.35, 2.4, n)
			if light is OmniLight3D:
				(light as OmniLight3D).omni_range = l.range * lerpf(1.0, 1.7, n)
	for g in _glows:
		if is_instance_valid(g):
			(g as SpriteBase3D).modulate.a = n * float(g.get_meta("strength", 1.0))
			g.visible = n > 0.02
	if _sky:
		_sky.color = Color.WHITE.lerp(Color(0.32, 0.36, 0.62), n).lerp(Color(1.0, 0.72, 0.55), dusk * 0.5)


## A new scene: remember its daylight and find its lamps.
func _bind(scene: Node) -> void:
	_scene = scene
	_env = null
	_sun = null
	_lights.clear()
	_glows.clear()
	_sky = null
	if scene == null:
		return
	var we := scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	_sun = scene.get_node_or_null("Sun") as DirectionalLight3D
	if we == null or _sun == null or we.environment == null:
		return  # interiors and menus: their own light
	_env = we.environment
	_strength = 0.35 if scene.scene_file_path.contains("/interiors/") else 1.0
	_ambient = _env.ambient_light_energy
	_ambient_colour = _env.ambient_light_color
	_sun_energy = _sun.light_energy
	_sun_colour = _sun.light_color
	for node in scene.find_children("*", "OmniLight3D", true, false):
		if _strength < 1.0:
			break  # indoors the hearths and candles keep their own light
		var light := node as OmniLight3D
		_lights.append({"light": light, "energy": light.light_energy, "range": light.omni_range})
		_add_glow(light.get_parent() as Node3D, light.position, light.light_color)
	for node in scene.find_children("*", "Sprite3D", true, false):
		var sprite := node as Sprite3D
		if sprite.texture == null or sprite.get_parent().find_children("*", "OmniLight3D", false, false).size() > 0:
			continue
		var path := sprite.texture.resource_path.to_lower()
		if LAMP_WORDS.any(func(w: String) -> bool: return path.get_file().contains(w)):
			_add_glow(sprite.get_parent() as Node3D, sprite.position + Vector3(0, 0.5, 0.2), Color(1.0, 0.78, 0.42))
	var backdrop := scene.get_node_or_null("Backdrop") as CanvasLayer
	if backdrop:
		_sky = CanvasModulate.new()
		backdrop.add_child(_sky)
	_apply(night() * _strength)


## A warm pool of light on the ground under `at` (local to `parent`) and a halo around the flame.
func _add_glow(parent: Node3D, at: Vector3, colour: Color) -> void:
	if parent == null:
		return
	var pool := _glow_sprite(_pool_texture, 0.09, colour)
	pool.axis = Vector3.AXIS_Y
	pool.position = Vector3(at.x, 0.06, at.z)
	pool.set_meta("strength", 0.9)
	parent.add_child(pool)
	var halo := _glow_sprite(_halo_texture, 0.03, colour)
	halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	(halo.material_override as StandardMaterial3D).billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	halo.position = at
	halo.set_meta("strength", 0.8)
	parent.add_child(halo)
	_glows.append_array([pool, halo])


func _glow_sprite(texture: Texture2D, size: float, colour: Color) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = texture
	s.pixel_size = size
	s.shaded = false
	s.double_sided = true
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	s.modulate = Color(colour.r, colour.g, colour.b, 0.0)
	var mat := StandardMaterial3D.new()  # additive: it brightens what is under it, like light
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = texture
	s.material_override = mat
	s.visible = false
	return s


static func _radial(colours: Array) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray(colours)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t
