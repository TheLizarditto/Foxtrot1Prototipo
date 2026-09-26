extends Node2D

@export var ruta_tablero: NodePath = "../Tablero"

@onready var tablero = get_node(ruta_tablero)

var posicion := Vector2.ZERO

# Inicializa al personaje ubicandolo en el centro del tablero.
func _ready() -> void:
	_actualizar_posicion_centro()
	
# Recibe un paso de movimiento y lo aplica solo si la celda destino existe.
func movimiento(direccion: Vector2i) -> bool:
	var paso := Vector2i(signi(direccion.x), signi(direccion.y))
	if paso == Vector2i.ZERO:
		return false

	var destino := Vector2i(posicion) + paso
	if not tablero.es_posicion_valida(destino.x, destino.y):
		return false

	posicion = destino
	_actualizar_sprite()
	return true
	
# Calcula la celda central del tablero y mueve ahi al personaje.
func _actualizar_posicion_centro() -> void:
	posicion = tablero.obtener_centro_tablero()
	_actualizar_sprite()

# Convierte la posicion de grilla del personaje a posicion global.
func _actualizar_sprite() -> void:
	global_position = tablero.to_global(
		tablero.obtener_posicion_en_tablero(int(posicion.x), int(posicion.y))
	)
