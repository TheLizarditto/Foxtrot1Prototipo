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

@onready var contador_cartas: Label = $ContadorCartas

var cartas: Array[Dictionary] = []


func _ready() -> void:
	_actualizar_contador()


# Carga un conjunto inicial de cartas en el mazo.
func cargar_cartas(datos_cartas: Array[Dictionary]) -> void:
	vaciar()

	for datos in datos_cartas:
		insertar_carta(datos)


# Limpia todas las cartas del mazo.
func vaciar() -> void:
	cartas.clear()
	_actualizar_contador()


# Inserta una carta en el mazo.
func insertar_carta(datos: Dictionary) -> void:
	cartas.append(Carta.normalizar_datos(datos))
	_actualizar_contador()


# Anima e inserta cartas progresivamente dentro del mazo.
func cargar_cartas_animadas(datos_cartas: Array[Dictionary], origen_global: Variant = null) -> void:
	vaciar()

	var factor_aceleracion := _obtener_factor_aceleracion_animacion(datos_cartas.size())
	var posicion_origen := _obtener_posicion_origen_animacion(origen_global)

	for indice in range(datos_cartas.size()):
		var carta := _crear_carta_visual_animacion(datos_cartas[indice], posicion_origen)
		await _animar_carta_entrando(carta, factor_aceleracion)
		insertar_carta(datos_cartas[indice])
		carta.queue_free()


# Transfiere y mezcla las cartas del descarte hacia este mazo cuando esta vacio.
func recargar_desde_descarte(mazo_descarte: MazoDescarte) -> bool:
	if not esta_vacio():
		return true

	if mazo_descarte == null or mazo_descarte.esta_vacio():
		return false

	mazo_descarte.mezclar()
	await cargar_cartas_animadas(mazo_descarte.entregar_cartas(), mazo_descarte.global_position)

	return not esta_vacio()


# Extrae la carta superior del mazo.
func robar_carta() -> Dictionary:
	if cartas.is_empty():
		return {}

	var datos: Dictionary = cartas.pop_front()
	_actualizar_contador()
	return datos.duplicate(true)


# Roba una carta y recarga desde el descarte antes o despues si es necesario.
func robar_carta_con_recarga(mazo_descarte: MazoDescarte) -> Dictionary:
	if esta_vacio():
		await recargar_desde_descarte(mazo_descarte)

	var datos := robar_carta()

	if esta_vacio():
		await recargar_desde_descarte(mazo_descarte)

	return datos


# Devuelve cuantas cartas quedan en el mazo.
func cantidad() -> int:
	return cartas.size()


# Indica si no quedan cartas.
func esta_vacio() -> bool:
	return cartas.is_empty()


# Mantiene actualizado el texto del contador visual.
func _actualizar_contador() -> void:
	if not is_node_ready():
		return

	contador_cartas.text = str(cantidad())


# Instancia la carta temporal para la animacion de entrada al mazo.
func _crear_carta_visual_animacion(datos_carta: Dictionary, posicion_origen: Vector2) -> Node2D:
	var carta := ESCENA_CARTA.instantiate() as Node2D
	Carta.aplicar_datos(carta, datos_carta)
	if carta.has_method("mostrar_reverso"):
		carta.mostrar_reverso()
	carta.modulate.a = 0.0
	carta.z_index = 100

	var escena_animacion := get_parent()
	if escena_animacion == null:
		escena_animacion = self

	escena_animacion.add_child(carta)
	carta.global_position = posicion_origen
	return carta


# Anima una carta individual viajando hacia el mazo de robo.
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


# Resuelve la posicion inicial desde la que parte la carta antes de entrar al mazo.
func _obtener_posicion_origen_animacion(origen_global: Variant) -> Vector2:
	if origen_global is Vector2:
		return origen_global

	return global_position + desplazamiento_carta_sobre_mazo


# Calcula un factor de 0 a 1 para acelerar las animaciones si hay muchas cartas.
func _obtener_factor_aceleracion_animacion(cantidad_cartas: int) -> float:
	var rango := cantidad_cartas_animacion_rapida - cantidad_cartas_animacion_lenta
	if rango <= 0:
		return 1.0

	return clampf(
		float(cantidad_cartas - cantidad_cartas_animacion_lenta) / float(rango),
		0.0,
		1.0
	)


# Devuelve el tiempo de aparicion escalado por la cantidad de cartas.
func _obtener_duracion_aparicion(factor_aceleracion: float) -> float:
	return _interpolar_por_aceleracion(max_duracion_aparicion_carta, min_duracion_aparicion_carta, factor_aceleracion)


# Devuelve el tiempo de espera visible escalado por la cantidad de cartas.
func _obtener_espera_visible(factor_aceleracion: float) -> float:
	return _interpolar_por_aceleracion(max_espera_carta_visible, min_espera_carta_visible, factor_aceleracion)


# Devuelve el tiempo de desplazamiento al mazo escalado por la cantidad de cartas.
func _obtener_duracion_entrada(factor_aceleracion: float) -> float:
	return _interpolar_por_aceleracion(max_duracion_entrada_mazo, min_duracion_entrada_mazo, factor_aceleracion)


# Interpola un valor entre lento y rapido segun el factor de aceleracion.
func _interpolar_por_aceleracion(valor_lento: float, valor_rapido: float, factor_aceleracion: float) -> float:
	return lerpf(valor_lento, valor_rapido, factor_aceleracion)
