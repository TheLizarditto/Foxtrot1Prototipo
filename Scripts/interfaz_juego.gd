extends RefCounted
class_name InterfazJuego

# Ajusta un sprite a la textura indicada y lo escala al tamano pedido.
static func ajustar_sprite(sprite: Sprite2D, textura: Texture2D, tamano: Vector2) -> void:
	sprite.texture = textura
	if textura != null:
		sprite.scale = tamano / textura.get_size()


# Crea un indicador visual con icono y numero dentro del contenedor indicado.
static func crear_indicador(contenedor: HBoxContainer, textura: Texture2D, cantidad: int, tamano_icono: Vector2, tamano_fuente: int) -> void:
	var indicador := HBoxContainer.new()
	indicador.add_theme_constant_override("separation", 1)
	indicador.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	contenedor.add_child(indicador)

	var icono := TextureRect.new()
	icono.custom_minimum_size = tamano_icono
	icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icono.texture = textura
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	indicador.add_child(icono)

	var numero := Label.new()
	numero.text = str(cantidad)
	numero.add_theme_font_size_override("font_size", tamano_fuente)
	numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	numero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	indicador.add_child(numero)
