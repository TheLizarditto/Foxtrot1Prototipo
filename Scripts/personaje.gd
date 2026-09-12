extends Node2D

@export var ruta_tablero: NodePath = "../Tablero"

@onready var tablero = get_node(ruta_tablero)

var posicion := Vector2.ZERO

# Inicializa al personaje ubicandolo en el centro del tablero.
func _ready() -> void:
	_actualizar_posicion_centro()
	
# Recibe una direccion de movimiento y actualiza la posicion en la grilla.
func movimiento(direccion: Vector2i) -> void:
	posicion += Vector2(direccion)
	posicion.x = clampi(posicion.x, 0, tablero.columnas - 1)
	posicion.y = clampi(posicion.y, 0, tablero.filas - 1)
	_actualizar_sprite()
	
# Calcula la celda central del tablero y mueve ahi al personaje.
func _actualizar_posicion_centro() -> void:
	posicion = tablero.obtener_centro_tablero()
	_actualizar_sprite()

# Convierte la posicion de grilla del personaje a posicion global.
func _actualizar_sprite() -> void:
	global_position = tablero.to_global(
		tablero._obtener_posicion_en_tablero(int(posicion.x), int(posicion.y))
	)
