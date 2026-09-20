extends Node2D
class_name MazoDescarte

var cartas: Array[Dictionary] = []

# Carga las cartas recibidas en el mazo de descarte.
func cargar_cartas(datos_cartas: Array[Dictionary]) -> void:
	vaciar()

	for datos in datos_cartas:
		recibir_carta(datos)


# Vacia todas las cartas guardadas en el mazo de descarte.
func vaciar() -> void:
	cartas.clear()


# Recibe una carta jugada y la guarda al final del mazo de descarte.
func recibir_carta(datos: Dictionary) -> void:
	cartas.append(Carta.normalizar_datos(datos))


# Devuelve todas las cartas del descarte en orden y deja el mazo vacio.
func entregar_cartas() -> Array[Dictionary]:
	var cartas_entregadas := obtener_cartas()
	vaciar()

	return cartas_entregadas


# Devuelve una copia de los datos de todas las cartas del mazo de descarte.
func obtener_cartas() -> Array[Dictionary]:
	var copia_cartas: Array[Dictionary] = []

	for datos in cartas:
		copia_cartas.append(datos.duplicate(true))

	return copia_cartas


# Devuelve la cantidad de cartas guardadas en el mazo de descarte.
func cantidad() -> int:
	return cartas.size()


# Indica si el mazo de descarte no tiene cartas disponibles.
func esta_vacio() -> bool:
	return cartas.is_empty()
