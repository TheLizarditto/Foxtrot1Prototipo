extends Node2D

var progreso := 0.0
var tween_brillo: Tween


func _ready() -> void:
	visible = false


# Un barrido metalico y pequenos destellos sobre el escudo, sin alterar el sprite.
func reproducir(duracion: float) -> void:
	ocultar()
	visible = true
	progreso = 0.0
	tween_brillo = create_tween()
	tween_brillo.tween_method(_actualizar_brillo, 0.0, 1.0, duracion)
	tween_brillo.tween_callback(ocultar)


func ocultar() -> void:
	if tween_brillo != null and tween_brillo.is_valid():
		tween_brillo.kill()
	visible = false
	queue_redraw()


func _actualizar_brillo(valor: float) -> void:
	progreso = valor
	queue_redraw()


func _draw() -> void:
	var intensidad := sin(progreso * PI)
	var azul := Color(0.55, 0.82, 1.0, intensidad * 0.22)
	var blanco := Color(0.9, 0.97, 1.0, intensidad * 0.95)
	# El efecto ocupa la superficie del escudo que se ve a la izquierda de la capa.
	var contorno := PackedVector2Array([
		Vector2(-4, -6), Vector2(3, -6), Vector2(4, -3),
		Vector2(3, 3), Vector2(0, 7), Vector2(-3, 4), Vector2(-4, 0),
	])
	draw_colored_polygon(contorno, azul)
	var barrido := roundf(lerpf(-5.0, 4.0, progreso))
	for fila in range(-4, 5):
		var x := barrido + floorf(float(fila) / 3.0)
		if x >= -3.0 and x <= 2.0:
			draw_rect(Rect2(Vector2(x, fila), Vector2(1, 1)), blanco)
	_dibujar_destello(Vector2(-2, -4), intensidad, blanco)
	var intensidad_secundaria := maxf(sin((progreso - 0.3) * PI * 1.4), 0.0)
	_dibujar_destello(Vector2(3, 2), intensidad_secundaria, Color(0.72, 0.88, 1.0, intensidad_secundaria * 0.8))


func _dibujar_destello(centro: Vector2, intensidad: float, color: Color) -> void:
	var radio := floorf(intensidad * 3.0)
	if radio < 1.0:
		return
	draw_rect(Rect2(centro - Vector2(radio, 0), Vector2(radio * 2.0 + 1.0, 1)), color)
	draw_rect(Rect2(centro - Vector2(0, radio), Vector2(1, radio * 2.0 + 1.0)), color)
