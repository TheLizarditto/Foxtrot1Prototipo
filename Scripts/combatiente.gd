extends Node2D

signal vida_cambiada(actual: int, maxima: int)

@export var vida_maxima := 10:
	set(valor):
		vida_maxima = maxi(valor, 1)
		puntos_vida = mini(puntos_vida, vida_maxima)

var puntos_vida := 10:
	set(valor):
		puntos_vida = clampi(valor, 0, vida_maxima)
		vida_cambiada.emit(puntos_vida, vida_maxima)


func _ready() -> void:
	puntos_vida = vida_maxima


# Devuelve el dano efectivo y limita la vida a cero, sin aceptar dano negativo.
func recibir_dano(cantidad: int) -> int:
	var anterior := puntos_vida
	puntos_vida -= maxi(cantidad, 0)
	return anterior - puntos_vida
