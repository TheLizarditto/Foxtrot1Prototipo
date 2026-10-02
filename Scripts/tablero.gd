extends Node2D

@export var columnas := 5
@export var filas := 5

@onready var cuadro: Sprite2D = $Cuadro
@onready var tamano_celda := cuadro.texture.get_size()

# Genera las celdas del tablero cuando el nodo entra en escena.
func _ready() -> void:
	
	_generar_tablero()
	queue_redraw()
	

# Calcula y devuelve la posicion local de la primera celda del tablero.
func _obtener_inicio() -> Vector2:
	
	var tamano_tablero := Vector2(
		columnas * tamano_celda.x,
		filas * tamano_celda.y 
	)
	var inicio := -tamano_tablero / 2.0 + tamano_celda / 2.0
	
	return inicio

# Devuelve las coordenadas de grilla de la celda central del tablero.
func obtener_centro_tablero() -> Vector2:
	return Vector2(
		floori(columnas / 2.0),
		floori(filas / 2.0)
	)
	
# Crea o duplica los sprites de celda y los ubica en sus posiciones.
func _generar_tablero() -> void:
	
	var inicio = _obtener_inicio()
	
	for fila in filas:
		for columna in columnas:
			var celda: Sprite2D
			if fila == 0 and columna == 0:
				celda = cuadro
			else:
				celda = cuadro.duplicate()
				add_child(celda)

			celda.position = inicio + Vector2(columna * tamano_celda.x, fila * tamano_celda.y)

# Decora solo el exterior: las losetas y sus limites conservan su aspecto.
func _draw() -> void:
	if not is_instance_valid(cuadro):
		return
	var mitad := Vector2(columnas, filas) * tamano_celda / 2.0
	var azar := RandomNumberGenerator.new()
	azar.seed = 7419
	for lado in range(4):
		var horizontal := lado < 2
		var largo := mitad.x * 2.0 if horizontal else mitad.y * 2.0
		var normal := Vector2(0, -1 if lado == 0 else 1) if horizontal else Vector2(-1 if lado == 2 else 1, 0)
		var tangente := Vector2.RIGHT if horizontal else Vector2.DOWN
		for indice in range(int(largo / 19.0)):
			if azar.randf() < 0.28:
				continue
			var distancia := -largo / 2.0 + indice * 19.0 + azar.randi_range(3, 12)
			var origen := tangente * distancia + normal * ((mitad.y if horizontal else mitad.x) + azar.randi_range(2, 5))
			_dibujar_pasto(origen.round(), azar)
		for indice in range(int(largo / 70.0)):
			var distancia := -largo / 2.0 + indice * 70.0 + azar.randi_range(15, 55)
			var origen := tangente * distancia + normal * ((mitad.y if horizontal else mitad.x) + azar.randi_range(6, 11))
			_dibujar_piedra(origen.round(), azar)


func _dibujar_pasto(origen: Vector2, azar: RandomNumberGenerator) -> void:
	var oscuro := Color("414934")
	var medio := Color("697047")
	var claro := Color("929466")
	draw_rect(Rect2(origen + Vector2(-5, -1), Vector2(11, 3)), oscuro)
	for brizna in range(5):
		var x := float(brizna * 2 - 4)
		var alto := float(azar.randi_range(3, 8))
		var inclinacion := float(azar.randi_range(-2, 2))
		draw_rect(Rect2(origen + Vector2(x, -alto * 0.5), Vector2(2, alto * 0.5 + 1)), medio)
		draw_rect(Rect2(origen + Vector2(x + inclinacion, -alto), Vector2(2, alto * 0.5)), medio)
		draw_rect(Rect2(origen + Vector2(x + inclinacion, -alto), Vector2(1, 2)), claro)


func _dibujar_piedra(origen: Vector2, azar: RandomNumberGenerator) -> void:
	var ancho := float(azar.randi_range(5, 10))
	var alto := float(azar.randi_range(4, 7))
	var forma := PackedVector2Array([
		Vector2(-ancho / 2, 0), Vector2(-ancho / 2, -alto + 2),
		Vector2(-ancho / 2 + 2, -alto), Vector2(ancho / 2 - 2, -alto),
		Vector2(ancho / 2, -alto + 2), Vector2(ancho / 2, 0),
		Vector2(ancho / 2 - 2, 2), Vector2(-ancho / 2 + 2, 2)
	])
	for punto in range(forma.size()):
		forma[punto] = forma[punto].round() + origen
	draw_rect(Rect2(origen + Vector2(-ancho / 2 - 1, 0), Vector2(ancho + 2, 3)), Color("33372f"))
	draw_colored_polygon(forma, Color("555d60"))
	draw_rect(Rect2(origen + Vector2(-ancho / 2 + 2, -alto), Vector2(ancho - 4, 1)), Color("838979"))
	draw_rect(Rect2(origen + Vector2(-ancho / 2, -alto + 2), Vector2(1, alto - 2)), Color("737c70"))


# Recibe columna y fila, valida que existan y devuelve la posicion local de esa celda.
func obtener_posicion_en_tablero(columna: int, fila: int) -> Vector2:
	
	if not es_posicion_valida(columna, fila):
		return Vector2.ZERO
	
	var inicio = _obtener_inicio()
	
	return inicio + Vector2(
		columna * tamano_celda.x,
		fila * tamano_celda.y
	)


# Devuelve la posicion de grilla limitada al tamano del tablero.
func limitar_posicion_en_tablero(posicion: Vector2) -> Vector2:
	return Vector2(
		clampi(int(posicion.x), 0, columnas - 1),
		clampi(int(posicion.y), 0, filas - 1)
	)


# Indica si una posicion de grilla existe dentro del tablero.
func es_posicion_valida(columna: int, fila: int) -> bool:
	return columna >= 0 and columna < columnas and fila >= 0 and fila < filas
