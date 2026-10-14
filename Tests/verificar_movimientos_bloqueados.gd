# Ejecutar: Godot --headless --path . --script res://Tests/verificar_movimientos_bloqueados.gd
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
	var personaje := escena.get_node("Personaje") as Node2D
	var carta := load("res://Scenes/carta.tscn").instantiate() as Carta
	carta.movimientos.assign([Vector2i(0, -4), Vector2i(-2, -2)])
	carta.delay_entre_movimientos = 0.5
	escena.add_child(carta)
	personaje.posicion = Vector2(2, 0)
	personaje.global_position = personaje._posicion_global_celda()
	var animacion: StringName = personaje.sprite.animation
	var frame_inicial := Engine.get_process_frames()
	await carta.ejecutar(personaje)
	assert(Engine.get_process_frames() == frame_inicial)
	assert(personaje.posicion == Vector2(2, 0))
	assert(personaje.sprite.animation == animacion)
	assert(not personaje.accion_en_curso)

	# Un paso valido seguido de choques termina en el mismo frame que el paso.
	personaje.posicion = Vector2(2, 1)
	personaje.global_position = personaje._posicion_global_celda()
	personaje.duracion_paso = 0.01
	carta.movimientos.assign([Vector2i(0, -4)])
	var frames_realizados: Array[int] = []
	carta.paso_resuelto.connect(func(realizado: bool) -> void:
		if realizado:
			frames_realizados.append(Engine.get_process_frames())
	)
	await carta.ejecutar(personaje)
	assert(frames_realizados.size() == 1)
	assert(Engine.get_process_frames() == frames_realizados[-1])
	assert(personaje.posicion == Vector2(2, 0))
	print("OK: pasos bloqueados sin animacion ni espera; sin pausa final tras llegar al borde.")
	quit()
