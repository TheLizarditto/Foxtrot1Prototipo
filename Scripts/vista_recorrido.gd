extends Node2D

const FUENTE := preload("res://Assets/Fonts/PressStart2P.ttf")
const BORDE := Color("222137")
const VERDE := Color("99e550") # Mismo RGB que Assets/Carta/miniflecha*.png.
const OPACIDAD_REPOSO := 0.4

# Mascaras propias de 13 px: bordes escalonados, sin suavizado ni giros fraccionarios.
const RECTA := [
	"......x......", ".....xxx.....", "....xxxxx....", "...xxxxxxx...",
	"..xxxxxxxxx..", ".xxxxxxxxxxx.", "....xxxxx....", "....xxxxx....",
	"....xxxxx....", "....xxxxx....", "....xxxxx....", "....xxxxx....",
	".............",
]
const DIAGONAL := [
	".............", "....xxxxxxxx.", ".....xxxxxxx.", "......xxxxxx.",
	".....xxxxxxx.", "....xxxxxxxx.", "...xxxxx.xxx.", "..xxxxx...xx.",
	".xxxxx.....x.", ".xxxx........", "..xx.........", ".............",
	".............",
]

var pasos: Array[Dictionary] = []
var texturas: Dictionary = {}
var tablero: Node2D
var mano: Mano
var personaje: Node2D
var indicadores: Array[Node2D] = []


func _ready() -> void:
	tablero = get_parent()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for direccion in Carta.DIRECCIONES_VALIDAS:
		texturas[direccion] = _crear_flecha(direccion)
	_vincular.call_deferred()


func _vincular() -> void:
	mano = tablero.get_node_or_null("../Mano") as Mano
	personaje = tablero.get_node_or_null("../Personaje") as Node2D
	if mano == null or personaje == null:
		return
	mano.cola_cambiada.connect(actualizar)
	mano.paso_cola_resuelto.connect(_al_resolver_paso)
	actualizar()


# Simula exactamente los pasos de Carta y Personaje: un intento fuera no avanza.
func actualizar() -> void:
	pasos.clear()
	var posicion := Vector2i(personaje.posicion)
	for datos in mano.cola:
		for movimiento in Carta.copiar_movimientos(datos.get("movimientos", [])):
			var direccion := Carta.obtener_direccion(movimiento)
			if direccion == Vector2i.ZERO:
				continue
			for _paso in range(Carta.obtener_cantidad(movimiento)):
				var destino := posicion + direccion
				if not tablero.es_posicion_valida(destino.x, destino.y):
					continue
				posicion = destino
				pasos.append({"posicion": posicion, "direccion": direccion, "orden": pasos.size() + 1})
	_reconstruir_indicadores()


func _al_resolver_paso(realizado: bool) -> void:
	if realizado and not pasos.is_empty():
		pasos.pop_front()
		_reconstruir_indicadores()


func _process(_delta: float) -> void:
	_actualizar_hover(get_global_mouse_position())


func _actualizar_hover(posicion_mouse: Vector2) -> void:
	for indicador in indicadores:
		var zona: Rect2 = indicador.get_meta("zona_hover")
		var resaltado := zona.has_point(indicador.to_local(posicion_mouse))
		indicador.modulate.a = 1.0 if resaltado else OPACIDAD_REPOSO
		# Solo el indicador bajo el mouse pasa delante del caballero.
		indicador.z_index = 5 if resaltado else 0


func _reconstruir_indicadores() -> void:
	for indicador in indicadores:
		remove_child(indicador)
		indicador.queue_free()
	indicadores.clear()
	var por_celda: Dictionary = {}
	for indice in range(pasos.size()):
		var celda: Vector2i = pasos[indice]["posicion"]
		if not por_celda.has(celda):
			por_celda[celda] = []
		por_celda[celda].append(indice)
	for celda in por_celda:
		var indices: Array = por_celda[celda]
		var columnas := ceili(sqrt(float(indices.size())))
		var filas := ceili(float(indices.size()) / columnas)
		var espacio: Vector2 = (tablero.tamano_celda - Vector2(8, 8)) / Vector2(columnas, filas)
		var centro: Vector2 = tablero.obtener_posicion_en_tablero(celda.x, celda.y)
		for lugar in range(indices.size()):
			var indice: int = indices[lugar]
			var desplazamiento := Vector2(lugar % columnas, floori(float(lugar) / columnas))
			var origen := (centro + (desplazamiento + Vector2(0.5, 0.5) - Vector2(columnas, filas) / 2.0) * espacio).round()
			var escala := minf(2.0, minf(espacio.x / 22.0, espacio.y / 23.0))
			var tamano := Vector2(15, 15) * escala
			var rectangulo := Rect2((-tamano / 2.0 - Vector2(0, 4)).round(), tamano)
			var numero := str(pasos[indice]["orden"])
			var fuente_tamano := maxi(6, floori(8.0 * minf(escala, 1.0)))
			var ancho := FUENTE.get_string_size(numero, HORIZONTAL_ALIGNMENT_LEFT, -1, fuente_tamano).x
			var texto := Vector2(-ancho / 2.0, tamano.y / 2.0 + 5).round()
			var indicador := Node2D.new()
			indicador.position = origen
			indicador.z_as_relative = false
			var zona_numero := Rect2(texto - Vector2(0, FUENTE.get_ascent(fuente_tamano)), Vector2(ancho, FUENTE.get_height(fuente_tamano)))
			indicador.set_meta("zona_hover", rectangulo.merge(zona_numero).grow(3.0))
			indicador.draw.connect(_dibujar_indicador.bind(indicador, texturas[pasos[indice]["direccion"]], rectangulo, texto, numero, fuente_tamano))
			add_child(indicador)
			indicadores.append(indicador)
	_actualizar_hover(get_global_mouse_position())


func _dibujar_indicador(indicador: Node2D, textura: Texture2D, rectangulo: Rect2, texto: Vector2, numero: String, fuente_tamano: int) -> void:
	indicador.draw_texture_rect(textura, rectangulo, false)
	indicador.draw_string_outline(FUENTE, texto, numero, HORIZONTAL_ALIGNMENT_LEFT, -1, fuente_tamano, 3, BORDE)
	indicador.draw_string(FUENTE, texto, numero, HORIZONTAL_ALIGNMENT_LEFT, -1, fuente_tamano, VERDE)


func _crear_flecha(direccion: Vector2i) -> Texture2D:
	var pixeles: Array[Vector2i] = []
	var diagonal := direccion.x != 0 and direccion.y != 0
	var mascara: Array = DIAGONAL if diagonal else RECTA
	for y in range(13):
		for x in range(13):
			if mascara[y][x] != "x":
				continue
			var punto := Vector2i(x - 6, y - 6)
			if diagonal:
				punto *= Vector2i(direccion.x, -direccion.y)
			elif direccion.y == 1:
				punto = -punto
			elif direccion.x != 0:
				punto = Vector2i(-punto.y * direccion.x, punto.x * direccion.x)
			pixeles.append(punto + Vector2i(7, 7))
	var imagen := Image.create(15, 15, false, Image.FORMAT_RGBA8)
	imagen.fill(Color.TRANSPARENT)
	for punto in pixeles:
		for vecino in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			imagen.set_pixelv(punto + vecino, BORDE)
	for punto in pixeles:
		imagen.set_pixelv(punto, VERDE)
	return ImageTexture.create_from_image(imagen)
