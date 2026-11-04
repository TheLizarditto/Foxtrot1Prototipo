# Godot --headless --path . --script res://Tests/verificar_escudo.gd
extends SceneTree


func _initialize() -> void:
	_verificar.call_deferred()


func _encolar(mano: Mano, datos: Dictionary) -> void:
	var carta := mano.cartas_visuales[0]
	mano.mano[0] = Carta.normalizar_datos(datos)
	Carta.aplicar_datos(carta, datos)
	mano.carta_en_hover = carta
	await mano._usar_carta_en_posicion(carta.position)


func _finalizar_turno(turno: Node) -> void:
	turno._al_presionar_boton_turno()
	turno.seleccion_descarte._confirmar()
	for _frame in range(3000):
		if not turno.pasando_turno:
			return
		await process_frame
	assert(false, "El turno no termino")


# Deja un ataque conocido, sin el escudo aleatorio del dragon.
func _preparar_ataque(ataques: Node, dano: int, celdas: Array[Vector2i]) -> void:
	ataques.limpiar()
	ataques.dragon.limpiar_escudo()
	ataques.ataque_actual = {"tipo": 0, "dano": dano, "celdas": celdas}
	ataques.marcas.mostrar(celdas)
	ataques.ataque_cambiado.emit()


func _verificar() -> void:
	Engine.time_scale = 8.0
	var escena := load("res://Scenes/main.tscn").instantiate() as Node2D
	root.add_child(escena)
	current_scene = escena
	var turno := escena.get_node("Turno")
	var mano := escena.get_node("Mano") as Mano
	var ataques := escena.get_node("AtaquesDragon")
	var caballero := escena.get_node("Personaje")
	var dragon := escena.get_node("Enemigo")
	var vista_caballero := escena.get_node("IndicadorCaballero")
	var vista_dragon := escena.get_node("IndicadorDragon")
	for _frame in range(3000):
		if turno.turno_actual == 1:
			break
		await process_frame
	assert(turno.turno_actual == 1)

	# Tickets 48 y 49: el escudo absorbe primero y baja con cada golpe.
	dragon.escudo = 0
	caballero.escudo = 5
	assert(caballero.recibir_dano(3) == 0)
	assert(caballero.escudo == 2 and caballero.puntos_vida == 10)
	assert(caballero.recibir_dano(6) == 4)
	assert(caballero.escudo == 0 and caballero.puntos_vida == 6)
	assert(caballero.recibir_dano(-4) == 0 and caballero.puntos_vida == 6)
	caballero.agregar_escudo(-3)
	assert(caballero.escudo == 0)
	caballero.puntos_vida = 10
	var heridas: Array[int] = []
	dragon.vida_cambiada.connect(func(actual: int, _maxima: int) -> void: heridas.append(actual))
	dragon.escudo = 4
	assert(dragon.recibir_dano(4) == 0)
	assert(dragon.escudo == 0 and dragon.puntos_vida == 20)
	assert(dragon.tween_herida == null)
	assert(heridas == [20])

	# Ticket 50: el escudo del dragon respeta su rango y aparece solo en algunos turnos.
	ataques.azar.seed = 777
	var con_escudo := 0
	for _vez in range(400):
		ataques.limpiar()
		dragon.limpiar_escudo()
		ataques.preparar_siguiente()
		if dragon.escudo > 0:
			con_escudo += 1
			assert(dragon.escudo >= 2 and dragon.escudo <= 4)
	assert(con_escudo > 120 and con_escudo < 200)

	# Tickets 45, 47, 51 y 53: la vista previa sigue a la cola sin tocar los valores reales.
	_preparar_ataque(ataques, 7, [Vector2i(2, 2)] as Array[Vector2i])
	assert(vista_caballero.etiqueta_escudo.text == "0" and vista_caballero.etiqueta_dano.text == "7")
	assert(vista_dragon.etiqueta_escudo.text == "0" and vista_dragon.etiqueta_dano.text == "0")
	dragon.escudo = 3
	assert(vista_dragon.etiqueta_escudo.text == "3")
	await _encolar(mano, {"ataque": 2, "defensa": 3, "costo_pa": 1})
	assert(vista_caballero.etiqueta_escudo.text == "0 > 3")
	assert(vista_caballero.etiqueta_dano.text == "7 > 4")
	assert(vista_dragon.etiqueta_escudo.text == "3 > 1")
	assert(vista_dragon.etiqueta_dano.text == "2 > 0")
	await _encolar(mano, {"ataque": 3, "costo_pa": 1})
	assert(vista_dragon.etiqueta_escudo.text == "3 > 0")
	assert(vista_dragon.etiqueta_dano.text == "5 > 2")
	assert(caballero.escudo == 0 and dragon.escudo == 3)
	await _encolar(mano, {"movimientos": [Vector2i(0, 1)], "costo_pa": 1})
	assert(vista_caballero.etiqueta_dano.text == "0")
	# Sacar la carta de la cola devuelve la prevision y la celda original.
	await mano._usar_carta_en_posicion(mano.cartas_en_cola[2].position)
	assert(vista_caballero.etiqueta_dano.text == "7 > 4")

	# Tickets 52 y 54: las cartas protegen del ataque del turno y el sobrante se borra.
	await _finalizar_turno(turno)
	assert(dragon.puntos_vida == 18)
	assert(caballero.puntos_vida == 6)
	assert(caballero.escudo == 0)
	assert(turno.turno_actual == 2)
	assert(vista_caballero.etiqueta_escudo.text == "0")

	_preparar_ataque(ataques, 2, [Vector2i(2, 2)] as Array[Vector2i])
	await _encolar(mano, {"defensa": 3, "costo_pa": 1})
	assert(vista_caballero.etiqueta_dano.text == "2 > 0")
	var escudo_antes_de_limpiar: Array[int] = []
	ataques.ataque_resuelto.connect(func(_tipo: int, _dano: int) -> void: escudo_antes_de_limpiar.append(caballero.escudo))
	await _finalizar_turno(turno)
	assert(escudo_antes_de_limpiar == [1])
	assert(caballero.puntos_vida == 6 and caballero.escudo == 0)

	# El movimiento planeado esquiva y los pasos fuera del tablero no cuentan.
	caballero.posicion = Vector2(4, 2)
	caballero.global_position = caballero._posicion_global_celda()
	_preparar_ataque(ataques, 5, [Vector2i(4, 2)] as Array[Vector2i])
	await _encolar(mano, {"movimientos": [Vector2i(2, 0)], "costo_pa": 1})
	assert(vista_caballero.etiqueta_dano.text == "5")
	await _finalizar_turno(turno)
	assert(caballero.puntos_vida == 1)

	# Al terminar el combate no queda escudo ni prevision activa.
	dragon.escudo = 2
	caballero.escudo = 2
	await _encolar(mano, {"ataque": 100, "costo_pa": 1})
	await _finalizar_turno(turno)
	assert(turno.combate_terminado and dragon.puntos_vida == 0)
	assert(dragon.escudo == 0 and caballero.escudo == 0)
	assert(vista_caballero.etiqueta_dano.text == "0")
	Engine.time_scale = 1.0
	print("OK: escudo, dragon con escudo, prevision de dano y escudo, cartas y limpieza al final del turno.")
	quit()
