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
	return GrillaJuego.obtener_inicio(columnas, filas, tamano_celda)

# Devuelve las coordenadas de grilla de la celda central del tablero.
func obtener_centro_tablero() -> Vector2:
	return GrillaJuego.obtener_centro(columnas, filas)
	
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
func _obtener_posicion_en_tablero(columna: int, fila: int) -> Vector2:
	return GrillaJuego.obtener_posicion_celda(columna, fila, columnas, filas, tamano_celda)
