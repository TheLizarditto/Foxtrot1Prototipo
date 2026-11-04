extends Node2D

const ICONO_ESCUDO := preload("res://Assets/Carta/miniescudo.png")
const ICONO_DANO := preload("res://Assets/Carta/miniespada.png")
const TAMANO_ICONO := Vector2(16, 16)
const TAMANO_FUENTE := 12

var etiqueta_escudo: Label
var etiqueta_dano: Label


func _ready() -> void:
	var panel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("191824d9")
	estilo.border_color = Color("49465e")
	estilo.set_border_width_all(2)
	estilo.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", estilo)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var filas := VBoxContainer.new()
	filas.add_theme_constant_override("separation", 4)
	panel.add_child(filas)
	etiqueta_escudo = _crear_fila(filas, ICONO_ESCUDO)
	etiqueta_dano = _crear_fila(filas, ICONO_DANO)


func _crear_fila(contenedor: VBoxContainer, textura: Texture2D) -> Label:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	contenedor.add_child(fila)
	var icono := TextureRect.new()
	icono.custom_minimum_size = TAMANO_ICONO
	icono.texture = textura
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fila.add_child(icono)
	var etiqueta := Label.new()
	etiqueta.add_theme_font_size_override("font_size", TAMANO_FUENTE)
	etiqueta.add_theme_color_override("font_color", Color("eee1bb"))
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(etiqueta)
	return etiqueta


# Cada fila muestra el valor actual y, si cambia, el resultado previsto.
func mostrar(escudo_actual: int, escudo_final: int, dano: int, dano_final: int) -> void:
	etiqueta_escudo.text = _formato(escudo_actual, escudo_final)
	etiqueta_dano.text = _formato(dano, dano_final)


func _formato(actual: int, final: int) -> String:
	return str(actual) if actual == final else "%d > %d" % [actual, final]
