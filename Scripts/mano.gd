extends Node2D
class_name Mano

@export var cantidad_cartas_mano := 5

var mano: Array[Dictionary] = []


# Roba la proxima carta del mazo y la agrega al final de la mano. Es para robar una carta
# Devuelve false si la mano esta llena o el mazo no tiene cartas disponibles.
func robar_carta(mazo_robo: MazoRobo) -> bool:
	if mazo_robo == null or esta_llena():
		return false

	var datos_carta := mazo_robo.robar_carta()
	if datos_carta.is_empty():
		return false

	mano.append(Carta.normalizar_datos(datos_carta))
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
