class_name Health
extends Node
## Hit points of anything that can be hurt. Bars, sounds and reactions listen to the signals.

signal changed(current: int, maximum: int)
signal died

@export var maximum := 100:
	set(value):
		maximum = value
		current = mini(current, maximum)
		changed.emit(current, maximum)

var current := 0


func _ready() -> void:
	current = maximum
	changed.emit(current, maximum)


func damage(amount: int) -> void:
	if current == 0:
		return
	current = maxi(0, current - amount)
	changed.emit(current, maximum)
	if current == 0:
		died.emit()


func heal(amount: int) -> void:
	current = mini(maximum, current + amount)
	changed.emit(current, maximum)


func is_dead() -> bool:
	return current == 0
