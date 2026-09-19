extends Node2D
class_name Baraja

const ESCENA_CARTA := preload("res://Scenes/carta.tscn")

@export var cantidad_cartas := 20
@export var min_movimientos := 2
@export var max_movimientos := Carta.MAX_MOVIMIENTOS
@export var min_pasos_movimiento := 1
@export var max_pasos_movimiento := 2
@export var min_ataque := 0
@export var max_ataque := 3
@export var min_defensa := 0
@export var max_defensa := 3

var cartas: Array[Dictionary] = []
var generador_random := RandomNumberGenerator.new()
var random_inicializado := false

# Inicializa el generador random de la baraja.
func _ready() -> void:
	_inicializar_random()


# Guarda los datos de las cartas de la baraja y las prepara como una cola.
func crear_cartas(datos_cartas: Array[Dictionary]) -> void:
	cartas.clear()

	for datos in datos_cartas:
		cartas.append(_normalizar_datos_carta(datos))


# Genera cartas random usando los valores minimos y maximos configurados.
func generar_cartas_random(cantidad_a_generar := -1) -> void:
	_inicializar_random()

	var total := cantidad_cartas if cantidad_a_generar < 0 else cantidad_a_generar
	var datos_cartas: Array[Dictionary] = []

	for _indice in range(maxi(total, 0)):
		datos_cartas.append(_crear_datos_carta_random())

	crear_cartas(datos_cartas)


# Mezcla el orden de la baraja de cartas.
func mezclar() -> void:
	cartas.shuffle()


# Devuelve los datos de la proxima carta de la baraja.
func robar_carta() -> Dictionary:
	if cartas.is_empty():
		return {}

	var datos: Dictionary = cartas.pop_front()
	return datos.duplicate(true)


# Devuelve la cantidad de cartas guardadas en la baraja.
func cantidad() -> int:
	return cartas.size()


# Devuelve una copia de los datos de todas las cartas de la baraja.
func obtener_cartas() -> Array[Dictionary]:
	var copia_cartas: Array[Dictionary] = []

	for datos in cartas:
		copia_cartas.append(datos.duplicate(true))

	return copia_cartas


# Instancia una carta visual a partir de los datos indicados.
func crear_carta_visual(datos: Dictionary) -> Node2D:
	var carta := ESCENA_CARTA.instantiate() as Node2D
	var datos_normalizados := _normalizar_datos_carta(datos)

	carta.set("movimientos", datos_normalizados["movimientos"])
	carta.set("ataque", datos_normalizados["ataque"])
	carta.set("defensa", datos_normalizados["defensa"])

	return carta


# Crea los datos de una carta random respetando los limites configurados.
func _crear_datos_carta_random() -> Dictionary:
	return {
		"movimientos": _crear_movimientos_random(),
		"ataque": _obtener_entero_ordenado(min_ataque, max_ataque),
		"defensa": _obtener_entero_ordenado(min_defensa, max_defensa),
	}


# Inicializa el generador random una sola vez.
func _inicializar_random() -> void:
	if random_inicializado:
		return

	generador_random.randomize()
	random_inicializado = true


# Crea la lista de movimientos random de una carta.
func _crear_movimientos_random() -> Array[Vector2i]:
	var movimientos: Array[Vector2i] = []
	var total_movimientos := _obtener_cantidad_movimientos_random()

	for _indice in range(total_movimientos):
		var direccion := Carta.obtener_direccion_random(generador_random)
		var pasos := _obtener_entero_ordenado(min_pasos_movimiento, max_pasos_movimiento)
		movimientos.append(direccion * maxi(pasos, 1))

	return movimientos


# Devuelve una cantidad random de movimientos sin superar el maximo que soporta la carta.
func _obtener_cantidad_movimientos_random() -> int:
	var minimo := clampi(min_movimientos, 0, Carta.MAX_MOVIMIENTOS)
	var maximo := clampi(max_movimientos, 0, Carta.MAX_MOVIMIENTOS)

	return _obtener_entero_ordenado(minimo, maximo)


# Devuelve un entero random aunque los limites esten cargados en orden inverso.
func _obtener_entero_ordenado(valor_minimo: int, valor_maximo: int) -> int:
	var minimo := mini(valor_minimo, valor_maximo)
	var maximo := maxi(valor_minimo, valor_maximo)

	return generador_random.randi_range(minimo, maximo)


# Normaliza los datos de una carta para que todas usen la misma estructura.
func _normalizar_datos_carta(datos: Dictionary) -> Dictionary:
	return {
		"movimientos": _copiar_movimientos(datos.get("movimientos", [])),
		"ataque": maxi(int(datos.get("ataque", 0)), 0),
		"defensa": maxi(int(datos.get("defensa", 0)), 0),
	}


# Copia los movimientos recibidos y conserva solo valores Vector2i.
func _copiar_movimientos(movimientos_originales: Variant) -> Array[Vector2i]:
	var movimientos: Array[Vector2i] = []

	if not movimientos_originales is Array:
		return movimientos

	for movimiento in movimientos_originales:
		if movimientos.size() >= Carta.MAX_MOVIMIENTOS:
			break

		if movimiento is Vector2i:
			movimientos.append(movimiento)

	return movimientos
