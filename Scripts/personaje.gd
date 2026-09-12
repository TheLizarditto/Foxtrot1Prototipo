extends Node2D

@export var ruta_tablero: NodePath = "../Tablero"

@onready var tablero = get_node(ruta_tablero)

var posicion := Vector2.ZERO

func _ready() -> void:
	_actualizar_posicion_centro()
	
# Las cartas invocaran esta funcion con un vector de direccion.
func movimiento(direccion: Vector2i) -> void:
	posicion += Vector2(direccion)
	posicion.x = clampi(posicion.x, 0, tablero.columnas - 1)
	posicion.y = clampi(posicion.y, 0, tablero.filas - 1)
	_actualizar_sprite()
	
func _actualizar_posicion_centro() -> void:
	posicion = tablero.obtener_centro_tablero()
	_actualizar_sprite()

func _actualizar_sprite() -> void:
	global_position = tablero.to_global(
		tablero._obtener_posicion_en_tablero(int(posicion.x), int(posicion.y))
	)
