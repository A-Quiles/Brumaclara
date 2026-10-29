extends Camera3D
## Fades what hides the hero completely, and nothing that hides only part of it:
## - buildings ("occluder" group): rays run from the camera to nine points of the hero's body (feet,
##   waist and head, each at the left edge, centre and right edge as seen from the camera); when every
##   ray is blocked by buildings, those buildings fade (see building.gd).
## - props drawn as sprites (trees, carts, animals...): one fades when its drawing's box on screen
##   holds the hero's whole box and it stands in front of the hero.
## `hidden` tells the hero to draw its silhouette on top while that happens (player.gd).

const HEIGHTS := [0.15, 1.0, 1.9]
const HALF_WIDTH := 0.35
const PROP_ALPHA := 0.4
const PROP_RANGE := 14.0  ## props farther than this from the hero are never checked
const RESCAN := 2.0  ## seconds between looks for new props (the edit mode adds some)

var hidden := false

var _faded := {}  # building -> true
var _faded_props := {}  # sprite -> its alpha cut mode before fading
var _props: Array[SpriteBase3D] = []
var _rescan := 0.0
var _tick := 0


func _physics_process(delta: float) -> void:
	var hero := get_parent() as Node3D
	if hero == null:
		return
	_fade_buildings(hero)
	_tick += 1
	_rescan -= delta
	if _rescan <= 0.0:
		_rescan = RESCAN
		_collect_props()
	if _tick % 3 == 0:
		_fade_props(hero)
	hidden = not _faded.is_empty() or not _faded_props.is_empty()


func _fade_buildings(hero: Node3D) -> void:
	var space := get_world_3d().direct_space_state
	var side := global_basis.x * HALF_WIDTH  # the camera's right, so the points span the hero on screen
	var blockers := {}
	var all_blocked := true
	for height: float in HEIGHTS:
		for k: float in [-1.0, 0.0, 1.0]:
			var target := hero.global_position + Vector3(0, height, 0) + side * k
			var query := PhysicsRayQueryParameters3D.create(global_position, target, 1)
			var blocked := false
			for i in 4:  # see through up to four layers
				var result := space.intersect_ray(query)
				if result.is_empty():
					break
				if result.collider.is_in_group("occluder"):
					blockers[result.collider] = true
					blocked = true
				query.exclude = query.exclude + [result.rid]
			all_blocked = all_blocked and blocked
	var hit := blockers if all_blocked else {}
	for node in hit:
		if not _faded.has(node):
			node.set_faded(true)
	for node in _faded:
		if not hit.has(node) and is_instance_valid(node):
			node.set_faded(false)
	_faded = hit


## The upright sprites of the level that are props (not people, monsters or parts of buildings).
func _collect_props() -> void:
	_props.clear()
	var level := get_tree().current_scene
	if level == null:
		return
	for node in level.find_children("*", "SpriteBase3D", true, false):
		var sprite := node as SpriteBase3D
		if sprite.global_basis.y.normalized().y < 0.7:  # lying on the ground: paths, shadows, rugs
			continue
		var prop := true
		var up := sprite.get_parent()
		while up and up != level:
			if up is CharacterBody3D or up.is_in_group("occluder"):
				prop = false
				break
			up = up.get_parent()
		if prop:
			_props.append(sprite)


func _fade_props(hero: Node3D) -> void:
	var side := global_basis.x * HALF_WIDTH
	var hero_box := Rect2(unproject_position(hero.global_position - side + Vector3(0, 0.1, 0)), Vector2.ZERO)
	for p: Vector3 in [hero.global_position + side, hero.global_position - side + Vector3(0, 1.9, 0),
			hero.global_position + side + Vector3(0, 1.9, 0)]:
		hero_box = hero_box.expand(unproject_position(p))
	var forward := -global_basis.z
	var hero_depth := forward.dot(hero.global_position - global_position)
	var now := {}
	for sprite in _props:
		if not is_instance_valid(sprite) or not sprite.is_visible_in_tree():
			continue
		if sprite.global_position.distance_to(hero.global_position) > PROP_RANGE:
			continue
		if forward.dot(sprite.global_position - global_position) > hero_depth - 0.2:  # level with or behind the hero
			continue
		if _screen_box(sprite).encloses(hero_box):
			now[sprite] = _faded_props.get(sprite, sprite.alpha_cut)
	for sprite: SpriteBase3D in now:
		if not _faded_props.has(sprite):
			sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
			sprite.modulate.a = PROP_ALPHA
	for sprite in _faded_props:  # (untyped: some may have been freed)
		if not now.has(sprite) and is_instance_valid(sprite):
			sprite.alpha_cut = _faded_props[sprite]
			sprite.modulate.a = 1.0
	_faded_props = now


func _screen_box(sprite: SpriteBase3D) -> Rect2:
	var box := sprite.get_aabb()
	var out := Rect2(unproject_position(sprite.global_transform * box.position), Vector2.ZERO)
	for i in range(1, 8):
		out = out.expand(unproject_position(sprite.global_transform * box.get_endpoint(i)))
	return out
