extends Node2D
class_name Mano

const ESCENA_CARTA := preload("res://Scenes/carta.tscn")

@export var cantidad_cartas_mano := 5
@export var separacion_cartas := 42.0
@export var angulo_maximo_grados := 12.0
@export var curvatura_vertical := 14.0

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

	mano.append(Carta.normalizar_datos(datos_carta))
	_crear_carta_visual(datos_carta)
	_actualizar_disposicion_visual()
	return true


# Roba cartas del mazo hasta completar la cantidad configurada de la mano. Es para llenar la mano
# Devuelve la cantidad de cartas que pudo cargar.
func cargar_desde_mazo(mazo_robo: MazoRobo) -> int:
	var cantidad_cargada := 0

	while not esta_llena() and robar_carta(mazo_robo):
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


# Crea la representacion visual de una carta dentro de la mano.
func _crear_carta_visual(datos_carta: Dictionary) -> void:
	var carta_visual := ESCENA_CARTA.instantiate() as Node2D
	Carta.aplicar_datos(carta_visual, datos_carta)
	add_child(carta_visual)
	cartas_visuales.append(carta_visual)


# Distribuye las cartas como un abanico, respetando su orden de izquierda a derecha.
func _actualizar_disposicion_visual() -> void:
	var total := cartas_visuales.size()
	if total == 0:
		return

	var centro := float(total - 1) / 2.0
	var divisor := maxf(centro, 1.0)

	for indice in range(total):
		var carta_visual := cartas_visuales[indice]
		var distancia_centro := float(indice) - centro
		var posicion_normalizada := distancia_centro / divisor

		carta_visual.position = Vector2(
			distancia_centro * separacion_cartas,
			pow(absf(posicion_normalizada), 2.0) * curvatura_vertical
		)
		carta_visual.rotation = deg_to_rad(posicion_normalizada * angulo_maximo_grados)
		carta_visual.z_index = total - indice
