class_name View
## Screen directions on the ground. The camera looks north (-z) from the south, so screen right is
## +x and screen down (toward the camera) is +z. Controls and sprite facings go through these
## helpers, so a different camera only has to change them.

const RIGHT := Vector3(1, 0, 0)  # screen right, on the ground
const DOWN := Vector3(0, 0, 1)   # screen down (toward the camera), on the ground


static func to_world(screen: Vector2) -> Vector3:
	return RIGHT * screen.x + DOWN * screen.y


static func to_screen(world: Vector3) -> Vector2:
	return Vector2(world.dot(RIGHT), world.dot(DOWN))
