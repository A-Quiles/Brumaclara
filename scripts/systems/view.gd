class_name View
## The game's fixed camera: orthographic, looking down at 45 degrees from a diagonal (yaw 45), so
## buildings show their front and one side. Controls and facings are screen-relative; these helpers
## turn screen directions (x right, y down) into ground directions and back.

const YAW := PI / 4.0
const PITCH := PI / 4.0
const DISTANCE := 40.0
## sprites stand upright and turn to face the camera; this vertical stretch undoes the 45 degree
## foreshortening so their pixels land 1:1 on the screen
const SPRITE_STRETCH := 1.4142135

const RIGHT := Vector3(0.70710678, 0, -0.70710678)  # screen right, on the ground
const DOWN := Vector3(0.70710678, 0, 0.70710678)    # screen down (toward the camera), on the ground


static func to_world(screen: Vector2) -> Vector3:
	return RIGHT * screen.x + DOWN * screen.y


static func to_screen(world: Vector3) -> Vector2:
	return Vector2(world.dot(RIGHT), world.dot(DOWN))
