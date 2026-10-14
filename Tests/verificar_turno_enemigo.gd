# Godot --headless --path . --script res://Tests/verificar_turno_enemigo.gd
extends SceneTree


func _initialize() -> void:
	_verificar.call_deferred()


func _encolar(mano: Mano, datos: Dictionary) -> void:
	var carta := mano.cartas_visuales[0]
	mano.mano[0] = Carta.normalizar_datos(datos)
	Carta.aplicar_datos(carta, datos)
	mano.carta_en_hover = carta
	await mano._usar_carta_en_posicion(carta.position)
	assert(mano.cola.size() == 1)


func _finalizar_turno(turno: Node) -> void:
	turno._al_presionar_boton_turno()
	assert(turno.seleccion_descarte.panel.visible)
	turno.seleccion_descarte._confirmar()
	for _frame in range(3000):
		if not turno.pasando_turno:
			return
		await process_frame
	assert(false, "El turno no termino")


func _verificar() -> void:
	Engine.time_scale = 8.0
	var escena := load("res://Scenes/main.tscn").instantiate() as Node2D
	root.add_child(escena)
	current_scene = escena
	var turno := escena.get_node("Turno")
	var mano := escena.get_node("Mano") as Mano
	var ataques := escena.get_node("AtaquesDragon")
	var caballero := escena.get_node("Personaje")
	for _frame in range(3000):
		if turno.turno_actual == 1:
			break
		await process_frame
	assert(turno.turno_actual == 1 and mano.cantidad() == 7)
	assert(not ataques.marcas.celdas.is_empty())
	ataques.limpiar()
	ataques.cola.assign([2])
	ataques.preparar_siguiente()
	var posiciones_impacto: Array[Vector2i] = []
	ataques.ataque_resuelto.connect(func(_tipo: int, _dano: int) -> void:
		assert(turno.pasando_turno and turno.boton_turno.disabled)
		posiciones_impacto.append(Vector2i(caballero.posicion))
	)
	await _encolar(mano, {"movimientos": [Vector2i.RIGHT], "costo_pa": 1})
	await _finalizar_turno(turno)
	assert(posiciones_impacto == [Vector2i(3, 2)])
	assert(caballero.puntos_vida == 10)
	assert(turno.turno_actual == 2 and mano.cantidad() == 7)
	assert(not turno.boton_turno.disabled and mano.mano_lista_para_seleccion)
	assert(ataques.ataque_actual.celdas.has(Vector2i(3, 2)))
	# Si la carta derrota al dragon, su ataque pendiente no llega a ejecutarse.
	await _encolar(mano, {"ataque": 100, "costo_pa": 1})
	await _finalizar_turno(turno)
	assert(ataques.dragon.puntos_vida == 0)
	assert(posiciones_impacto.size() == 1 and caballero.puntos_vida == 10)
	assert(turno.combate_terminado and turno.boton_turno.disabled)
	assert(not mano.mano_lista_para_seleccion and ataques.marcas.celdas.is_empty())
	Engine.time_scale = 1.0
	print("OK: cartas antes del enemigo, esquiva real, bloqueo durante animacion, siguiente turno y cancelacion al derrotar al dragon.")
	quit()
