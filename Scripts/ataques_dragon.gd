extends Node

signal ataque_resuelto(tipo: int, dano_realizado: int)

enum Tipo { BOLA_FUEGO, GARRAS, MORDIDA }
const DANOS := [Vector2i(3, 5), Vector2i(5, 7), Vector2i(8, 10)]
const MARCAS := preload("res://Scripts/marcas_ataque.gd")
const EFECTOS := preload("res://Scripts/efectos_dragon.gd")

@onready var tablero: Node2D = $"../Tablero"
@onready var caballero: Node2D = $"../Personaje"
@onready var dragon: Node2D = $"../Enemigo"

var azar := RandomNumberGenerator.new()
var cola: Array[int] = []
var ataque_actual: Dictionary = {}
var en_curso := false
var ultimo_tipo := -1
var dano_realizado := 0
var impacto_aplicado := false
var marcas: Node2D
var efectos: Node2D


func _ready() -> void:
	azar.randomize()
	marcas = MARCAS.new()
	marcas.name = "MarcasAtaque"
	tablero.add_child(marcas)
	# Las flechas de recorrido y el caballero se dibujan sobre las marcas.
	tablero.move_child(marcas, tablero.get_node("VistaRecorrido").get_index())
	efectos = EFECTOS.new()
	efectos.name = "EfectosDragon"
	add_child(efectos)
	efectos.impacto.connect(_aplicar_impacto)


func preparar_siguiente() -> void:
	if en_curso or not ataque_actual.is_empty():
		return
	if dragon.puntos_vida <= 0 or caballero.puntos_vida <= 0:
		limpiar()
		return
	if cola.is_empty():
		_rellenar_cola()
	var tipo: int = cola.pop_front()
	ultimo_tipo = tipo
	var rango: Vector2i = DANOS[tipo]
	ataque_actual = {
		"tipo": tipo,
		"dano": azar.randi_range(rango.x, rango.y),
		"celdas": elegir_zona(tipo, Vector2i(caballero.posicion)),
	}
	marcas.mostrar(ataque_actual["celdas"])


func _rellenar_cola() -> void:
	cola.assign([Tipo.BOLA_FUEGO, Tipo.GARRAS, Tipo.MORDIDA])
	for indice in range(cola.size() - 1, 0, -1):
		var otro := azar.randi_range(0, indice)
		var temporal := cola[indice]
		cola[indice] = cola[otro]
		cola[otro] = temporal
	# Cada tanda contiene los tres ataques y evita repetir al cambiar de tanda.
	if cola[0] == ultimo_tipo:
		var temporal := cola[0]
		cola[0] = cola[1]
		cola[1] = temporal


func elegir_zona(tipo: int, objetivo: Vector2i) -> Array[Vector2i]:
	var candidatas: Array = []
	if tipo == Tipo.MORDIDA:
		for x in range(tablero.columnas):
			var zona: Array[Vector2i] = []
			for y in range(tablero.filas):
				zona.append(Vector2i(x, y))
			candidatas.append(zona)
	else:
		for y in range(tablero.filas - 2):
			for x in range(tablero.columnas - 2):
				var zona: Array[Vector2i] = []
				for dy in range(3):
					if tipo == Tipo.GARRAS and dy == 1:
						continue
					for dx in range(3):
						zona.append(Vector2i(x + dx, y + dy))
				candidatas.append(zona)
	var apuntadas: Array = []
	for zona in candidatas:
		if zona.has(objetivo):
			apuntadas.append(zona)
	if apuntadas.is_empty():
		return []
	# Solo se apunta al preparar: el patron no persigue al jugador durante su turno.
	return apuntadas[azar.randi_range(0, apuntadas.size() - 1)].duplicate()


func ejecutar_ataque() -> void:
	if en_curso or ataque_actual.is_empty():
		return
	if dragon.puntos_vida <= 0 or caballero.puntos_vida <= 0:
		limpiar()
		return
	en_curso = true
	impacto_aplicado = false
	dano_realizado = 0
	var tipo: int = ataque_actual["tipo"]
	await dragon.preparar_animacion_ataque(tipo)
	await efectos.reproducir(tipo, ataque_actual["celdas"], tablero, dragon.obtener_boca_global())
	await dragon.terminar_animacion_ataque()
	limpiar()
	en_curso = false
	ataque_resuelto.emit(tipo, dano_realizado)


func _aplicar_impacto() -> void:
	if not en_curso or impacto_aplicado or ataque_actual.is_empty():
		return
	impacto_aplicado = true
	if dragon.puntos_vida <= 0 or caballero.puntos_vida <= 0:
		return
	dragon.impactar_ataque(ataque_actual["tipo"])
	if ataque_actual["celdas"].has(Vector2i(caballero.posicion)):
		dano_realizado = caballero.recibir_dano(ataque_actual["dano"])


func limpiar() -> void:
	ataque_actual.clear()
	marcas.limpiar()
