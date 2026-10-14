# Ejecutar: Godot --headless --path . --script res://Tests/verificar_recorrido.gd
extends SceneTree


func _initialize() -> void:
	_verificar.call_deferred()


func _verificar() -> void:
	var escena := load("res://Scenes/main.tscn").instantiate() as Node2D
	var turno := escena.get_node("Turno")
	escena.remove_child(turno)
	turno.free()
	root.add_child(escena)
	current_scene = escena
	await process_frame
	var mano := escena.get_node("Mano") as Mano
	var personaje := escena.get_node("Personaje") as Node2D
	var vista := escena.get_node("Tablero/VistaRecorrido") as Node2D

	# Ejemplo pedido: arriba, luego derecha, entre dos cartas.
	mano.cola.assign([{"movimientos": [Vector2i.UP]}, {"movimientos": [Vector2i.RIGHT]}])
	mano.cola_cambiada.emit()
	assert(vista.pasos.size() == 2)
	assert(vista.pasos[0].posicion == Vector2i(2, 1))
	assert(vista.pasos[0].direccion == Vector2i.UP)
	assert(vista.pasos[1].posicion == Vector2i(3, 1))
	assert(vista.pasos[1].direccion == Vector2i.RIGHT)

	# El mouse resalta solo la flecha y el numero apuntados, incluso sobre el personaje.
	var primero: Node2D = vista.indicadores[0]
	var segundo: Node2D = vista.indicadores[1]
	var zona: Rect2 = primero.get_meta("zona_hover")
	vista._actualizar_hover(primero.to_global(zona.get_center()))
	assert(is_equal_approx(primero.modulate.a, 1.0))
	assert(primero.z_index > personaje.z_index)
	assert(is_equal_approx(segundo.modulate.a, 0.4))
	assert(segundo.z_index == personaje.z_index)
	assert(not primero.z_as_relative)
	assert(vista.texturas[Vector2i.UP].get_image().get_pixel(7, 7) == Color("99e550"))
	vista._actualizar_hover(Vector2(-1000, -1000))
	assert(is_equal_approx(primero.modulate.a, 0.4))
	assert(primero.z_index == personaje.z_index)

	# Quitar y cambiar el orden recalcula desde la posicion del personaje.
	mano.cola.reverse()
	mano.cola_cambiada.emit()
	assert(vista.pasos[0].posicion == Vector2i(3, 2))
	mano.cola.pop_front()
	mano.cola_cambiada.emit()
	assert(vista.pasos.size() == 1)
	assert(vista.pasos[0].posicion == Vector2i(2, 1))

	# Todas las direcciones, incluida la textura propia para cada diagonal.
	for direccion in Carta.DIRECCIONES_VALIDAS:
		mano.cola.assign([{"movimientos": [direccion]}])
		mano.cola_cambiada.emit()
		assert(vista.pasos[0].posicion == Vector2i(2, 2) + direccion)
		assert(vista.texturas[direccion].get_size() == Vector2(15, 15))

	# Multipaso, bordes, movimiento invalido y regreso a una celda ya visitada.
	var datos := {"movimientos": [Vector2i(0, -4), Vector2i(1, -2), Vector2i(0, 1), Vector2i(0, -1)]}
	mano.cola.assign([datos])
	mano.cola_cambiada.emit()
	assert(vista.pasos.size() == 4)
	assert(vista.pasos[1].posicion == Vector2i(2, 0))
	assert(vista.pasos[3].posicion == Vector2i(2, 0))
	assert(vista.pasos[3].orden == 4)
	await process_frame # Dibuja tambien las visitas repetidas.

	# Compara la previsualizacion con la ejecucion real y su limpieza.
	var carta := mano.ESCENA_CARTA.instantiate() as Carta
	Carta.aplicar_datos(carta, datos)
	mano.add_child(carta)
	mano.cartas_en_cola.append(carta)
	carta.delay_entre_movimientos = 0.0
	personaje.duracion_paso = 0.01
	var destino_previsto: Vector2i = vista.pasos[-1].posicion
	await mano.ejecutar_cola()
	assert(Vector2i(personaje.posicion) == destino_previsto)
	assert(vista.pasos.is_empty())
	assert(mano.cola.is_empty())
	print("OK: color, transparencia, hover individual, capas y ejecucion del recorrido.")
	quit()
