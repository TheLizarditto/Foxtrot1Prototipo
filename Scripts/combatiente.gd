extends Node2D

signal vida_cambiada(actual: int, maxima: int)
signal escudo_cambiado(actual: int)

@export var vida_maxima := 10:
	set(valor):
		vida_maxima = maxi(valor, 1)
		puntos_vida = mini(puntos_vida, vida_maxima)

var puntos_vida := 10:
	set(valor):
		puntos_vida = clampi(valor, 0, vida_maxima)
		vida_cambiada.emit(puntos_vida, vida_maxima)

var escudo := 0:
	set(valor):
		escudo = maxi(valor, 0)
		escudo_cambiado.emit(escudo)


func _ready() -> void:
	puntos_vida = vida_maxima


func sincronizar_reposo(sprite: AnimatedSprite2D) -> void:
	var ritmo := get_node_or_null("../RitmoIdle")
	if ritmo != null:
		ritmo.registrar(sprite)


# El escudo absorbe primero; devuelve solo la vida perdida, sin aceptar dano negativo.
func recibir_dano(cantidad: int) -> int:
	var restante := maxi(cantidad, 0)
	var absorbido := mini(escudo, restante)
	if absorbido > 0:
		escudo -= absorbido
	var anterior := puntos_vida
	puntos_vida -= restante - absorbido
	return anterior - puntos_vida


func agregar_escudo(cantidad: int) -> void:
	if cantidad > 0:
		escudo += cantidad


func limpiar_escudo() -> void:
	if escudo > 0:
		escudo = 0
