extends Node2D

@onready var baraja: Baraja = $Baraja


# Genera y mezcla la baraja inicial cuando la escena principal esta lista.
func _ready() -> void:
	baraja.generar_cartas_random()
	baraja.mezclar()
