extends Node2D
class_name Baraja

const ESCENA_CARTA := preload("res://Scenes/carta.tscn")

var cartas: Array[Node2D] = []

# Instancia todas las cartas de la baraja y las guarda como una cola.
func crear_cartas(datos_cartas: Array[Dictionary]) -> void:
	for carta in cartas:
		if is_instance_valid(carta):
			carta.queue_free()

	cartas.clear()

	for datos in datos_cartas:
		var carta := ESCENA_CARTA.instantiate()
		var movimientos: Array[Vector2i] = []
		for movimiento in datos.get("movimientos", []):
			movimientos.append(movimiento)

		carta.movimientos = movimientos
		carta.ataque = datos.get("ataque", 0)
		carta.defensa = datos.get("defensa", 0)
		add_child(carta)
		cartas.append(carta)


# Mezcla el orden de la baraja de cartas.
func mezclar() -> void:
	cartas.shuffle()


# Devuelve la proxima carta de la baraja.
func robar_carta() -> Node2D:
	if cartas.is_empty():
		return null

	var carta: Node2D = cartas.pop_front()
	remove_child(carta)
	return carta


func cantidad() -> int:
	return cartas.size()
