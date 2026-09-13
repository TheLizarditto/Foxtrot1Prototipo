extends Node2D

var turno_actual: int = 0

# Avanza exactamente un turno cada vez que se llama.
func avanzar_turno() -> void:
	turno_actual += 1

func _al_presionar_boton_turno() -> void:
	avanzar_turno()
