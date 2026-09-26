extends CanvasLayer

signal confirmado(indices: Array[int])

const ESCENA_CARTA := preload("res://Scenes/carta.tscn")
const TEXTURA_CONFIRMAR := preload("res://Assets/Turno/confirmar_descarte.svg")

var panel: Control
var grilla: GridContainer
var pregunta: Label
var boton_confirmar: TextureButton
var seleccionadas: Array[int] = []
var marcos: Array[Panel] = []


func _ready() -> void:
	layer = 20
	panel = ColorRect.new()
	panel.color = Color("151b25")
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 28)
	panel.add_child(margen)
	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 16)
	margen.add_child(contenido)
	pregunta = Label.new()
	pregunta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pregunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pregunta.add_theme_font_size_override("font_size", 22)
	contenido.add_child(pregunta)
	var ayuda := Label.new()
	ayuda.text = "Hacé clic para seleccionar o deseleccionar. Podés confirmar sin descartar ninguna."
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contenido.add_child(ayuda)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenido.add_child(scroll)
	var centro := CenterContainer.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(centro)
	grilla = GridContainer.new()
	grilla.add_theme_constant_override("h_separation", 8)
	grilla.add_theme_constant_override("v_separation", 8)
	centro.add_child(grilla)
	boton_confirmar = TextureButton.new()
	boton_confirmar.texture_normal = TEXTURA_CONFIRMAR
	boton_confirmar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	boton_confirmar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	boton_confirmar.pressed.connect(_confirmar)
	contenido.add_child(boton_confirmar)
	var texto := Label.new()
	texto.text = "Confirmar descartes"
	texto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boton_confirmar.add_child(texto)
	get_viewport().size_changed.connect(_ajustar_columnas)
	panel.hide()


func abrir(cartas: Array[Dictionary]) -> void:
	for hijo in grilla.get_children():
		grilla.remove_child(hijo)
		hijo.queue_free()
	seleccionadas.clear()
	marcos.clear()
	boton_confirmar.disabled = false
	for indice in range(cartas.size()):
		var espacio := Control.new()
		espacio.custom_minimum_size = Vector2(112, 144)
		espacio.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		espacio.gui_input.connect(_al_click_carta.bind(indice))
		grilla.add_child(espacio)
		var carta := ESCENA_CARTA.instantiate() as Carta
		Carta.aplicar_datos(carta, cartas[indice])
		espacio.add_child(carta)
		carta.position = espacio.custom_minimum_size / 2.0
		_ignorar_mouse(carta)
		var marco := Panel.new()
		marco.position = Vector2(5, 5)
		marco.size = Vector2(102, 134)
		marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color.TRANSPARENT
		estilo.border_color = Color("ff3838")
		estilo.set_border_width_all(3)
		marco.add_theme_stylebox_override("panel", estilo)
		espacio.add_child(marco)
		marco.hide()
		marcos.append(marco)
	_actualizar_pregunta()
	_ajustar_columnas()
	panel.show()


func _ignorar_mouse(nodo: Node) -> void:
	if nodo is Control:
		nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for hijo in nodo.get_children():
		_ignorar_mouse(hijo)


func _ajustar_columnas() -> void:
	grilla.columns = maxi(1, mini(marcos.size(), int((get_viewport().get_visible_rect().size.x - 56.0) / 120.0)))


func _al_click_carta(evento: InputEvent, indice: int) -> void:
	if boton_confirmar.disabled:
		return
	if (evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and evento.pressed) or (evento is InputEventScreenTouch and evento.pressed):
		if seleccionadas.has(indice):
			seleccionadas.erase(indice)
		else:
			seleccionadas.append(indice)
		marcos[indice].visible = seleccionadas.has(indice)
		_actualizar_pregunta()
		panel.get_viewport().set_input_as_handled()


func _actualizar_pregunta() -> void:
	pregunta.text = "¿Qué cartas querés descartar? (%d seleccionadas)" % seleccionadas.size()
	if marcos.is_empty():
		pregunta.text = "No quedan cartas en la mano. Confirmá para pasar de turno."


func _confirmar() -> void:
	if boton_confirmar.disabled or not panel.visible:
		return
	boton_confirmar.disabled = true
	panel.hide()
	seleccionadas.sort()
	confirmado.emit(seleccionadas.duplicate())
