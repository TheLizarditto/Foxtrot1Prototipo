extends Node2D

@export var ruta_baraja: NodePath = "../Baraja"
@export var ruta_mazo_robo: NodePath = "../MazoRobo"
@export var ruta_mazo_descarte: NodePath = "../MazoDescarte"
@export var ruta_mano: NodePath = "../Mano"

@onready var baraja: Baraja = get_node(ruta_baraja)
@onready var mazo_robo: MazoRobo = get_node(ruta_mazo_robo)
@onready var mazo_descarte: MazoDescarte = get_node(ruta_mazo_descarte)
@onready var mano: Mano = get_node(ruta_mano)
@onready var boton_turno: TextureButton = $BotonTurno

const SELECCION_DESCARTE := preload("res://Scripts/seleccion_descarte.gd")

var turno_actual: int = 0
var pasando_turno := false
var seleccion_descarte: CanvasLayer

# Prepara el primer turno cuando el nodo entra en escena.
func _ready() -> void:
	mano.accion_en_curso_cambiada.connect(_al_cambiar_accion_mano)
	seleccion_descarte = SELECCION_DESCARTE.new()
	add_child(seleccion_descarte)
	await get_tree().process_frame
	await iniciar_primer_turno()


# Genera la baraja inicial, la mezcla y la carga en el mazo de robo con animacion.
func iniciar_primer_turno() -> void:
	if turno_actual != 0:
		return

	_bloquear_boton_turno(true)
	baraja.generar_cartas_random()
	baraja.mezclar()
	await mazo_robo.cargar_cartas_animadas(baraja.obtener_cartas())
	await mano.cargar_desde_mazo_animada(mazo_robo)
	avanzar_turno()
	_bloquear_boton_turno(false)


# Avanza exactamente un turno cada vez que se llama.
func avanzar_turno() -> void:
	turno_actual += 1

# Permite elegir descartes y confirmar antes de rellenar la mano y avanzar.
func _al_presionar_boton_turno() -> void:
	if mano.accion_en_curso or boton_turno.disabled or pasando_turno:
		return
	pasando_turno = true
	_bloquear_boton_turno(true)
	mano.preparar_seleccion_descarte()
	mano.visible = false
	seleccion_descarte.abrir(mano.obtener_cartas())
	var indices: Array[int] = await seleccion_descarte.confirmado
	mano.visible = true
	await mano.descartar_cartas(indices)
	await _rellenar_mano_para_siguiente_turno()
	avanzar_turno()
	pasando_turno = false
	mano.mano_lista_para_seleccion = not mano.esta_vacia()
	_bloquear_boton_turno(false)


func _al_cambiar_accion_mano(en_curso: bool) -> void:
	_bloquear_boton_turno(en_curso or pasando_turno)


# Roba solo las cartas necesarias; si el mazo se vacia, lo recarga desde el descarte.
func _rellenar_mano_para_siguiente_turno() -> void:
	while not mano.esta_llena():
		if mazo_robo.esta_vacio():
			if not await mazo_robo.recargar_desde_descarte(mazo_descarte):
				return

		if not await mano.robar_carta_animada(mazo_robo):
			return


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
