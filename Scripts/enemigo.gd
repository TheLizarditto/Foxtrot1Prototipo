extends "res://Scripts/combatiente.gd"

@export var ruta_tablero: NodePath = "../Tablero"
@export var distancia_tablero := 72.0

const EFECTO_HERIDA := preload("res://Assets/Dragon2/herida.gdshader")
const POSES_ORIGINALES := preload("res://Assets/Dragon2/femDrag_frontWalk.png")
const ANIMACIONES_ATAQUE := [&"ataque_fuego", &"ataque_garras", &"ataque_mordida"]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var material_herida: ShaderMaterial
var tween_herida: Tween
var posicion_reposo := Vector2.ZERO
var escala_reposo := Vector2.ONE
var tween_ataque: Tween
var atacando := false


func _ready() -> void:
	super._ready()
	posicion_reposo = sprite.position
	escala_reposo = sprite.scale
	_preparar_animaciones_ataque()
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


func _preparar_animaciones_ataque() -> void:
	sprite.sprite_frames = sprite.sprite_frames.duplicate() as SpriteFrames
	var reposo_0 := sprite.sprite_frames.get_frame_texture("idle", 0)
	var reposo_1 := sprite.sprite_frames.get_frame_texture("idle", 1)
	var poses: Array[Texture2D] = []
	for region in [Rect2(0, 0, 64, 96), Rect2(64, 0, 64, 96), Rect2(0, 96, 64, 96)]:
		var pose := AtlasTexture.new()
		pose.atlas = POSES_ORIGINALES
		pose.region = region
		poses.append(pose)
	var secuencias := [
		[reposo_0, reposo_1, poses[2], reposo_1],
		[reposo_0, poses[0], poses[1], poses[2]],
		[reposo_1, poses[2], poses[0], reposo_1],
	]
	for indice in range(ANIMACIONES_ATAQUE.size()):
		var nombre: StringName = ANIMACIONES_ATAQUE[indice]
		sprite.sprite_frames.add_animation(nombre)
		sprite.sprite_frames.set_animation_loop(nombre, false)
		sprite.sprite_frames.set_animation_speed(nombre, 8.0)
		for textura in secuencias[indice]:
			sprite.sprite_frames.add_frame(nombre, textura)


func preparar_animacion_ataque(tipo: int) -> void:
	if tween_herida != null and tween_herida.is_running():
		await tween_herida.finished
	atacando = true
	sprite.position = posicion_reposo
	sprite.rotation = 0.0
	sprite.scale = escala_reposo
	sprite.play(ANIMACIONES_ATAQUE[tipo])
	tween_ataque = create_tween().set_parallel(true)
	var preparacion := Vector2(0, -6) if tipo != 1 else Vector2(-8, -4)
	tween_ataque.tween_property(sprite, "position", posicion_reposo + preparacion, 0.28)
	tween_ataque.tween_property(sprite, "scale", escala_reposo * Vector2(1.04, 0.96), 0.28)
	tween_ataque.tween_property(sprite, "rotation", -0.07 if tipo == 1 else 0.0, 0.28)
	await tween_ataque.finished


func obtener_boca_global() -> Vector2:
	return sprite.to_global(Vector2(0, -62))


func impactar_ataque(tipo: int) -> void:
	if tween_ataque != null and tween_ataque.is_valid():
		tween_ataque.kill()
	sprite.pause()
	tween_ataque = create_tween().set_parallel(true)
	var empuje := Vector2(8, 4) if tipo == 1 else Vector2(0, 10 if tipo == 2 else 3)
	tween_ataque.tween_property(sprite, "position", posicion_reposo + empuje, 0.1)
	tween_ataque.tween_property(sprite, "rotation", 0.07 if tipo == 1 else 0.0, 0.1)
	tween_ataque.tween_property(sprite, "scale", escala_reposo, 0.1)


func terminar_animacion_ataque() -> void:
	if tween_ataque != null and tween_ataque.is_running():
		await tween_ataque.finished
	tween_ataque = create_tween().set_parallel(true)
	tween_ataque.tween_property(sprite, "position", posicion_reposo, 0.18)
	tween_ataque.tween_property(sprite, "rotation", 0.0, 0.18)
	tween_ataque.tween_property(sprite, "scale", escala_reposo, 0.18)
	await tween_ataque.finished
	atacando = false
	_mostrar_reposo()


func _draw() -> void:
	# Sombra escalonada bajo las patas para apoyar el sprite sobre el suelo.
	var sombra := Color(0.09, 0.08, 0.12, 0.3)
	draw_rect(Rect2(-45, -9, 90, 3), sombra)
	draw_rect(Rect2(-55, -6, 110, 6), sombra)
	draw_rect(Rect2(-45, 0, 90, 3), sombra)
