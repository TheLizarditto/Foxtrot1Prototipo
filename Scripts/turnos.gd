extends Node2D

@export var ruta_baraja: NodePath = "../Baraja"
@export var ruta_mazo_robo: NodePath = "../MazoRobo"
@export var ruta_mazo_descarte: NodePath = "../MazoDescarte"

@onready var baraja: Baraja = get_node(ruta_baraja)
@onready var mazo_robo: MazoRobo = get_node(ruta_mazo_robo)
@onready var mazo_descarte: MazoDescarte = get_node(ruta_mazo_descarte)
@onready var boton_turno: TextureButton = $BotonTurno

var turno_actual: int = 0

# Prepara el primer turno cuando el nodo entra en escena.
func _ready() -> void:
	await iniciar_primer_turno()


# Genera la baraja inicial, la mezcla y la carga en el mazo de robo con animacion.
func iniciar_primer_turno() -> void:
	if turno_actual != 0:
		return

	_bloquear_boton_turno(true)
	baraja.generar_cartas_random()
	baraja.mezclar()
	await mazo_robo.cargar_cartas_animadas(baraja.obtener_cartas())
	avanzar_turno()
	_bloquear_boton_turno(false)


# Avanza exactamente un turno cada vez que se llama.
func avanzar_turno() -> void:
	turno_actual += 1

# Responde al boton de turno avanzando al siguiente turno.
func _al_presionar_boton_turno() -> void:
	avanzar_turno()


# Recarga el mazo de robo desde el descarte cuando no quedan cartas para robar.
func recargar_mazo_robo_si_hace_falta() -> bool:
	if not mazo_robo.esta_vacio():
		return true

	_bloquear_boton_turno(true)
	var pudo_recargar := await mazo_robo.recargar_desde_descarte(mazo_descarte)
	_bloquear_boton_turno(false)

	return pudo_recargar


# Activa o desactiva el boton de turno mientras se resuelven acciones.
func _bloquear_boton_turno(bloqueado: bool) -> void:
	boton_turno.disabled = bloqueado
