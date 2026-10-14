extends Node2D

@export var ruta_tablero: NodePath = "../Tablero"
@export var distancia_tablero := 32.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	var tablero := get_node_or_null(ruta_tablero) as Node2D
	if tablero != null:
		# El origen esta en los pies: todo el dragon queda fuera del tablero.
		var borde_superior: float = -tablero.filas * tablero.tamano_celda.y / 2.0
		global_position = tablero.to_global(Vector2(0, borde_superior - distancia_tablero))
	sprite.play("idle")
	queue_redraw()


func _draw() -> void:
	# Sombra escalonada bajo las patas para apoyar el sprite sobre el suelo.
	var sombra := Color(0.09, 0.08, 0.12, 0.3)
	draw_rect(Rect2(-45, -9, 90, 3), sombra)
	draw_rect(Rect2(-55, -6, 110, 6), sombra)
	draw_rect(Rect2(-45, 0, 90, 3), sombra)
