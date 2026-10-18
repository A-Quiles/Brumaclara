class_name Hurtbox
extends Area3D
## The part of a character that can be struck. What a hit does (invulnerability, knockback, damage)
## is decided by the owner, which listens to `struck`.

signal struck(damage: int, push: Vector3)


func receive(damage: int, push: Vector3) -> void:
	struck.emit(damage, push)
