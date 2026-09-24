extends Node2D
class_name Mano

const ESCENA_CARTA := preload("res://Scenes/carta.tscn")

@export var cantidad_cartas_mano := 5
@export var separacion_cartas := 42.0
@export var angulo_maximo_grados := 12.0
@export var curvatura_vertical := 14.0
@export var altura_animacion_robo := 90.0
@export var duracion_levantar_carta := 0.18
@export var duracion_girar_carta := 0.18
@export var duracion_llevar_a_mano := 0.34

var mano: Array[Dictionary] = []
var cartas_visuales: Array[Node2D] = []


# Roba la proxima carta del mazo y la agrega al final de la mano. Es para robar una carta
# Devuelve false si la mano esta llena o el mazo no tiene cartas disponibles.
func robar_carta(mazo_robo: MazoRobo) -> bool:
	if mazo_robo == null or esta_llena():
		return false

	var datos_carta := mazo_robo.robar_carta()
	if datos_carta.is_empty():
		return false

	_agregar_carta(datos_carta)
	_actualizar_disposicion_visual()
	return true


# Roba cartas del mazo hasta completar la cantidad configurada de la mano. Es para llenar la mano
# Devuelve la cantidad de cartas que pudo cargar.
func cargar_desde_mazo(mazo_robo: MazoRobo) -> int:
	var cantidad_cargada := 0

	while not esta_llena() and robar_carta(mazo_robo):
		cantidad_cargada += 1

	return cantidad_cargada


# Roba una carta y la anima desde el mazo hasta su lugar en la mano.
func robar_carta_animada(mazo_robo: MazoRobo) -> bool:
	if mazo_robo == null or esta_llena():
		return false

	var datos_carta := mazo_robo.robar_carta()
	if datos_carta.is_empty():
		return false

	var carta_visual := _agregar_carta(datos_carta)
	await _animar_carta_robada(carta_visual, mazo_robo.global_position)
	return true


# Reparte cartas una por una hasta completar la mano.
func cargar_desde_mazo_animada(mazo_robo: MazoRobo) -> int:
	var cantidad_cargada := 0

	while not esta_llena():
		if not await robar_carta_animada(mazo_robo):
			break

		cantidad_cargada += 1

	return cantidad_cargada


# Devuelve la cantidad actual de cartas en la mano.
func cantidad() -> int:
	return mano.size()


# Indica si la mano alcanzo la cantidad de cartas configurada.
func esta_llena() -> bool:
	return cantidad() >= maxi(cantidad_cartas_mano, 0)


# Indica si la mano no tiene cartas.
func esta_vacia() -> bool:
	return mano.is_empty()


# Devuelve una copia de las cartas en el mismo orden en que fueron robadas.
func obtener_cartas() -> Array[Dictionary]:
	var copia_cartas: Array[Dictionary] = []

	for datos in mano:
		copia_cartas.append(datos.duplicate(true))

	return copia_cartas


# Guarda una carta y crea su representacion visual.
func _agregar_carta(datos_carta: Dictionary) -> Node2D:
	mano.append(Carta.normalizar_datos(datos_carta))

	var carta_visual := ESCENA_CARTA.instantiate() as Node2D
	Carta.aplicar_datos(carta_visual, datos_carta)
	add_child(carta_visual)
	cartas_visuales.append(carta_visual)
	return carta_visual


# Eleva la carta, la gira para mostrar su frente y la lleva en arco a la mano.
func _animar_carta_robada(carta_visual: Node2D, origen_global: Vector2) -> void:
	var total := cartas_visuales.size()
	var indice := total - 1
	var posicion_destino := _obtener_posicion_carta(indice, total)
	var rotacion_destino := _obtener_rotacion_carta(indice, total)
	var z_destino := total - indice
	var posicion_inicial := to_local(origen_global)
	var posicion_elevada := posicion_inicial + Vector2(-14.0, -42.0)
	var control_arco := (posicion_elevada + posicion_destino) / 2.0 + Vector2(0.0, -altura_animacion_robo)
	var contenido := carta_visual.get_node_or_null("Contenido") as CanvasItem

	_acomodar_cartas_existentes(carta_visual, duracion_levantar_carta)
	carta_visual.position = posicion_inicial
	carta_visual.rotation = 0.0
	carta_visual.scale = Vector2(0.92, 0.92)
	carta_visual.modulate = Color(0.62, 0.66, 0.78, 1.0)
	carta_visual.z_index = 100

	if contenido != null:
		contenido.visible = false

	var tween := create_tween()
	var levantar := tween.tween_property(
		carta_visual,
		"position",
		posicion_elevada,
		maxf(duracion_levantar_carta, 0.0)
	)
	levantar.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(
		carta_visual,
		"rotation",
		deg_to_rad(-7.0),
		maxf(duracion_levantar_carta, 0.0)
	)

	var primera_mitad := tween.tween_method(
		_mover_carta_en_arco.bind(carta_visual, posicion_elevada, control_arco, posicion_destino),
		0.0,
		0.5,
		maxf(duracion_girar_carta, 0.0)
	)
	primera_mitad.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(
		carta_visual,
		"scale:x",
		0.05,
		maxf(duracion_girar_carta, 0.0)
	)

	tween.tween_callback(_mostrar_frente_carta.bind(carta_visual, contenido, z_destino))

	var segunda_mitad := tween.tween_method(
		_mover_carta_en_arco.bind(carta_visual, posicion_elevada, control_arco, posicion_destino),
		0.5,
		1.0,
		maxf(duracion_llevar_a_mano, 0.0)
	)
	segunda_mitad.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(
		carta_visual,
		"scale",
		Vector2.ONE,
		maxf(duracion_llevar_a_mano, 0.0)
	)
	tween.parallel().tween_property(
		carta_visual,
		"rotation",
		rotacion_destino,
		maxf(duracion_llevar_a_mano, 0.0)
	)

	await tween.finished
	_actualizar_disposicion_visual()


# Abre lugar suavemente en el abanico mientras se reparte la carta nueva.
func _acomodar_cartas_existentes(carta_nueva: Node2D, duracion: float) -> void:
	var total := cartas_visuales.size()
	if total <= 1:
		return

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	for indice in range(total):
		var carta_visual := cartas_visuales[indice]
		carta_visual.z_index = total - indice

		if carta_visual == carta_nueva:
			continue

		tween.tween_property(
			carta_visual,
			"position",
			_obtener_posicion_carta(indice, total),
			maxf(duracion, 0.0)
		)
		tween.tween_property(
			carta_visual,
			"rotation",
			_obtener_rotacion_carta(indice, total),
			maxf(duracion, 0.0)
		)


# Mueve una carta sobre una curva cuadratica para evitar un recorrido recto.
func _mover_carta_en_arco(
	progreso: float,
	carta_visual: Node2D,
	inicio: Vector2,
	control: Vector2,
	fin: Vector2
) -> void:
	var inverso := 1.0 - progreso
	carta_visual.position = (
		inverso * inverso * inicio
		+ 2.0 * inverso * progreso * control
		+ progreso * progreso * fin
	)


# Revela el contenido de la carta justo cuando termina de darse vuelta.
func _mostrar_frente_carta(carta_visual: Node2D, contenido: CanvasItem, z_destino: int) -> void:
	if contenido != null:
		contenido.visible = true

	carta_visual.modulate = Color.WHITE
	carta_visual.z_index = z_destino


# Distribuye las cartas como un abanico, respetando su orden de izquierda a derecha.
func _actualizar_disposicion_visual() -> void:
	var total := cartas_visuales.size()
	if total == 0:
		return

	for indice in range(total):
		var carta_visual := cartas_visuales[indice]
		carta_visual.position = _obtener_posicion_carta(indice, total)
		carta_visual.rotation = _obtener_rotacion_carta(indice, total)
		carta_visual.scale = Vector2.ONE
		carta_visual.modulate = Color.WHITE
		carta_visual.z_index = total - indice


# Calcula la posicion de una carta dentro del abanico.
func _obtener_posicion_carta(indice: int, total: int) -> Vector2:
	var centro := float(total - 1) / 2.0
	var distancia_centro := float(indice) - centro
	var posicion_normalizada := distancia_centro / maxf(centro, 1.0)

	return Vector2(
		distancia_centro * separacion_cartas,
		pow(absf(posicion_normalizada), 2.0) * curvatura_vertical
	)


# Calcula la inclinacion de una carta dentro del abanico.
func _obtener_rotacion_carta(indice: int, total: int) -> float:
	var centro := float(total - 1) / 2.0
	var distancia_centro := float(indice) - centro
	var posicion_normalizada := distancia_centro / maxf(centro, 1.0)

	return deg_to_rad(posicion_normalizada * angulo_maximo_grados)
