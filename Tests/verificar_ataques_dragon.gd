# Godot --headless --path . --script res://Tests/verificar_ataques_dragon.gd
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
	Engine.time_scale = 8.0
	var ataques := escena.get_node("AtaquesDragon")
	var caballero := escena.get_node("Personaje")
	var dragon := escena.get_node("Enemigo")
	ataques.azar.seed = 12345
	for tipo in range(3):
		for y in range(5):
			for x in range(5):
				var objetivo := Vector2i(x, y)
				var celdas: Array[Vector2i] = ataques.elegir_zona(tipo, objetivo)
				assert(celdas.size() == [9, 6, 5][tipo])
				assert(celdas.has(objetivo))
				var unicas: Dictionary = {}
				var filas: Dictionary = {}
				var columnas: Dictionary = {}
				for celda in celdas:
					assert(celda.x >= 0 and celda.x < 5 and celda.y >= 0 and celda.y < 5)
					unicas[celda] = true
					filas[celda.y] = filas.get(celda.y, 0) + 1
					columnas[celda.x] = true
				assert(unicas.size() == celdas.size())
				if tipo == 0:
					assert(filas.size() == 3 and columnas.size() == 3)
				elif tipo == 1:
					assert(filas.size() == 2 and columnas.size() == 3)
					for cantidad in filas.values():
						assert(cantidad == 3)
				else:
					assert(columnas.size() == 1 and filas.size() == 5)

	var anterior := -1
	for _tanda in range(5):
		var vistos: Dictionary = {}
		for _paso in range(3):
			ataques.preparar_siguiente()
			var datos: Dictionary = ataques.ataque_actual
			var tipo: int = datos.tipo
			assert(tipo != anterior)
			anterior = tipo
			vistos[tipo] = true
			assert(datos.dano >= [3, 5, 8][tipo] and datos.dano <= [5, 7, 10][tipo])
			ataques.limpiar()
		assert(vistos.size() == 3)

	var resultados: Array[int] = []
	ataques.ataque_resuelto.connect(func(_tipo: int, dano: int) -> void: resultados.append(dano))
	for tipo in range(3):
		for esquivar in [false, true]:
			caballero.puntos_vida = 10
			caballero.posicion = Vector2(2, 2)
			caballero.global_position = caballero._posicion_global_celda()
			ataques.cola.assign([tipo])
			ataques.preparar_siguiente()
			var previstas: Array[Vector2i] = ataques.ataque_actual.celdas.duplicate()
			var dano: int = ataques.ataque_actual.dano
			assert(ataques.marcas.celdas == previstas)
			if esquivar:
				for y in range(5):
					for x in range(5):
						if not previstas.has(Vector2i(x, y)):
							caballero.posicion = Vector2(x, y)
				caballero.global_position = caballero._posicion_global_celda()
			ataques.preparar_siguiente()
			assert(ataques.ataque_actual.celdas == previstas)
			await ataques.ejecutar_ataque()
			assert(caballero.puntos_vida == (10 if esquivar else 10 - dano))
			assert(resultados[-1] == (0 if esquivar else dano))
			assert(ataques.ataque_actual.is_empty() and ataques.marcas.celdas.is_empty())
			assert(not ataques.en_curso and not ataques.efectos.visible and not dragon.atacando)
			assert(dragon.sprite.position == dragon.posicion_reposo)
			assert(dragon.sprite.scale == dragon.escala_reposo)
			assert(dragon.sprite.animation == &"idle")
			assert(dragon.sprite.frame == caballero.sprite.frame)
	assert(resultados.size() == 6)
	# Un dragon derrotado no golpea ni deja una advertencia activa.
	caballero.puntos_vida = 10
	ataques.preparar_siguiente()
	dragon.puntos_vida = 0
	await ataques.ejecutar_ataque()
	assert(caballero.puntos_vida == 10 and resultados.size() == 6)
	assert(ataques.marcas.celdas.is_empty())
	Engine.time_scale = 1.0
	print("OK: patrones en 25 posiciones, cola aleatoria, rangos, marcas fijas, impactos, esquivas y retorno a idle.")
	quit()
