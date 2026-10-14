extends Node2D

const TEXTURA_BORDE := preload("res://Assets/Carta/frente.svg")
const TEXTURA_DORSO := preload("res://Assets/Carta/dorso.svg")
const ESCENA_CARTA := preload("res://Scenes/carta.tscn")
const TAMANO := Vector2(96, 128)
const DIRECCION_RELIEVE := Vector2(-0.38, -1.0)

@export var es_descarte := false
@onready var contador_cartas: Label = get_node_or_null("../ContadorCartas")
var cantidad_visual := 0.0
var cantidad_objetivo := 0
var tween_altura: Tween
var carta_superior: Carta
var datos_visibles: Dictionary = {}


func _ready() -> void:
	_ajustar_altura(cantidad_visual)


func actualizar(total: int, datos_superiores: Dictionary = {}, animar := true) -> void:
	cantidad_objetivo = maxi(total, 0)
	if es_descarte:
		if total > 0 and (carta_superior == null or datos_visibles != datos_superiores):
			if carta_superior != null:
				carta_superior.visible = false
				carta_superior.queue_free()
			carta_superior = ESCENA_CARTA.instantiate() as Carta
			Carta.aplicar_datos(carta_superior, datos_superiores)
			add_child(carta_superior)
			carta_superior.position = _desplazamiento_superior(cantidad_visual)
			datos_visibles = datos_superiores.duplicate(true)
		if carta_superior != null:
			carta_superior.visible = total > 0
	if tween_altura != null and tween_altura.is_valid():
		tween_altura.kill()
	if animar and is_inside_tree():
		tween_altura = create_tween()
		tween_altura.tween_method(_ajustar_altura, cantidad_visual, float(cantidad_objetivo), 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_ajustar_altura(float(cantidad_objetivo))


func posicion_superior_global() -> Vector2:
	return to_global(_desplazamiento_superior(float(cantidad_objetivo)))


func posicion_entrada_global() -> Vector2:
	return to_global(_desplazamiento_superior(float(cantidad_objetivo + 1)))


func _desplazamiento_superior(total: float) -> Vector2:
	return DIRECCION_RELIEVE * (sqrt(maxf(total - 1.0, 0.0)) * 6.5)


func _ajustar_altura(total: float) -> void:
	cantidad_visual = total
	var cima := _desplazamiento_superior(total)
	if carta_superior != null:
		carta_superior.position = cima
	if contador_cartas != null:
		# Mantiene el contador centrado y a 8 px del borde superior de la pila.
		contador_cartas.position = position + cima + Vector2(-contador_cartas.size.x / 2.0, -TAMANO.y / 2.0 - 8.0 - contador_cartas.size.y)
	queue_redraw()


func _draw() -> void:
	var base := Rect2(-TAMANO / 2.0, TAMANO)
	# La base queda visible cuando el mazo esta vacio.
	draw_style_box(_estilo_base(), base.grow(4.0))
	if cantidad_visual < 0.01:
		draw_rect(base.grow(-7.0), Color(0.65, 0.59, 0.43, 0.3), false, 1.0)
		return
	var cima := _desplazamiento_superior(cantidad_visual)
	draw_rect(Rect2(base.position + Vector2(5, 7), TAMANO + Vector2(2, 2)), Color(0, 0, 0, 0.32))
	var capas := mini(ceili(cantidad_visual), 64)
	for indice in range(capas):
		var factor := float(indice) / maxf(capas - 1, 1)
		var posicion := cima * factor
		draw_texture_rect(TEXTURA_BORDE, Rect2(base.position + posicion, TAMANO), false, Color(0.72, 0.69, 0.62).lerp(Color.WHITE, factor))
	if not es_descarte:
		draw_texture_rect(TEXTURA_DORSO, Rect2(base.position + cima, TAMANO), false)


func _estilo_base() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.08, 0.07, 0.12, 1.0)
	estilo.border_color = Color(0.65, 0.59, 0.43, 0.4)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(5)
	return estilo
