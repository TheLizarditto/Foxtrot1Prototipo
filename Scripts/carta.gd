extends Node2D
class_name Carta

const TEXTURA_ATAQUE := preload("res://Assets/Carta/miniespada.png")
const TEXTURA_DEFENSA := preload("res://Assets/Carta/miniescudo.png")
const MAX_MOVIMIENTOS := 4
const TAMANO_ICONO := Vector2(10, 10)
const TAMANO_FUENTE := 10
const TEXTURAS_MOVIMIENTO := {
	MovimientosCarta.DIRECCION_ARRIBA: preload("res://Assets/Carta/miniflechaarriba.png"),
	MovimientosCarta.DIRECCION_ABAJO: preload("res://Assets/Carta/miniflechaabajo.png"),
	MovimientosCarta.DIRECCION_IZQUIERDA: preload("res://Assets/Carta/miniflechaizquierda.png"),
	MovimientosCarta.DIRECCION_DERECHA: preload("res://Assets/Carta/miniflechaderecha.png"),
	MovimientosCarta.DIRECCION_ARRIBA_IZQUIERDA: preload("res://Assets/Carta/miniflechaarribaizquierda.png"),
	MovimientosCarta.DIRECCION_ARRIBA_DERECHA: preload("res://Assets/Carta/miniflechaarribaderecha.png"),
	MovimientosCarta.DIRECCION_ABAJO_IZQUIERDA: preload("res://Assets/Carta/miniflechaabajoizquierda.png"),
	MovimientosCarta.DIRECCION_ABAJO_DERECHA: preload("res://Assets/Carta/miniflechaabajoderecha.png"),
}

@export var tamano_carta := Vector2i(96, 128)
@export var sprite_fondo: Texture2D
@export var movimientos: Array[Vector2i] = []
@export var ataque := 0
@export var defensa := 0
@export var ruta_personaje: NodePath = "../Personaje"
@export var delay_entre_movimientos := 0.5

@onready var fondo: Sprite2D = $Fondo
@onready var movimientos_contenedor: HBoxContainer = $Contenido/Movimientos
@onready var atributos_contenedor: HBoxContainer = $Contenido/Atributos

var ejecutando := false

# Inicializa la carta, ajusta sus valores y muestra movimientos y atributos.
func _ready() -> void:
	ataque = maxi(ataque, 0)
	defensa = maxi(defensa, 0)
	delay_entre_movimientos = maxf(delay_entre_movimientos, 0.0)
	_limitar_movimientos()

	InterfazJuego.ajustar_sprite(fondo, sprite_fondo, Vector2(tamano_carta))

	_mostrar_movimientos()
	_mostrar_atributos()


# Ejecuta los movimientos de la carta sobre el personaje indicado.
func ejecutar(personaje: Node = null) -> void:
	if ejecutando:
		return

	if personaje == null:
		personaje = _obtener_personaje()

	if personaje == null or not personaje.has_method("movimiento"):
		push_warning("La carta no encontro un personaje valido para ejecutar movimientos.")
		return

	ejecutando = true
	var movimientos_validos := _obtener_movimientos_validos()

	for indice in range(movimientos_validos.size()):
		personaje.movimiento(movimientos_validos[indice])

		if indice < movimientos_validos.size() - 1 and delay_entre_movimientos > 0.0:
			await get_tree().create_timer(delay_entre_movimientos).timeout

	ejecutando = false


# Muestra cada movimiento de izquierda a derecha como flecha y cantidad.
# Por ejemplo, Vector2i(2, 0) se representa con la flecha derecha y el numero 2.
func _mostrar_movimientos() -> void:
	var movimientos_agrupados: Array[Vector2i] = []

	for movimiento in _obtener_movimientos_validos():
		var direccion := MovimientosCarta.obtener_direccion(movimiento)
		var cantidad := MovimientosCarta.obtener_cantidad(movimiento)

		# Dos movimientos consecutivos iguales se muestran como una sola cantidad.
		if not movimientos_agrupados.is_empty() and MovimientosCarta.obtener_direccion(movimientos_agrupados[-1]) == direccion:
			movimientos_agrupados[-1] += direccion * cantidad
		else:
			movimientos_agrupados.append(direccion * cantidad)

	for movimiento in movimientos_agrupados:
		InterfazJuego.crear_indicador(
			movimientos_contenedor,
			_obtener_textura_movimiento(MovimientosCarta.obtener_direccion(movimiento)),
			MovimientosCarta.obtener_cantidad(movimiento),
			TAMANO_ICONO,
			TAMANO_FUENTE
		)

	movimientos_contenedor.visible = movimientos_contenedor.get_child_count() > 0


# Ataque y defensa usan un unico icono cada uno, siempre a la izquierda del valor.
func _mostrar_atributos() -> void:
	if ataque > 0:
		InterfazJuego.crear_indicador(atributos_contenedor, TEXTURA_ATAQUE, ataque, TAMANO_ICONO, TAMANO_FUENTE)

	if defensa > 0:
		InterfazJuego.crear_indicador(atributos_contenedor, TEXTURA_DEFENSA, defensa, TAMANO_ICONO, TAMANO_FUENTE)

	atributos_contenedor.visible = atributos_contenedor.get_child_count() > 0


# Deja la lista de movimientos con el maximo permitido.
func _limitar_movimientos() -> void:
	if movimientos.size() <= MAX_MOVIMIENTOS:
		return

	push_warning("La carta solo puede tener hasta %s movimientos. Se ignoraron los movimientos extra." % MAX_MOVIMIENTOS)
	movimientos.resize(MAX_MOVIMIENTOS)


# Devuelve los movimientos validos en orden, respetando el limite de la carta.
func _obtener_movimientos_validos() -> Array[Vector2i]:
	var movimientos_validos: Array[Vector2i] = []

	for indice in range(mini(movimientos.size(), MAX_MOVIMIENTOS)):
		var movimiento := movimientos[indice]
		var direccion := MovimientosCarta.obtener_direccion(movimiento)
		var cantidad := MovimientosCarta.obtener_cantidad(movimiento)

		if direccion == Vector2i.ZERO or cantidad == 0:
			push_warning("Movimiento invalido en carta: %s" % movimiento)
			continue

		movimientos_validos.append(direccion * cantidad)

	return movimientos_validos


# Busca el personaje asignado o, como respaldo, uno llamado Personaje en la escena.
func _obtener_personaje() -> Node:
	var personaje := get_node_or_null(ruta_personaje)
	if personaje != null:
		return personaje

	if get_tree().current_scene == null:
		return null

	return get_tree().current_scene.find_child("Personaje", true, false)


# Devuelve la textura de flecha correspondiente a una direccion.
func _obtener_textura_movimiento(direccion: Vector2i) -> Texture2D:
	return TEXTURAS_MOVIMIENTO.get(direccion, null) as Texture2D
