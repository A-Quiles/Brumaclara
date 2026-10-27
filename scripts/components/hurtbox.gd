class_name Hurtbox
extends Area3D
## The part of a character that can be struck. What a hit does (invulnerability, knockback, damage,
## statuses) is decided by the owner, which listens to `struck`. `source` is the Hitbox, if any.

signal struck(damage: int, push: Vector3, source: Hitbox)


func receive(damage: int, push: Vector3, source: Hitbox = null) -> void:
	struck.emit(damage, push, source)
