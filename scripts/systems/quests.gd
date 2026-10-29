extends Node
## The story of Brumaclara (chapter 1 of GUILD_ZERO_Historia_Completa, "El precio de una noche"),
## as a list of stages: what the hero must do now (the HUD shows it), who has something to say about it
## and what changes when it is done. The stage and the choices are saved with the game (Progress.quest).
##
## 1.1 "Una cama y un contrato": Mara's first job, the supply box from the carter to Tovan (delivered
##     sealed, opened, shared out or looked at by Elia first).
## 1.2 "El ruido bajo el puente": the rift in the outskirts and the Madre de la manada that feeds on it.
## 1.3 "Un nombre en el tablón": Iven's welcome and what to do with the rift's remains (Caldus of the
##     Faro wants them).
## Closing: night falls on the town, the bell of the seat rings three times; rank zero becomes official.

signal changed

enum Stage { ARRIVE, GET_BOX, DELIVER_BOX, REPORT_BOX, RIFT, REPORT_RIFT, MEET_IVEN, REMAINS, DONE }

const OBJECTIVES := {
	Stage.ARRIVE: "Busca trabajo: habla con Mara Venn, en la sede del Faro (al norte de la plaza).",
	Stage.GET_BOX: "Recoge la caja de suministros del carretero, junto a los establos (suroeste).",
	Stage.DELIVER_BOX: "Lleva la caja a Tovan Sere, de la Liga (terraza del este). Elia podría revisarla antes.",
	Stage.REPORT_BOX: "Vuelve con Mara Venn a cobrar el contrato.",
	Stage.RIFT: "Sal por la puerta sur a las afueras y acaba con lo que se alimenta de la grieta.",
	Stage.REPORT_RIFT: "Vuelve a la sede del Faro y cuéntaselo a Mara.",
	Stage.MEET_IVEN: "Habla con Iven Rusk, que espera junto al tablón de la sede.",
	Stage.REMAINS: "Un enviado del Faro, Caldus Renn, quiere los restos de la grieta. Habla con él.",
	Stage.DONE: "Capítulo 1 completado. Brumaclara es tuya: explora, compra, entrena en el patio de pruebas.",
}
const MADRE := "res://data/enemies/madre.tres"
const RIFT_AT := Vector3(10.4, 0, -8.1)  ## the rift of the outskirts (afueras.tscn, Props/RiftCrack)

var _busy := false


func stage() -> int:
	return int(Progress.quest.get("stage", 0))


func flag(name: String, default: Variant = null) -> Variant:
	return Progress.quest.flags.get(name, default)


func objective() -> String:
	return OBJECTIVES.get(stage(), "")


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


## A person was spoken to (F). Returns true when the story had something to say (the person's own
## lines are skipped then).
func talk(who: String, npc: Node) -> bool:
	if _busy:
		return true
	_busy = true
	var handled := await _talk(who.to_lower(), npc)
	_busy = false
	return handled


func _talk(who: String, npc: Node) -> bool:
	var s := stage()
	match [who, s]:
		["mara", Stage.ARRIVE]:
			await _say(npc, "Mara Venn", [
				"¿Rango cero y sin un cobre? Entonces eres justo lo que necesito.",
				"La carreta del carretero volcó en el camino: dice que algo salió de la maleza. Lleva una caja de suministros de la Liga.",
				"Recoge la caja y llévasela a Tovan, en la oficina de la Liga. Paga poco, pero incluye cama en la sede dos noches."])
			_set_stage(Stage.GET_BOX)
		["carter", Stage.GET_BOX]:
			await _say(npc, "Carretero", [
				"¿Te manda Mara? Gracias a la Luz. Esa caja no la quiero ni ver.",
				"Brillaba, te lo juro. La cosa que nos atacó tenía una luz violeta bajo la piel.",
				"Toma. Es para Tovan, el de la Liga. Y no la abras: lleva su sello."])
			Progress.add_item(&"caja")
			_set_stage(Stage.DELIVER_BOX)
		["elia", Stage.DELIVER_BOX]:
			if flag("elia_inspected", false):
				await _say(npc, "Elia", ["Esa pieza antigua no debería ir en una caja moderna. Pregúntale a Tovan de dónde salió."])
				return true
			var pick := await _say(npc, "Elia", [
				"¿Una caja de la Liga? Las conozco: a veces traen catalizadores para mi taller.",
				"Si quieres, le echo un vistazo antes de que la entregues. Tardaré un poco, y el sello se notará."],
				["Sí, revísala", "No, la entrego tal cual"])
			if pick == 0:
				_set_flag("elia_inspected", true)
				await _say(npc, "Elia", ["Medicinas, piezas de catalizador... y esto. Una pieza muy vieja, con tres marcas grabadas.",
						"No debería estar en un envío de ahora. Guárdate el detalle."])
		["tovan", Stage.DELIVER_BOX]:
			var options := ["Entregar la caja cerrada", "Abrirla antes, para comprobar el contenido", "Repartir parte de las medicinas entre las familias del camino"]
			if flag("elia_inspected", false):
				options.append("Entregarla y contarle lo que vio Elia")
			var pick := await _say(npc, "Tovan Sere", [
				"La caja de la carreta. Bien. Esas piezas tienen que llegar al puesto defensivo del este antes de que acabe la semana."],
				options)
			Progress.take_item(&"caja")
			var choice: String = ["sealed", "opened", "shared", "elia_inspected"][pick]
			_set_flag("supply_box_choice", choice)
			match choice:
				"sealed":
					await _say(npc, "Tovan Sere", ["Sello intacto. Así da gusto. La Liga no olvida a quien cumple."])
					_reward(25, 40)
				"opened":
					await _say(npc, "Tovan Sere", ["El sello está roto... ¿y dices que falta peso? Eso no me lo esperaba.",
							"Lo apuntaré. Pero la próxima vez, pregunta antes de abrir lo que no es tuyo."])
					_reward(15, 50)
				"shared":
					await _say(npc, "Tovan Sere", ["¿Repartiste las medicinas? Esas familias te lo agradecerán. El puesto del este, menos.",
							"Toma lo que queda del pago. No es un reproche: es una cuenta."])
					_reward(10, 50)
					Progress.add_item(&"pocion", 1)
				"elia_inspected":
					await _say(npc, "Tovan Sere", ["¿Una pieza antigua con tres marcas? No figura en mi inventario.",
							"Llegó tarde, pero ahora sé que alguien mete cosas en mis envíos. Gracias."])
					_reward(20, 50)
			_set_stage(Stage.REPORT_BOX)
		["mara", Stage.REPORT_BOX]:
			await _say(npc, "Mara Venn", [
				"¿Has cobrado? Entonces ya eres aventurero. Empieza cuando decides en qué gastar tu tiempo.",
				"Tengo otro encargo. En las afueras han desaparecido dos animales de carga. Hay una grieta violeta junto al viejo puente.",
				"Sal por la puerta sur. Si algo se alimenta de esa grieta, acaba con ello... y vuelve con todos los dedos."])
			_set_stage(Stage.RIFT)
		["mara", Stage.RIFT]:
			await _say(npc, "Mara Venn", ["La grieta está al este de la guarida de los lobos, en las afueras. Ten cuidado con la grande."])
		["mara", Stage.REPORT_RIFT]:
			await _say(npc, "Mara Venn", [
				"¿Se cerró cuando cayó la loba? Como si se estuviera alimentando de ella...",
				"Esto no debería haberse clasificado como un ataque común. Iven quiere hablar contigo: está junto al tablón."])
			_set_stage(Stage.MEET_IVEN)
		["iven", Stage.MEET_IVEN]:
			var pick := await _say(npc, "Iven Rusk", [
				"Así que tú eres el de rango cero que tumbó a la madre de la manada. Suerte de principiante.",
				"Un consejo gratis: los acechadores quedan abiertos al aterrizar. Pega entonces, no antes."],
				["Gracias, lo tendré en cuenta", "La próxima la tumbo antes que tú", "(Encogerse de hombros)"])
			_set_flag("iven_relationship", ["respect", "rival", "rival"][pick])
			var answer: Array = [["Hm. Al menos escuchas. Eso es raro por aquí."], ["Ja. Ya veremos quién escribe el informe."],
					["Como quieras. Un contrato bueno te da dinero; uno difícil, un nombre."]][pick]
			await _say(npc, "Iven Rusk", answer)
			_set_stage(Stage.REMAINS)
		["caldus", Stage.REMAINS]:
			var options := ["Entregar los restos al Faro", "Pedir que los examine Neris, del Archivo",
					"Guardar una muestra y entregar el resto", "No entregar nada hasta saber quién tiene autoridad"]
			var pick := await _say(npc, "Caldus Renn", [
				"Caldus Renn, del Gremio del Faro. Los restos de esa grieta son asunto de contención.",
				"Entrégamelos y nos encargaremos de que no haya más incidentes."], options)
			var choice: String = ["faro", "archivo", "muestra", "ninguno"][pick]
			_set_flag("remains_choice", choice)
			match choice:
				"faro":
					Progress.take_item(&"restos")
					await _say(npc, "Caldus Renn", ["Sabia decisión. El Faro recordará tu cooperación."])
				"archivo":
					Progress.take_item(&"restos")
					await _say(npc, "Caldus Renn", ["¿El Archivo? Neris siempre llega antes que nosotros... Muy bien. Que conste en el informe."])
				"muestra":
					await _say(npc, "Caldus Renn", ["Una muestra... Lo aceptaré, por ahora. No hagas experimentos con ella."])
				"ninguno":
					await _say(npc, "Caldus Renn", ["Prudente. O testarudo. Hablaremos cuando sepas a quién debes responder."])
			_finish_chapter(npc)
		_:
			return false
	return true


## The rift's mother fell: the rift closes and leaves the plaque and the remains.
func on_enemy_died(enemy: Node) -> void:
	var data: Resource = enemy.get("data")
	if data and data.resource_path == MADRE and stage() == Stage.RIFT:
		Progress.add_item(&"placa")
		Progress.add_item(&"restos")
		get_tree().call_group("hud", "say", "La grieta se cierra. Entre las piedras queda una placa con tres marcas.", 6.0)
		_set_stage(Stage.REPORT_RIFT)


func _on_node_added(node: Node) -> void:
	if node == get_tree().current_scene:
		_setup_scene.call_deferred(node)


## Per scene: the mother waits at the rift while the story needs her; Caldus only comes for the remains.
func _setup_scene(scene: Node) -> void:
	if scene == null or not is_instance_valid(scene):
		return
	if scene.scene_file_path.ends_with("afueras.tscn") and stage() == Stage.RIFT:
		_spawn_mother(scene)
	var caldus := scene.get_node_or_null("People/Caldus")
	if caldus:
		caldus.visible = stage() >= Stage.REMAINS
		caldus.process_mode = Node.PROCESS_MODE_INHERIT if caldus.visible else Node.PROCESS_MODE_DISABLED
		caldus.set_collision_layer_value(1, caldus.visible)


func _spawn_mother(scene: Node) -> void:
	var enemies := scene.get_node_or_null("Enemies")
	if enemies == null or enemies.has_node("MadreDeLaManada"):
		return
	var e: CharacterBody3D = load("res://scenes/characters/enemies/wolf.tscn").instantiate()
	e.name = "MadreDeLaManada"
	e.set("data", load(MADRE))
	e.set("orb_scene", load("res://scenes/effects/xp_orb.tscn"))
	e.set("death_effect", load("res://scenes/effects/rift_burst.tscn"))
	e.set("text_scene", load("res://scenes/effects/floating_text.tscn"))
	e.set_meta("summoned", true)
	e.collision_layer = 4
	e.collision_mask = 7
	e.position = RIFT_AT + Vector3(1.5, 0.2, 1.0)
	enemies.add_child(e)


func _finish_chapter(npc: Node) -> void:
	_set_stage(Stage.DONE)
	DayNight.set_hour(21.0)
	get_tree().call_group("hud", "say", "La campana de la sede suena tres veces.", 5.0)
	await get_tree().create_timer(1.2).timeout
	var mara := npc.get_tree().current_scene.get_node_or_null("People/Mara")
	await _say(mara if mara else npc, "Mara Venn", [
		"Esta noche han aparecido contratos nuevos en el tablón. Para caminos que nunca habían sido peligrosos.",
		"No sé qué está pasando. Pero sé reconocer cuando alguien intenta llamar rutina a algo que no entiende.",
		"Toma. Desde hoy, tu rango cero es oficial."])
	Progress.add_item(&"insignia")
	_reward(50, 120)
	get_tree().call_group("hud", "chapter_complete", "Capítulo 1 — El precio de una noche")


func _say(npc: Node, who: String, lines: Array, options: Array = []) -> int:
	if npc and npc.has_method("face_hero"):
		npc.face_hero()
	return await Dialogue.run(npc if npc else self, who, PackedStringArray(lines), PackedStringArray(options))


func _reward(coins: int, xp: int) -> void:
	Progress.add_item(&"monedas", coins)
	var hero := get_tree().get_first_node_in_group("player")
	if hero and hero.has_method("gain_xp"):
		hero.gain_xp(xp)
	get_tree().call_group("hud", "say", "+%d monedas · +%d de experiencia" % [coins, xp], 4.0)


func _set_stage(s: int) -> void:
	Progress.quest.stage = s
	Progress.save_game()
	changed.emit()
	_setup_scene(get_tree().current_scene)


func _set_flag(name: String, value: Variant) -> void:
	Progress.quest.flags[name] = value
	Progress.save_game()
