extends Node2D

@export var columnas := 5
@export var filas := 5

@onready var cuadro: Sprite2D = $Cuadro

func _ready() -> void:
	_generar_tablero()


func _generar_tablero() -> void:
	var tamano_celda := cuadro.texture.get_size()
	var paso := tamano_celda + Vector2(0, 0)
	var tamano_tablero := Vector2(
		columnas * tamano_celda.x ,
		filas * tamano_celda.y 
	)
	var inicio := -tamano_tablero / 2.0 + tamano_celda / 2.0
	for fila in filas:
		for columna in columnas:
			var celda: Sprite2D
			if fila == 0 and columna == 0:
				celda = cuadro
			else:
				celda = cuadro.duplicate()
				add_child(celda)

			celda.position = inicio + Vector2(columna * paso.x, fila * paso.y)
