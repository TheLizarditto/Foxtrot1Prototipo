extends Node2D

const TEXTURA_ARRIBA := preload("res://Assets/miniflechaarriba.png")
const TEXTURA_ABAJO := preload("res://Assets/miniflechaabajo.png")
const TEXTURA_IZQUIERDA := preload("res://Assets/miniflechaizquierda.png")
const TEXTURA_DERECHA := preload("res://Assets/miniflechaderecha.png")
const TEXTURA_ARRIBA_IZQUIERDA := preload("res://Assets/miniflechaarribaizquierda.png")
const TEXTURA_ARRIBA_DERECHA := preload("res://Assets/miniflechaarribaderecha.png")
const TEXTURA_ABAJO_IZQUIERDA := preload("res://Assets/miniflechaabajoizquierda.png")
const TEXTURA_ABAJO_DERECHA := preload("res://Assets/miniflechaabajoderecha.png")
const TEXTURA_ATAQUE := preload("res://Assets/miniespada.png")
const TEXTURA_DEFENSA := preload("res://Assets/miniescudo.png")
const TAMANO_ICONO := Vector2(10, 10)
const TAMANO_FUENTE := 10

@export var tamano_carta := Vector2i(96, 128)
@export var sprite_fondo: Texture2D
@export var movimientos: Array[Vector2i] = []
@export var ataque := 0
@export var defensa := 0

@onready var fondo: Sprite2D = $Fondo
@onready var movimientos_contenedor: HBoxContainer = $Contenido/Movimientos
@onready var atributos_contenedor: HBoxContainer = $Contenido/Atributos

func _ready() -> void:
	ataque = maxi(ataque, 0)
	defensa = maxi(defensa, 0)

	fondo.texture = sprite_fondo
	if sprite_fondo != null:
		fondo.scale = Vector2(tamano_carta) / sprite_fondo.get_size()

	_mostrar_movimientos()
	_mostrar_atributos()


# Muestra cada movimiento de izquierda a derecha como flecha y cantidad.
# Por ejemplo, Vector2i(2, 0) se representa con la flecha derecha y el numero 2.
func _mostrar_movimientos() -> void:
	var movimientos_agrupados: Array[Vector2i] = []

	for movimiento in movimientos:
		var direccion := _obtener_direccion(movimiento)
		var cantidad := _obtener_cantidad(movimiento)

		if direccion == Vector2i.ZERO or cantidad == 0:
			push_warning("Movimiento invalido en carta: %s" % movimiento)
			continue

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


func _obtener_direccion(movimiento: Vector2i) -> Vector2i:
	if movimiento == Vector2i.ZERO:
		return Vector2i.ZERO

	var direccion := Vector2i(signi(movimiento.x), signi(movimiento.y))
	if direccion.x != 0 and direccion.y != 0 and absi(movimiento.x) != absi(movimiento.y):
		return Vector2i.ZERO

	return direccion


func _obtener_cantidad(movimiento: Vector2i) -> int:
	return maxi(absi(movimiento.x), absi(movimiento.y))


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
