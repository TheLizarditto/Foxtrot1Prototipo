extends Node2D

@export var ruta_baraja: NodePath = "../Baraja"
@export var ruta_mazo_robo: NodePath = "../MazoRobo"

@onready var baraja: Baraja = get_node(ruta_baraja)
@onready var mazo_robo: MazoRobo = get_node(ruta_mazo_robo)
@onready var boton_turno: TextureButton = $BotonTurno

var turno_actual: int = 0

# Prepara el primer turno cuando el nodo entra en escena.
func _ready() -> void:
	await iniciar_primer_turno()


# Genera la baraja inicial, la mezcla y la carga en el mazo de robo con animacion.
func iniciar_primer_turno() -> void:
	if turno_actual != 0:
		return

	boton_turno.disabled = true
	baraja.generar_cartas_random()
	baraja.mezclar()
	await mazo_robo.cargar_cartas_animadas(baraja.obtener_cartas())
	avanzar_turno()
	boton_turno.disabled = false


# Avanza exactamente un turno cada vez que se llama.
func avanzar_turno() -> void:
	turno_actual += 1

# Responde al boton de turno avanzando al siguiente turno.
func _al_presionar_boton_turno() -> void:
	avanzar_turno()
