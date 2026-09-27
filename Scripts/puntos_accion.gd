extends Node2D
class_name PuntosAccion

@export_range(0, 99, 1) var maximo_puntos_por_turno := 10

@onready var contador_puntos: Label = $ContadorPuntos

var puntos_disponibles := 0


# Inicia cada partida con todos los puntos disponibles.
func _ready() -> void:
	recargar()


# Restaura los puntos disponibles al máximo configurado para el nuevo turno.
func recargar() -> void:
	puntos_disponibles = maxi(maximo_puntos_por_turno, 0)
	_actualizar_contador()


# Devuelve los puntos que estarán disponibles para futuras acciones.
func cantidad() -> int:
	return puntos_disponibles


# Refleja el valor actual encima del sprite de puntos de acción.
func _actualizar_contador() -> void:
	if is_node_ready():
		contador_puntos.text = str(puntos_disponibles)
