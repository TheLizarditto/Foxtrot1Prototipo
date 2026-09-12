extends Node2D

const ICONO_MOVIMIENTO := "M"
const ICONO_ATAQUE := "A"
const ICONO_DEFENSA := "D"

@export var tamano_carta := Vector2i(96, 128)
@export var sprite_fondo: Texture2D
@export var sprite_icono_movimiento: Texture2D
@export var sprite_icono_ataque: Texture2D
@export var sprite_icono_defensa: Texture2D
@export var movimientos: Array[Vector2i] = []
@export var ataque := 0
@export var defensa := 0

@onready var fondo: Sprite2D = $Fondo
@onready var icono_movimiento: Sprite2D = $Iconos/Movimiento
@onready var icono_ataque: Sprite2D = $Iconos/Ataque
@onready var icono_defensa: Sprite2D = $Iconos/Defensa
@onready var movimiento_label: Label = $Contenido/Movimiento
@onready var atributos_label: Label = $Contenido/Atributos

func _ready() -> void:
	ataque = maxi(ataque, 0)
	defensa = maxi(defensa, 0)
	
	fondo.texture = sprite_fondo
	if sprite_fondo != null:
		fondo.scale = Vector2(tamano_carta) / sprite_fondo.get_size()
	
	_setear_icono(icono_movimiento, sprite_icono_movimiento, not movimientos.is_empty())
	_setear_icono(icono_ataque, sprite_icono_ataque, ataque > 0)
	_setear_icono(icono_defensa, sprite_icono_defensa, defensa > 0)
	movimiento_label.text = _obtener_texto_principal()
	atributos_label.text = _obtener_texto_atributos()

func _setear_icono(sprite: Sprite2D, textura: Texture2D, tiene_atributo: bool) -> void:
	sprite.texture = textura
	sprite.visible = tiene_atributo and textura != null
	
	if sprite.visible:
		sprite.scale = Vector2(16, 16) / textura.get_size()

func _obtener_texto_principal() -> String:
	var textos := PackedStringArray()
	
	for indice in movimientos.size():
		var direccion := movimientos[indice]
		textos.append("%d. %s %s" % [indice + 1, ICONO_MOVIMIENTO, _obtener_flecha(direccion)])
	
	if ataque > 0:
		textos.append("%s %d" % [ICONO_ATAQUE, ataque])
	
	if defensa > 0:
		textos.append("%s %d" % [ICONO_DEFENSA, defensa])
	
	return "\n".join(textos)


func _obtener_texto_atributos() -> String:
	var textos := PackedStringArray()
	
	if not movimientos.is_empty():
		textos.append(ICONO_MOVIMIENTO)
	
	if ataque > 0:
		textos.append("%s %d" % [ICONO_ATAQUE, ataque])
	
	if defensa > 0:
		textos.append("%s %d" % [ICONO_DEFENSA, defensa])
	
	return "   ".join(textos)

func _obtener_flecha(direccion: Vector2i) -> String:
	match direccion:
		Vector2i(0, -1):
			return "^"
		Vector2i(0, 1):
			return "v"
		Vector2i(-1, 0):
			return "<"
		Vector2i(1, 0):
			return ">"
		Vector2i(-1, -1):
			return "<^"
		Vector2i(1, -1):
			return "^>"
		Vector2i(-1, 1):
			return "<v"
		Vector2i(1, 1):
			return "v>"
		_:
			return "(%d, %d)" % [direccion.x, direccion.y]
