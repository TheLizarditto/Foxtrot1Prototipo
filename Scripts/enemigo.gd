extends "res://Scripts/combatiente.gd"

@export var ruta_tablero: NodePath = "../Tablero"
@export var distancia_tablero := 72.0

const EFECTO_HERIDA := preload("res://Assets/Dragon2/herida.gdshader")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var material_herida: ShaderMaterial
var tween_herida: Tween
var posicion_reposo := Vector2.ZERO


func _ready() -> void:
	super._ready()
	posicion_reposo = sprite.position
	material_herida = ShaderMaterial.new()
	material_herida.shader = EFECTO_HERIDA
	sprite.material = material_herida
	var tablero := get_node_or_null(ruta_tablero) as Node2D
	if tablero != null:
		# El origen esta en los pies: todo el dragon queda fuera del tablero.
		var borde_superior: float = -tablero.filas * tablero.tamano_celda.y / 2.0
		global_position = tablero.to_global(Vector2(0, borde_superior - distancia_tablero))
	sprite.play("idle")
	queue_redraw()


func recibir_dano(cantidad: int) -> int:
	var efectivo := super.recibir_dano(cantidad)
	if efectivo > 0:
		_mostrar_herida()
	return efectivo


func _mostrar_herida() -> void:
	if tween_herida != null and tween_herida.is_valid():
		tween_herida.kill()
	sprite.pause()
	sprite.position = posicion_reposo
	sprite.rotation = 0.0
	material_herida.set_shader_parameter("color_destello", Color.WHITE)
	material_herida.set_shader_parameter("intensidad", 1.0)
	tween_herida = create_tween()
	tween_herida.tween_property(sprite, "position", posicion_reposo + Vector2(4, -2), 0.05)
	tween_herida.parallel().tween_property(sprite, "rotation", -0.035, 0.05)
	tween_herida.tween_callback(func() -> void: material_herida.set_shader_parameter("color_destello", Color("ff3838")))
	tween_herida.tween_property(sprite, "position", posicion_reposo + Vector2(-4, 0), 0.06)
	tween_herida.parallel().tween_property(sprite, "rotation", 0.035, 0.06)
	tween_herida.tween_property(sprite, "position", posicion_reposo, 0.18)
	tween_herida.parallel().tween_property(sprite, "rotation", 0.0, 0.18)
	tween_herida.parallel().tween_property(material_herida, "shader_parameter/intensidad", 0.0, 0.18)
	tween_herida.tween_callback(func() -> void: sprite.play("idle"))


func _draw() -> void:
	# Sombra escalonada bajo las patas para apoyar el sprite sobre el suelo.
	var sombra := Color(0.09, 0.08, 0.12, 0.3)
	draw_rect(Rect2(-45, -9, 90, 3), sombra)
	draw_rect(Rect2(-55, -6, 110, 6), sombra)
	draw_rect(Rect2(-45, 0, 90, 3), sombra)
