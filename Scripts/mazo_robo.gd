extends Node2D
class_name MazoRobo

const ESCENA_CARTA := preload("res://Scenes/carta.tscn")

@export var desplazamiento_carta_sobre_mazo := Vector2(0, -150)
@export var cantidad_cartas_animacion_lenta := 4
@export var cantidad_cartas_animacion_rapida := 20
@export var max_duracion_entrada_mazo := 0.26
@export var min_duracion_entrada_mazo := 0.08
@export var max_duracion_aparicion_carta := 0.12
@export var min_duracion_aparicion_carta := 0.03
@export var max_espera_carta_visible := 0.12
@export var min_espera_carta_visible := 0.01
@export var escala_carta_al_entrar := Vector2(0.35, 0.35)

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
	cartas.append(Carta.normalizar_datos(datos))


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


# Indica si el mazo de robo no tiene cartas disponibles.
func esta_vacio() -> bool:
	return cartas.is_empty()


# Crea una carta visual en la posicion de origen de la animacion.
func _crear_carta_visual_animacion(datos_carta: Dictionary, posicion_origen: Vector2) -> Node2D:
	var carta := ESCENA_CARTA.instantiate() as Node2D
	Carta.aplicar_datos(carta, datos_carta)
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
	tween.tween_property(carta, "scale", escala_carta_al_entrar, duracion_entrada)
	tween.tween_property(carta, "modulate:a", 0.0, duracion_entrada)

	await tween.finished


# Devuelve la posicion desde donde aparecen las cartas de la animacion.
func _obtener_posicion_origen_animacion(origen_global: Variant) -> Vector2:
	if origen_global is Vector2:
		return origen_global

	return global_position + desplazamiento_carta_sobre_mazo


# Calcula que tan rapida debe ser la animacion segun la cantidad de cartas.
func _obtener_factor_aceleracion_animacion(cantidad_cartas: int) -> float:
	var rango := cantidad_cartas_animacion_rapida - cantidad_cartas_animacion_lenta
	if rango <= 0:
		return 1.0

	return clampf(
		float(cantidad_cartas - cantidad_cartas_animacion_lenta) / float(rango),
		0.0,
		1.0
	)


# Devuelve la duracion de aparicion ajustada por la cantidad de cartas.
func _obtener_duracion_aparicion(factor_aceleracion: float) -> float:
	return _interpolar_por_aceleracion(max_duracion_aparicion_carta, min_duracion_aparicion_carta, factor_aceleracion)


# Devuelve el tiempo visible de cada carta ajustado por la cantidad de cartas.
func _obtener_espera_visible(factor_aceleracion: float) -> float:
	return _interpolar_por_aceleracion(max_espera_carta_visible, min_espera_carta_visible, factor_aceleracion)


# Devuelve la duracion de entrada al mazo ajustada por la cantidad de cartas.
func _obtener_duracion_entrada(factor_aceleracion: float) -> float:
	return _interpolar_por_aceleracion(max_duracion_entrada_mazo, min_duracion_entrada_mazo, factor_aceleracion)


# Interpola entre el valor lento y rapido usando el factor de aceleracion.
func _interpolar_por_aceleracion(valor_lento: float, valor_rapido: float, factor_aceleracion: float) -> float:
	return lerpf(valor_lento, valor_rapido, factor_aceleracion)
