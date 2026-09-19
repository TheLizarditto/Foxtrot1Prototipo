extends RefCounted
class_name GrillaJuego

# Calcula y devuelve la posicion local de la primera celda de una grilla centrada.
static func obtener_inicio(columnas: int, filas: int, tamano_celda: Vector2) -> Vector2:
	var tamano_grilla := Vector2(columnas * tamano_celda.x, filas * tamano_celda.y)
	return -tamano_grilla / 2.0 + tamano_celda / 2.0


# Devuelve las coordenadas de la celda central de una grilla.
static func obtener_centro(columnas: int, filas: int) -> Vector2:
	return Vector2(floori(columnas / 2.0), floori(filas / 2.0))


# Indica si una coordenada existe dentro de la grilla.
static func es_posicion_valida(columna: int, fila: int, columnas: int, filas: int) -> bool:
	return columna >= 0 and columna < columnas and fila >= 0 and fila < filas


# Devuelve la posicion local de una celda valida dentro de una grilla centrada.
static func obtener_posicion_celda(columna: int, fila: int, columnas: int, filas: int, tamano_celda: Vector2) -> Vector2:
	if not es_posicion_valida(columna, fila, columnas, filas):
		return Vector2.ZERO

	return obtener_inicio(columnas, filas, tamano_celda) + Vector2(columna * tamano_celda.x, fila * tamano_celda.y)
