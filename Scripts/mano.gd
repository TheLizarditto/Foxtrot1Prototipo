extends Node2D
class_name Mano

const ESCENA_CARTA := preload("res://Scenes/carta.tscn")

@export var cantidad_cartas_mano := 7
@export var separacion_cartas := 52.0
@export var angulo_maximo_grados := 12.0
@export var curvatura_vertical := 14.0
@export var altura_animacion_robo := 90.0
@export var duracion_levantar_carta := 0.18
@export var duracion_girar_carta := 0.18
@export var duracion_llevar_a_mano := 0.34
@export var desplazamiento_elevacion_relativo := Vector2(-0.15, -0.33)
@export var inclinacion_inicial_grados := -7.0
@export var escala_inicial_robo := Vector2(0.92, 0.92)
@export var escala_minima_giro := 0.05
@export var color_carta_oculta := Color(0.62, 0.66, 0.78, 1.0)
@export var desplazamiento_hover := Vector2(0.0, -72.0)
@export var duracion_hover := 0.15
@export var ruta_mazo_descarte: NodePath = "../MazoDescarte"

var mano: Array[Dictionary] = []
var cartas_visuales: Array[Node2D] = []
var carta_en_hover: Node2D
var tween_hover: Tween
var mano_lista_para_seleccion := false


# Detecta la carta bajo el mouse y la muestra en una posicion legible.
func _process(_delta: float) -> void:
	_actualizar_hover()


# Usa la carta tocada o clickeada antes de que los controles de su contenido consuman el evento.
func _input(event: InputEvent) -> void:
	if not mano_lista_para_seleccion:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_usar_carta_en_posicion(to_local(get_global_mouse_position()))
	elif event is InputEventScreenTouch and event.pressed:
		_usar_carta_en_posicion(get_global_transform_with_canvas().affine_inverse() * event.position)


# Roba una carta del mazo especificado y la agrega a la mano.
func robar_carta(mazo_robo: MazoRobo) -> bool:
	if mazo_robo == null or esta_llena():
		return false

	var datos_carta := mazo_robo.robar_carta()
	if datos_carta.is_empty():
		return false

	_agregar_carta(datos_carta)
	_actualizar_disposicion_visual()
	mano_lista_para_seleccion = esta_llena()
	return true


# Llena la mano sacando cartas del mazo de robo.
func cargar_desde_mazo(mazo_robo: MazoRobo) -> int:
	var cantidad_cargada := 0

	while not esta_llena() and robar_carta(mazo_robo):
		cantidad_cargada += 1

	return cantidad_cargada


# Roba una carta del mazo realizando una animacion desde la posicion del mazo.
func robar_carta_animada(mazo_robo: MazoRobo) -> bool:
	if mazo_robo == null or esta_llena():
		return false

	var datos_carta := mazo_robo.robar_carta()
	if datos_carta.is_empty():
		return false

	mano_lista_para_seleccion = false
	var carta_visual := _agregar_carta(datos_carta)
	await _animar_carta_robada(carta_visual, mazo_robo.global_position)
	mano_lista_para_seleccion = esta_llena()
	return true


# Llena la mano sacando cartas animadas una por una desde el mazo de robo.
func cargar_desde_mazo_animada(mazo_robo: MazoRobo) -> int:
	var cantidad_cargada := 0

	while not esta_llena():
		if not await robar_carta_animada(mazo_robo):
			break

		cantidad_cargada += 1

	return cantidad_cargada


# Devuelve la cantidad de cartas en la mano.
func cantidad() -> int:
	return mano.size()


# Indica si la mano llego a su capacidad maxima.
func esta_llena() -> bool:
	return cantidad() >= maxi(cantidad_cartas_mano, 0)


# Indica si la mano no tiene cartas.
func esta_vacia() -> bool:
	return mano.is_empty()


# Devuelve una copia de las cartas que componen la mano actual.
func obtener_cartas() -> Array[Dictionary]:
	var copia_cartas: Array[Dictionary] = []

	for datos in mano:
		copia_cartas.append(datos.duplicate(true))

	return copia_cartas


# Registra la carta en la mano interna y crea su representacion visual.
func _agregar_carta(datos_carta: Dictionary) -> Node2D:
	mano.append(Carta.normalizar_datos(datos_carta))

	var carta_visual := ESCENA_CARTA.instantiate() as Node2D
	Carta.aplicar_datos(carta_visual, datos_carta)
	add_child(carta_visual)
	cartas_visuales.append(carta_visual)
	return carta_visual


# Ejecuta la carta elegida, la elimina de la mano y la anima hasta el descarte.
func _usar_carta_en_posicion(posicion_local: Vector2) -> void:
	var carta_visual := carta_en_hover
	if carta_visual == null or not is_instance_valid(carta_visual):
		return

	if not _contiene_carta_seleccionada(carta_visual, posicion_local):
		return

	var indice := cartas_visuales.find(carta_visual)
	var mazo_descarte := get_node_or_null(ruta_mazo_descarte) as MazoDescarte
	if indice < 0 or mazo_descarte == null:
		return

	mano_lista_para_seleccion = false
	if tween_hover != null and tween_hover.is_valid():
		tween_hover.kill()
	carta_en_hover = null

	await carta_visual.ejecutar()
	var datos_carta: Dictionary = mano[indice]
	mano.remove_at(indice)
	cartas_visuales.remove_at(indice)
	await _animar_carta_al_descarte(carta_visual, mazo_descarte)
	mazo_descarte.recibir_carta(datos_carta)
	carta_visual.queue_free()
	_actualizar_disposicion_visual()
	mano_lista_para_seleccion = not esta_vacia()


# Reutiliza el recorrido curvo de robo para llevar la carta jugada al descarte.
func _animar_carta_al_descarte(carta_visual: Node2D, mazo_descarte: MazoDescarte) -> void:
	var inicio := carta_visual.position
	var destino := to_local(mazo_descarte.global_position)
	var control := (inicio + destino) / 2.0 + Vector2(0.0, -altura_animacion_robo)
	carta_visual.z_index = 100

	var tween := create_tween()
	var recorrido := tween.tween_method(
		_mover_carta_en_arco.bind(carta_visual, inicio, control, destino),
		0.0,
		1.0,
		maxf(duracion_llevar_a_mano, 0.0)
	)
	recorrido.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(
		carta_visual,
		"scale",
		escala_inicial_robo,
		maxf(duracion_llevar_a_mano, 0.0)
	)
	tween.parallel().tween_property(
		carta_visual,
		"modulate:a",
		0.0,
		maxf(duracion_llevar_a_mano, 0.0)
	)
	await tween.finished


# Anima la llegada de una carta desde el mazo hacia su lugar en el abanico.
func _animar_carta_robada(carta_visual: Node2D, origen_global: Vector2) -> void:
	var total := cartas_visuales.size()
	var indice := total - 1
	var posicion_destino := _obtener_posicion_carta(indice, total)
	var rotacion_destino := _obtener_rotacion_carta(indice, total)
	var z_destino := total - indice
	var posicion_inicial := to_local(origen_global)
	var tamano_carta := Vector2(carta_visual.get("tamano_carta"))
	var posicion_elevada := posicion_inicial + tamano_carta * desplazamiento_elevacion_relativo
	var control_arco := (posicion_elevada + posicion_destino) / 2.0 + Vector2(0.0, -altura_animacion_robo)

	_acomodar_cartas_existentes(carta_visual, duracion_levantar_carta)
	carta_visual.mostrar_atras()
	carta_visual.position = posicion_inicial
	carta_visual.rotation = 0.0
	carta_visual.scale = escala_inicial_robo
	carta_visual.modulate = color_carta_oculta
	carta_visual.z_index = total + 1

	var tween := create_tween()
	var levantar := tween.tween_property(
		carta_visual,
		"position",
		posicion_elevada,
		maxf(duracion_levantar_carta, 0.0)
	)
	levantar.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(
		carta_visual,
		"rotation",
		deg_to_rad(inclinacion_inicial_grados),
		maxf(duracion_levantar_carta, 0.0)
	)

	var primera_mitad := tween.tween_method(
		_mover_carta_en_arco.bind(carta_visual, posicion_elevada, control_arco, posicion_destino),
		0.0,
		0.5,
		maxf(duracion_girar_carta, 0.0)
	)
	primera_mitad.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(
		carta_visual,
		"scale:x",
		clampf(escala_minima_giro, 0.0, 1.0),
		maxf(duracion_girar_carta, 0.0)
	)

	tween.tween_callback(_mostrar_frente_carta.bind(carta_visual, z_destino))

	var segunda_mitad := tween.tween_method(
		_mover_carta_en_arco.bind(carta_visual, posicion_elevada, control_arco, posicion_destino),
		0.5,
		1.0,
		maxf(duracion_llevar_a_mano, 0.0)
	)
	segunda_mitad.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(
		carta_visual,
		"scale",
		Vector2.ONE,
		maxf(duracion_llevar_a_mano, 0.0)
	)
	tween.parallel().tween_property(
		carta_visual,
		"rotation",
		rotacion_destino,
		maxf(duracion_llevar_a_mano, 0.0)
	)

	await tween.finished
	_actualizar_disposicion_visual()


# Reacomoda progresivamente las cartas que ya estaban en la mano.
func _acomodar_cartas_existentes(carta_nueva: Node2D, duracion: float) -> void:
	var total := cartas_visuales.size()
	if total <= 1:
		return

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	for indice in range(total):
		var carta_visual := cartas_visuales[indice]
		carta_visual.z_index = total - indice

		if carta_visual == carta_nueva:
			continue

		tween.tween_property(
			carta_visual,
			"position",
			_obtener_posicion_carta(indice, total),
			maxf(duracion, 0.0)
		)
		tween.tween_property(
			carta_visual,
			"rotation",
			_obtener_rotacion_carta(indice, total),
			maxf(duracion, 0.0)
		)


# Calcula la posicion sobre una curva cuadratica de Bezier.
func _mover_carta_en_arco(
	progreso: float,
	carta_visual: Node2D,
	inicio: Vector2,
	control: Vector2,
	fin: Vector2
) -> void:
	var inverso := 1.0 - progreso
	carta_visual.position = (
		inverso * inverso * inicio
		+ 2.0 * inverso * progreso * control
		+ progreso * progreso * fin
	)


# Revela el contenido de la carta justo cuando termina de darse vuelta.
func _mostrar_frente_carta(carta_visual: Carta, z_destino: int) -> void:
	carta_visual.mostrar_frente()
	carta_visual.modulate = Color.WHITE
	carta_visual.z_index = z_destino


# Sincroniza la transformacion de cada carta visual segun la cantidad actual.
func _actualizar_disposicion_visual() -> void:
	var total := cartas_visuales.size()
	if total == 0:
		return

	for indice in range(total):
		var carta_visual := cartas_visuales[indice]
		carta_visual.position = _obtener_posicion_carta(indice, total)
		carta_visual.rotation = _obtener_rotacion_carta(indice, total)
		carta_visual.scale = Vector2.ONE
		carta_visual.modulate = Color.WHITE
		carta_visual.z_index = total - indice


# Detecta el mouse sobre la carta mas al frente y la despliega.
func _actualizar_hover() -> void:
	if not mano_lista_para_seleccion:
		if carta_en_hover != null:
			if tween_hover != null and tween_hover.is_valid():
				tween_hover.kill()
			carta_en_hover = null
			_actualizar_disposicion_visual()
		return

	var carta_bajo_mouse := _obtener_carta_bajo_mouse()
	if carta_bajo_mouse == carta_en_hover:
		return

	if tween_hover != null and tween_hover.is_valid():
		tween_hover.kill()

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var total := cartas_visuales.size()

	carta_en_hover = carta_bajo_mouse
	for indice in range(total):
		var carta_visual := cartas_visuales[indice]
		if carta_visual == carta_en_hover:
			continue

		carta_visual.z_index = total - indice
		tween.tween_property(
			carta_visual,
			"position",
			_obtener_posicion_carta(indice, total),
			maxf(duracion_hover, 0.0)
		)
		tween.tween_property(
			carta_visual,
			"rotation",
			_obtener_rotacion_carta(indice, total),
			maxf(duracion_hover, 0.0)
		)

	if carta_en_hover == null:
		tween_hover = tween
		return

	carta_en_hover.z_index = total + 1
	tween.tween_property(
		carta_en_hover,
		"position",
		carta_en_hover.position + desplazamiento_hover,
		maxf(duracion_hover, 0.0)
	)
	tween.tween_property(carta_en_hover, "rotation", 0.0, maxf(duracion_hover, 0.0))
	tween_hover = tween


# Busca la carta con mayor z_index que este colisionando con el puntero.
func _obtener_carta_bajo_mouse() -> Node2D:
	var mouse_local := to_local(get_global_mouse_position())
	return _obtener_carta_en_posicion(mouse_local)


# Busca la carta visible con mayor prioridad en la posicion local recibida.
func _obtener_carta_en_posicion(posicion_local: Vector2) -> Node2D:
	var carta_bajo_mouse: Node2D
	var mayor_z := -INF

	for carta_visual in cartas_visuales:
		if not is_instance_valid(carta_visual) or not _contiene_mouse(carta_visual, posicion_local):
			continue

		if carta_visual.z_index > mayor_z:
			carta_bajo_mouse = carta_visual
			mayor_z = carta_visual.z_index

	return carta_bajo_mouse


# Comprueba si el punto esta dentro de la carta en abanico o desplegada.
func _contiene_mouse(carta_visual: Node2D, mouse_local: Vector2) -> bool:
	var indice := cartas_visuales.find(carta_visual)
	if indice < 0:
		return false

	var posicion_base := _obtener_posicion_carta(indice, cartas_visuales.size())
	var rotacion_base := _obtener_rotacion_carta(indice, cartas_visuales.size())
	var tamano_carta := Vector2(carta_visual.get("tamano_carta"))
	var punto_en_abanico := (mouse_local - posicion_base).rotated(-rotacion_base)
	var esta_en_abanico := (
		absf(punto_en_abanico.x) <= tamano_carta.x / 2.0
		and absf(punto_en_abanico.y) <= tamano_carta.y / 2.0
	)
	if esta_en_abanico or carta_visual != carta_en_hover:
		return esta_en_abanico

	var punto_desplegado := mouse_local - (posicion_base + desplazamiento_hover)
	return absf(punto_desplegado.x) <= tamano_carta.x / 2.0 and absf(punto_desplegado.y) <= tamano_carta.y / 2.0


# Solo considera la zona recta de la carta que ya fue desplegada.
func _contiene_carta_seleccionada(carta_visual: Node2D, posicion_local: Vector2) -> bool:
	var tamano_carta := Vector2(carta_visual.get("tamano_carta"))
	var punto_seleccionado := (posicion_local - carta_visual.position).rotated(-carta_visual.rotation)
	return (
		absf(punto_seleccionado.x) <= tamano_carta.x / 2.0
		and absf(punto_seleccionado.y) <= tamano_carta.y / 2.0
	)


# Calcula la posicion de una carta dentro del arco segun su indice.
func _obtener_posicion_carta(indice: int, total: int) -> Vector2:
	var centro := float(total - 1) / 2.0
	var distancia_centro := float(indice) - centro
	var posicion_normalizada := distancia_centro / maxf(centro, 1.0)

	return Vector2(
		distancia_centro * separacion_cartas,
		pow(absf(posicion_normalizada), 2.0) * curvatura_vertical
	)


# Calcula la inclinacion de una carta dentro del abanico.
func _obtener_rotacion_carta(indice: int, total: int) -> float:
	var centro := float(total - 1) / 2.0
	var distancia_centro := float(indice) - centro
	var posicion_normalizada := distancia_centro / maxf(centro, 1.0)

	return deg_to_rad(posicion_normalizada * angulo_maximo_grados)
