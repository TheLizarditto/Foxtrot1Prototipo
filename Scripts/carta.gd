extends Node2D

const TEXTURA_ARRIBA := preload("res://Assets/Carta/miniflechaarriba.png")
const TEXTURA_ABAJO := preload("res://Assets/Carta/miniflechaabajo.png")
const TEXTURA_IZQUIERDA := preload("res://Assets/Carta/miniflechaizquierda.png")
const TEXTURA_DERECHA := preload("res://Assets/Carta/miniflechaderecha.png")
const TEXTURA_ARRIBA_IZQUIERDA := preload("res://Assets/Carta/miniflechaarribaizquierda.png")
const TEXTURA_ARRIBA_DERECHA := preload("res://Assets/Carta/miniflechaarribaderecha.png")
const TEXTURA_ABAJO_IZQUIERDA := preload("res://Assets/Carta/miniflechaabajoizquierda.png")
const TEXTURA_ABAJO_DERECHA := preload("res://Assets/Carta/miniflechaabajoderecha.png")
const TEXTURA_ATAQUE := preload("res://Assets/Carta/miniespada.png")
const TEXTURA_DEFENSA := preload("res://Assets/Carta/miniescudo.png")
const MAX_MOVIMIENTOS := 4
const TAMANO_ICONO := Vector2(10, 10)
const TAMANO_FUENTE := 10

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

	fondo.texture = sprite_fondo
	if sprite_fondo != null:
		fondo.scale = Vector2(tamano_carta) / sprite_fondo.get_size()

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
		var direccion := _obtener_direccion(movimiento)
		var cantidad := _obtener_cantidad(movimiento)

		# Dos movimientos consecutivos iguales se muestran como una sola cantidad.
		if not movimientos_agrupados.is_empty() and _obtener_direccion(movimientos_agrupados[-1]) == direccion:
			movimientos_agrupados[-1] += direccion * cantidad
		else:
			movimientos_agrupados.append(direccion * cantidad)

	for movimiento in movimientos_agrupados:
		_crear_indicador(
			movimientos_contenedor,
			_obtener_textura_movimiento(_obtener_direccion(movimiento)),
			_obtener_cantidad(movimiento)
		)

	movimientos_contenedor.visible = movimientos_contenedor.get_child_count() > 0


# Ataque y defensa usan un unico icono cada uno, siempre a la izquierda del valor.
func _mostrar_atributos() -> void:
	if ataque > 0:
		_crear_indicador(atributos_contenedor, TEXTURA_ATAQUE, ataque)

	if defensa > 0:
		_crear_indicador(atributos_contenedor, TEXTURA_DEFENSA, defensa)

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
		var direccion := _obtener_direccion(movimiento)
		var cantidad := _obtener_cantidad(movimiento)

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


# Crea un indicador visual con icono y numero dentro del contenedor indicado.
func _crear_indicador(contenedor: HBoxContainer, textura: Texture2D, cantidad: int) -> void:
	var indicador := HBoxContainer.new()
	indicador.add_theme_constant_override("separation", 1)
	indicador.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	contenedor.add_child(indicador)

	var icono := TextureRect.new()
	icono.custom_minimum_size = TAMANO_ICONO
	icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icono.texture = textura
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	indicador.add_child(icono)

	var numero := Label.new()
	numero.text = str(cantidad)
	numero.add_theme_font_size_override("font_size", TAMANO_FUENTE)
	numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	numero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	indicador.add_child(numero)


# Normaliza un movimiento y devuelve solo su direccion valida.
func _obtener_direccion(movimiento: Vector2i) -> Vector2i:
	if movimiento == Vector2i.ZERO:
		return Vector2i.ZERO

	var direccion := Vector2i(signi(movimiento.x), signi(movimiento.y))
	if direccion.x != 0 and direccion.y != 0 and absi(movimiento.x) != absi(movimiento.y):
		return Vector2i.ZERO

	return direccion


# Calcula la cantidad de casillas que representa un movimiento.
func _obtener_cantidad(movimiento: Vector2i) -> int:
	return maxi(absi(movimiento.x), absi(movimiento.y))


# Devuelve la textura de flecha correspondiente a una direccion.
func _obtener_textura_movimiento(direccion: Vector2i) -> Texture2D:
	match direccion:
		Vector2i(0, -1):
			return TEXTURA_ARRIBA
		Vector2i(0, 1):
			return TEXTURA_ABAJO
		Vector2i(-1, 0):
			return TEXTURA_IZQUIERDA
		Vector2i(1, 0):
			return TEXTURA_DERECHA
		Vector2i(-1, -1):
			return TEXTURA_ARRIBA_IZQUIERDA
		Vector2i(1, -1):
			return TEXTURA_ARRIBA_DERECHA
		Vector2i(-1, 1):
			return TEXTURA_ABAJO_IZQUIERDA
		Vector2i(1, 1):
			return TEXTURA_ABAJO_DERECHA
		_:
			return null
