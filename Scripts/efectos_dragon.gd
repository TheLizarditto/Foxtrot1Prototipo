extends Node2D

signal impacto

const FUEGO_ORIGINAL := preload("res://Assets/Dragon2/femDrag_FireAttack.png")
const OSCURO := Color("7d202b")
const ROJO := Color("d83e32")
const NARANJA := Color("f18b35")
const CLARO := Color("ffe5a3")

var tipo := 0
var fase := 0
var progreso := 0.0
var puntos: Array[Vector2] = []
var origen := Vector2.ZERO
var centro := Vector2.ZERO
var tamano_celda := Vector2(64, 64)
var llama: AtlasTexture


func _ready() -> void:
	z_index = 4
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false
	llama = AtlasTexture.new()
	llama.atlas = FUEGO_ORIGINAL
	llama.region = Rect2(9, 12, 16, 18)


func reproducir(ataque: int, celdas: Array[Vector2i], tablero: Node2D, boca: Vector2) -> void:
	tipo = ataque
	fase = 0
	progreso = 0.0
	origen = to_local(boca)
	tamano_celda = tablero.tamano_celda
	puntos.clear()
	centro = Vector2.ZERO
	for celda in celdas:
		var punto := to_local(tablero.to_global(tablero.obtener_posicion_en_tablero(celda.x, celda.y)))
		puntos.append(punto)
		centro += punto
	centro /= maxf(puntos.size(), 1.0)
	visible = true
	var tween := create_tween()
	tween.tween_method(_avanzar, 0.0, 1.0, 0.42 if tipo == 0 else 0.24)
	await tween.finished
	fase = 1
	progreso = 0.0
	impacto.emit()
	tween = create_tween()
	tween.tween_method(_avanzar, 0.0, 1.0, 0.55 if tipo == 0 else 0.35)
	await tween.finished
	visible = false
	queue_redraw()


func _avanzar(valor: float) -> void:
	progreso = valor
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	match tipo:
		0: _dibujar_fuego()
		1: _dibujar_garras()
		2: _dibujar_mordida()


func _dibujar_fuego() -> void:
	if fase == 0:
		var posicion := origen.lerp(centro, progreso).round()
		for indice in range(5, 0, -1):
			var anterior := origen.lerp(centro, maxf(progreso - indice * 0.035, 0.0)).round()
			var lado := float(14 - indice * 2)
			draw_rect(Rect2(anterior - Vector2.ONE * lado / 2.0, Vector2.ONE * lado), Color(0.94, 0.33, 0.1, 0.55))
		_bola(posicion, 16.0)
		return
	for indice in range(puntos.size()):
		var punto := puntos[indice]
		var opacidad := 1.0 - progreso
		var altura := 36.0 + sin(progreso * TAU * 2.0 + indice) * 6.0
		draw_rect(Rect2(punto - tamano_celda * 0.43, tamano_celda * 0.86), Color(0.9, 0.25, 0.06, opacidad * 0.22))
		draw_texture_rect(llama, Rect2((punto - Vector2(20, altura - 12)).round(), Vector2(40, altura)), false, Color(1, 1, 1, opacidad))
		for chispa in range(4):
			var x := float((indice * 13 + chispa * 11) % 42 - 21)
			var y := -progreso * (18.0 + chispa * 5.0) + 5.0
			draw_rect(Rect2((punto + Vector2(x, y)).round(), Vector2(3, 3)), Color(1.0, 0.8, 0.3, opacidad))


func _bola(posicion: Vector2, radio: float) -> void:
	# Tres siluetas escalonadas, sin suavizado, en la paleta del fuego original.
	for capa in range(3):
		var r := radio - capa * 4.0
		var color: Color = [OSCURO, NARANJA, CLARO][capa]
		draw_rect(Rect2(posicion + Vector2(-r, -r + 4), Vector2(r * 2, r * 2 - 8)), color)
		draw_rect(Rect2(posicion + Vector2(-r + 4, -r), Vector2(r * 2 - 8, r * 2)), color)


func _dibujar_garras() -> void:
	var filas: Dictionary = {}
	for punto in puntos:
		if not filas.has(punto.y):
			filas[punto.y] = Vector2(punto.x, punto.x)
		var limites: Vector2 = filas[punto.y]
		filas[punto.y] = Vector2(minf(limites.x, punto.x), maxf(limites.y, punto.x))
	var avance := progreso if fase == 0 else 1.0
	var alfa := 1.0 if fase == 0 else 1.0 - progreso
	for y in filas:
		var limites: Vector2 = filas[y]
		var izquierda := limites.x - tamano_celda.x / 2.0 + 6.0
		var derecha := limites.y + tamano_celda.x / 2.0 - 6.0
		for garra in range(3):
			var cantidad := maxi(1, int((derecha - izquierda) * avance / 3.0))
			for paso in range(cantidad):
				var factor := float(paso * 3) / (derecha - izquierda)
				var punto := Vector2(izquierda + paso * 3, y + (garra - 1) * 14 + lerpf(-8, 8, factor)).round()
				draw_rect(Rect2(punto - Vector2(1, 2), Vector2(5, 6)), Color(0.55, 0.08, 0.12, alfa))
				draw_rect(Rect2(punto, Vector2(3, 2)), Color(1.0, 0.9, 0.7, alfa))


func _dibujar_mordida() -> void:
	var cierre := progreso if fase == 0 else 1.0 - progreso * 0.25
	var alfa := 1.0 if fase == 0 else 1.0 - progreso
	var separacion := lerpf(tamano_celda.x * 0.45, 7.0, cierre)
	for punto in puntos:
		for lado in [-1, 1]:
			var x: float = punto.x + lado * separacion
			draw_rect(Rect2(Vector2(x - 2, punto.y - 29).round(), Vector2(4, 58)), Color(0.5, 0.06, 0.1, alfa))
			for diente in range(3):
				var y := punto.y - 20 + diente * 18
				for escalon in range(4):
					var punta := Vector2(x - lado * (escalon * 3 + 2), y + escalon).round()
					draw_rect(Rect2(punta, Vector2(3, 9 - escalon * 2)), Color(0.95, 0.87, 0.67, alfa))
		if fase == 1:
			draw_rect(Rect2(punto - Vector2(8, 26), Vector2(16, 52)), Color(0.9, 0.15, 0.12, alfa * 0.35))
