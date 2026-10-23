extends Node3D
## Greybox test room (development only). Grey blocks measure the hero against the official scale and
## check what the controller can climb: stairs with different riser heights and ramps with different
## slopes, all rising 1.8 units toward the north. Not part of the game; open it from the editor (F6).

const RISE := 1.8      # every flight and ramp climbs to this height
const TREAD := 0.5     # depth of each step
const START_Z := 2.0   # where the climbs begin; the hero starts south of here
## [x, label, riser height] of each flight of stairs
const STAIRS := [[-9.0, "Escalón 0,2", 0.2], [-6.0, "0,3", 0.3], [-3.0, "0,45", 0.45]]
## [x, label, slope in degrees] of each ramp; the hero walks up to 50° (floor_max_angle)
const RAMPS := [[3.0, "Rampa 30°", 30.0], [6.0, "45°", 45.0], [9.0, "55°", 55.0]]

var _grey := _material(Color("8d8a85"))
var _dark := _material(Color("5d5a56"))
var _light := _material(Color("c9c5bd"))


func _ready() -> void:
	_box(Vector3(0, -0.5, 0), Vector3(30, 1, 30), _grey)  # floor
	for s in STAIRS:
		_stairs(s[0], s[2])
		_label(s[1], Vector3(s[0], 0.1, START_Z + 1.0))
	for r in RAMPS:
		_ramp(r[0], deg_to_rad(r[2]))
		_label(r[1], Vector3(r[0], 0.1, START_Z + 1.0))
	_scale_marks()


func _stairs(x: float, riser: float) -> void:
	var flight := Stairs.new()
	flight.steps = roundi(RISE / riser)
	flight.rise = RISE
	flight.tread = TREAD
	flight.width = 2.0
	flight.material = _dark
	flight.position = Vector3(x, 0, START_Z)
	add_child(flight)
	_landing(x, START_Z - TREAD * flight.steps)


func _ramp(x: float, angle: float) -> void:
	var run := RISE / tan(angle)
	var thick := 0.2
	var basis := Basis(Vector3.RIGHT, angle)  # tilts the box so it rises toward -z
	var top_middle := Vector3(x, RISE / 2.0, START_Z - run / 2.0)
	var center := top_middle - basis.y * thick / 2.0
	_box(center, Vector3(2, thick, RISE / sin(angle)), _dark, basis)
	_landing(x, START_Z - run)


func _landing(x: float, z: float) -> void:
	_box(Vector3(x, RISE / 2.0, z - 1.5), Vector3(2, RISE, 3), _light)


## Scale references: a 1-unit tape on the ground, a door frame and a pole as tall as the hero.
func _scale_marks() -> void:
	for i in 10:
		_box(Vector3(-5 + i + 0.5, 0.01, 8.5), Vector3(1, 0.02, 0.4), _dark if i % 2 else _light)
	_label("1 cuadro = 1 unidad", Vector3(0, 0.1, 9.3))
	_box(Vector3(-10.6, 1.1, 6), Vector3(0.2, 2.2, 0.2), _dark)  # door: 1.2 wide, 2.2 tall
	_box(Vector3(-9.4, 1.1, 6), Vector3(0.2, 2.2, 0.2), _dark)
	_box(Vector3(-10.0, 2.3, 6), Vector3(1.4, 0.2, 0.2), _dark)
	_label("Puerta 1,2 × 2,2", Vector3(-10, 0.1, 6.8))
	_box(Vector3(10, 1.05, 6), Vector3(0.15, 2.1, 0.15), _light)
	_label("Altura del héroe 2,1", Vector3(10, 0.1, 6.8))


func _box(center: Vector3, size: Vector3, material: Material, basis := Basis.IDENTITY) -> void:
	var body := StaticBody3D.new()
	body.transform = Transform3D(basis, center)
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = size
	mesh.material_override = material
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = size
	body.add_child(mesh)
	body.add_child(shape)
	add_child(body)


func _label(text: String, where: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.pixel_size = 0.02
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	label.outline_size = 6
	label.position = where + Vector3(0, 0.4, 0)
	add_child(label)


static func _material(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	return m
