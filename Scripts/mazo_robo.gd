extends Node2D
class_name MazoRobo

const ESCENA_CARTA := preload("res://Scenes/carta.tscn")
const DESPLAZAMIENTO_CARTA_SOBRE_MAZO := Vector2(0, -150)
const CANTIDAD_CARTAS_ANIMACION_LENTA := 4
const CANTIDAD_CARTAS_ANIMACION_RAPIDA := 20
const MAX_DURACION_ENTRADA_MAZO := 0.26
const MIN_DURACION_ENTRADA_MAZO := 0.08
const MAX_DURACION_APARICION_CARTA := 0.12
const MIN_DURACION_APARICION_CARTA := 0.03
const MAX_ESPERA_CARTA_VISIBLE := 0.12
const MIN_ESPERA_CARTA_VISIBLE := 0.01

var cartas: Array[Dictionary] = []

# Carga las cartas recibidas en la cola del mazo de robo.
func cargar_cartas(datos_cartas: Array[Dictionary]) -> void:
	vaciar()

	for datos in datos_cartas:
		insertar_carta(datos)


# Vacia todas las cartas guardadas en el mazo de robo.
func vaciar() -> void:
	cartas.clear()


# Inserta una carta al final de la cola del mazo de robo.
func insertar_carta(datos: Dictionary) -> void:
	cartas.append(datos.duplicate(true))


# Anima las cartas recibidas entrando al mazo de robo y las inserta en el mismo orden.
func cargar_cartas_animadas(datos_cartas: Array[Dictionary], origen_global: Variant = null) -> void:
	vaciar()

	var factor_aceleracion := _obtener_factor_aceleracion_animacion(datos_cartas.size())
	var posicion_origen := _obtener_posicion_origen_animacion(origen_global)

	for indice in range(datos_cartas.size()):
		var carta := _crear_carta_visual_animacion(datos_cartas[indice], posicion_origen)
		await _animar_carta_entrando(carta, factor_aceleracion)
		insertar_carta(datos_cartas[indice])
		carta.queue_free()


# Devuelve los datos de la proxima carta del mazo de robo.
func robar_carta() -> Dictionary:
	if cartas.is_empty():
		return {}

	var datos: Dictionary = cartas.pop_front()
	return datos.duplicate(true)


# Devuelve la cantidad de cartas guardadas en el mazo de robo.
func cantidad() -> int:
	return cartas.size()


# Crea una carta visual en la posicion de origen de la animacion.
func _crear_carta_visual_animacion(datos_carta: Dictionary, posicion_origen: Vector2) -> Node2D:
	var carta := ESCENA_CARTA.instantiate() as Node2D
	carta.set("movimientos", _copiar_movimientos(datos_carta.get("movimientos", [])))
	carta.set("ataque", maxi(int(datos_carta.get("ataque", 0)), 0))
	carta.set("defensa", maxi(int(datos_carta.get("defensa", 0)), 0))
	carta.modulate.a = 0.0
	carta.z_index = 100

	var escena_animacion := get_parent()
	if escena_animacion == null:
		escena_animacion = self

	escena_animacion.add_child(carta)
	carta.global_position = posicion_origen
	return carta


# Anima una carta visual hasta la posicion del mazo de robo.
func _animar_carta_entrando(carta: Node2D, factor_aceleracion: float) -> void:
	var duracion_aparicion := _obtener_duracion_aparicion(factor_aceleracion)
	var espera_visible := _obtener_espera_visible(factor_aceleracion)
	var duracion_entrada := _obtener_duracion_entrada(factor_aceleracion)

	var aparicion := create_tween()
	aparicion.tween_property(carta, "modulate:a", 1.0, duracion_aparicion)
	await aparicion.finished
	await get_tree().create_timer(espera_visible).timeout

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(carta, "global_position", global_position, duracion_entrada)
	tween.tween_property(carta, "scale", Vector2(0.35, 0.35), duracion_entrada)
	tween.tween_property(carta, "modulate:a", 0.0, duracion_entrada)

	await tween.finished


# Devuelve la posicion desde donde aparecen las cartas de la animacion.
func _obtener_posicion_origen_animacion(origen_global: Variant) -> Vector2:
	if origen_global is Vector2:
		return origen_global

	return global_position + DESPLAZAMIENTO_CARTA_SOBRE_MAZO


# Calcula que tan rapida debe ser la animacion segun la cantidad de cartas.
func _obtener_factor_aceleracion_animacion(cantidad_cartas: int) -> float:
	var rango := CANTIDAD_CARTAS_ANIMACION_RAPIDA - CANTIDAD_CARTAS_ANIMACION_LENTA
	if rango <= 0:
		return 1.0

	return clampf(
		float(cantidad_cartas - CANTIDAD_CARTAS_ANIMACION_LENTA) / float(rango),
		0.0,
		1.0
	)


# Devuelve la duracion de aparicion ajustada por la cantidad de cartas.
func _obtener_duracion_aparicion(factor_aceleracion: float) -> float:
	return lerpf(MAX_DURACION_APARICION_CARTA, MIN_DURACION_APARICION_CARTA, factor_aceleracion)


# Devuelve el tiempo visible de cada carta ajustado por la cantidad de cartas.
func _obtener_espera_visible(factor_aceleracion: float) -> float:
	return lerpf(MAX_ESPERA_CARTA_VISIBLE, MIN_ESPERA_CARTA_VISIBLE, factor_aceleracion)


# Devuelve la duracion de entrada al mazo ajustada por la cantidad de cartas.
func _obtener_duracion_entrada(factor_aceleracion: float) -> float:
	return lerpf(MAX_DURACION_ENTRADA_MAZO, MIN_DURACION_ENTRADA_MAZO, factor_aceleracion)


# Copia los movimientos recibidos y conserva solo valores Vector2i.
func _copiar_movimientos(movimientos_originales: Variant) -> Array[Vector2i]:
	var movimientos: Array[Vector2i] = []

	if not movimientos_originales is Array:
		return movimientos

	for movimiento in movimientos_originales:
		if movimientos.size() >= Carta.MAX_MOVIMIENTOS:
			break

		if movimiento is Vector2i:
			movimientos.append(movimiento)

	return movimientos
