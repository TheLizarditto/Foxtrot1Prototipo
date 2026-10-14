extends Node2D

var celdas: Array[Vector2i] = []


func mostrar(zona: Array[Vector2i]) -> void:
	celdas = zona.duplicate()
	queue_redraw()


func limpiar() -> void:
	celdas.clear()
	queue_redraw()


func _draw() -> void:
	var tablero := get_parent()
	for celda in celdas:
		var centro: Vector2 = tablero.obtener_posicion_en_tablero(celda.x, celda.y)
		var area := Rect2(centro - tablero.tamano_celda / 2.0, tablero.tamano_celda).grow(-3.0)
		draw_rect(area, Color(0.85, 0.04, 0.08, 0.27))
		draw_rect(area, Color("ef4148"), false, 2.0)
