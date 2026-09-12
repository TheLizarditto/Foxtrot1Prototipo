extends Node2D

@export var ruta_tablero: NodePath = "../Tablero"

@onready var tablero = get_node(ruta_tablero)

var posicion := Vector2.ZERO

func _ready() -> void:
	_actualizar_posicion_centro()
	
func _process(_delta: float) -> void:
	pass
	
func _actualizar_posicion_centro() -> void:
	posicion = tablero.obtener_centro_tablero()
