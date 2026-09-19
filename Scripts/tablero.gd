extends Node2D

@export var columnas := 5
@export var filas := 5

@onready var cuadro: Sprite2D = $Cuadro
@onready var tamano_celda := cuadro.texture.get_size()

# Genera las celdas del tablero cuando el nodo entra en escena.
func _ready() -> void:
	
	_generar_tablero()
	

# Calcula y devuelve la posicion local de la primera celda del tablero.
func _obtener_inicio() -> Vector2:
	
	var tamano_tablero := Vector2(
		columnas * tamano_celda.x,
		filas * tamano_celda.y 
	)
	var inicio := -tamano_tablero / 2.0 + tamano_celda / 2.0
	
	return inicio

# Devuelve las coordenadas de grilla de la celda central del tablero.
func obtener_centro_tablero() -> Vector2:
	return Vector2(
		floori(columnas / 2.0),
		floori(filas / 2.0)
	)
	
# Crea o duplica los sprites de celda y los ubica en sus posiciones.
func _generar_tablero() -> void:
	
	var inicio = _obtener_inicio()
	
	for fila in filas:
		for columna in columnas:
			var celda: Sprite2D
			if fila == 0 and columna == 0:
				celda = cuadro
			else:
				celda = cuadro.duplicate()
				add_child(celda)

			celda.position = inicio + Vector2(columna * tamano_celda.x, fila * tamano_celda.y)

# Recibe columna y fila, valida que existan y devuelve la posicion local de esa celda.
func obtener_posicion_en_tablero(columna: int, fila: int) -> Vector2:
	
	if not es_posicion_valida(columna, fila):
		return Vector2.ZERO
	
	var inicio = _obtener_inicio()
	
	return inicio + Vector2(
		columna * tamano_celda.x,
		fila * tamano_celda.y
	)


# Devuelve la posicion de grilla limitada al tamano del tablero.
func limitar_posicion_en_tablero(posicion: Vector2) -> Vector2:
	return Vector2(
		clampi(int(posicion.x), 0, columnas - 1),
		clampi(int(posicion.y), 0, filas - 1)
	)


# Indica si una posicion de grilla existe dentro del tablero.
func es_posicion_valida(columna: int, fila: int) -> bool:
	return columna >= 0 and columna < columnas and fila >= 0 and fila < filas
