extends Node2D

@export var columnas := 5
@export var filas := 5

@onready var cuadro: Sprite2D = $Cuadro
@onready var tamano_celda := cuadro.texture.get_size()

func _ready() -> void:
	
	_generar_tablero()
	

func _obtener_inicio() -> Vector2:
	
	var tamano_tablero := Vector2(
		columnas * tamano_celda.x,
		filas * tamano_celda.y 
	)
	var inicio := -tamano_tablero / 2.0 + tamano_celda / 2.0
	
	return inicio

func obtener_centro_tablero() -> Vector2:
	return Vector2(
		floori(columnas / 2.0),
		floori(filas / 2.0)
	)
	
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

func _obtener_posicion_en_tablero(columna: int, fila: int) -> Vector2:
	
	if columna < 0 or columna >= columnas:
		return Vector2.ZERO
	
	if fila < 0 or fila >= filas:
		return Vector2.ZERO
	
	var inicio = _obtener_inicio()
	
	return inicio + Vector2(
		columna * tamano_celda.x,
		fila * tamano_celda.y
	)
