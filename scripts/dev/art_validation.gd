extends Node3D
## Art validation scene (docs/plan_unificacion_artistica.md, section 5): the reference composition
## built by tools/levels/validation.py. Repeats a magic effect, one affinity after another, so effects
## are judged next to the hero and the props.

const AFFINITIES: Array[StringName] = [&"fuego", &"hielo", &"rayo", &"sombra", &"tierra", &"luz"]
var _next := 0


func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = 1.6
	timer.autostart = true
	timer.timeout.connect(_effect)
	add_child(timer)
	_effect.call_deferred()


func _effect() -> void:
	var at: Vector3 = $Muestras/Efecto.global_position
	Vfx.burst(self, at, AFFINITIES[_next % AFFINITIES.size()], 1.0)
	_next += 1
