extends RefCounted
class_name MovimientosCarta

const DIRECCION_ARRIBA := Vector2i(0, -1)
const DIRECCION_ABAJO := Vector2i(0, 1)
const DIRECCION_IZQUIERDA := Vector2i(-1, 0)
const DIRECCION_DERECHA := Vector2i(1, 0)
const DIRECCION_ARRIBA_IZQUIERDA := Vector2i(-1, -1)
const DIRECCION_ARRIBA_DERECHA := Vector2i(1, -1)
const DIRECCION_ABAJO_IZQUIERDA := Vector2i(-1, 1)
const DIRECCION_ABAJO_DERECHA := Vector2i(1, 1)
const DIRECCIONES_VALIDAS: Array[Vector2i] = [
	DIRECCION_ARRIBA,
	DIRECCION_ABAJO,
	DIRECCION_IZQUIERDA,
	DIRECCION_DERECHA,
	DIRECCION_ARRIBA_IZQUIERDA,
	DIRECCION_ARRIBA_DERECHA,
	DIRECCION_ABAJO_IZQUIERDA,
	DIRECCION_ABAJO_DERECHA,
]

# Normaliza un movimiento y devuelve solo su direccion valida.
static func obtener_direccion(movimiento: Vector2i) -> Vector2i:
	if movimiento == Vector2i.ZERO:
		return Vector2i.ZERO

	var direccion := Vector2i(signi(movimiento.x), signi(movimiento.y))
	if direccion.x != 0 and direccion.y != 0 and absi(movimiento.x) != absi(movimiento.y):
		return Vector2i.ZERO

	return direccion


# Calcula la cantidad de casillas que representa un movimiento.
static func obtener_cantidad(movimiento: Vector2i) -> int:
	return maxi(absi(movimiento.x), absi(movimiento.y))


# Devuelve una direccion random valida usando el generador indicado.
static func obtener_direccion_random(generador_random: RandomNumberGenerator) -> Vector2i:
	var indice := generador_random.randi_range(0, DIRECCIONES_VALIDAS.size() - 1)
	return DIRECCIONES_VALIDAS[indice]
