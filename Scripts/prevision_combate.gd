extends Node

@onready var tablero: Node2D = $"../Tablero"
@onready var caballero: Node2D = $"../Personaje"
@onready var dragon: Node2D = $"../Enemigo"
@onready var mano: Mano = $"../Mano"
@onready var ataques: Node = $"../AtaquesDragon"
@onready var indicador_caballero: Node2D = $"../IndicadorCaballero"
@onready var indicador_dragon: Node2D = $"../IndicadorDragon"


func _ready() -> void:
	mano.cola_cambiada.connect(actualizar)
	mano.accion_en_curso_cambiada.connect(_al_cambiar_accion)
	mano.paso_cola_resuelto.connect(_al_resolver_paso)
	ataques.ataque_cambiado.connect(actualizar)
	caballero.escudo_cambiado.connect(_al_cambiar_escudo)
	dragon.escudo_cambiado.connect(_al_cambiar_escudo)
	actualizar()


func actualizar() -> void:
	var dano_al_dragon := 0
	var defensa := 0
	var celda := Vector2i(caballero.posicion)
	# Las cartas que ya se estan resolviendo impactan directo en los valores actuales.
	if not mano.resolviendo_cola:
		for carta in mano.cola:
			dano_al_dragon += carta.get("ataque", 0)
			defensa += carta.get("defensa", 0)
			celda = _celda_final(celda, carta.get("movimientos", []))
	var escudo_caballero: int = caballero.escudo + defensa
	var dano_al_caballero: int = ataques.obtener_dano_en(celda)
	indicador_caballero.mostrar(caballero.escudo, escudo_caballero, dano_al_caballero, maxi(dano_al_caballero - escudo_caballero, 0))
	indicador_dragon.mostrar(dragon.escudo, maxi(dragon.escudo - dano_al_dragon, 0), dano_al_dragon, maxi(dano_al_dragon - dragon.escudo, 0))


# Repite los pasos de la carta: los que salen del tablero se pierden sin mover al personaje.
func _celda_final(inicio: Vector2i, movimientos: Array) -> Vector2i:
	var celda := inicio
	for movimiento in movimientos:
		var direccion := Carta.obtener_direccion(movimiento)
		for _paso in range(Carta.obtener_cantidad(movimiento)):
			var destino := celda + direccion
			if direccion != Vector2i.ZERO and tablero.es_posicion_valida(destino.x, destino.y):
				celda = destino
	return celda


func _al_cambiar_accion(_en_curso: bool) -> void:
	actualizar()


func _al_resolver_paso(_realizado: bool) -> void:
	actualizar()


func _al_cambiar_escudo(_actual: int) -> void:
	actualizar()
