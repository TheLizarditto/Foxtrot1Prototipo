extends Node2D

@export var ruta_tablero: NodePath = "../Tablero"

@onready var tablero = get_node(ruta_tablero)

var posicion := Vector2.ZERO

# Inicializa al personaje ubicandolo en el centro del tablero.
func _ready() -> void:
	_actualizar_posicion_centro()
	
# Recibe una direccion de movimiento y actualiza la posicion en la grilla.
func movimiento(direccion: Vector2i) -> void:
	posicion = tablero.limitar_posicion_en_tablero(posicion + Vector2(direccion))
	_actualizar_sprite()
	
# Calcula la celda central del tablero y mueve ahi al personaje.
func _actualizar_posicion_centro() -> void:
	posicion = tablero.obtener_centro_tablero()
	_actualizar_sprite()

# Convierte la posicion de grilla del personaje a posicion global.
func _actualizar_sprite() -> void:
	global_position = tablero.to_global(
		tablero.obtener_posicion_en_tablero(int(posicion.x), int(posicion.y))
	)
