# Ejecutar: Godot --headless --path . --script res://Tests/verificar_idle.gd
extends SceneTree

var caballero: Node2D
var dragon: Node2D
var ritmo: Node


func _initialize() -> void:
	_verificar.call_deferred()


func _comprobar_sincronia() -> void:
	assert(caballero.sprite.is_playing() and dragon.sprite.is_playing())
	assert(String(caballero.sprite.animation).begins_with("reposo_"))
	assert(dragon.sprite.animation == &"idle")
	assert(caballero.sprite.frame == dragon.sprite.frame)
	assert(is_equal_approx(caballero.sprite.frame_progress, dragon.sprite.frame_progress))


func _verificar() -> void:
	var escena := load("res://Scenes/main.tscn").instantiate() as Node2D
	var turno := escena.get_node("Turno")
	escena.remove_child(turno)
	turno.free()
	root.add_child(escena)
	current_scene = escena
	await process_frame
	caballero = escena.get_node("Personaje")
	dragon = escena.get_node("Enemigo")
	ritmo = escena.get_node("RitmoIdle")
	for direccion in caballero.NOMBRES_DIRECCION:
		var animacion := StringName("reposo_" + direccion)
		assert(caballero.sprite.sprite_frames.get_frame_count(animacion) == 2)
		assert(caballero.sprite.sprite_frames.get_animation_speed(animacion) == 3.0)
	assert(dragon.sprite.sprite_frames.get_frame_count("idle") == 2)
	_comprobar_sincronia()

	# Las dos poses se distinguen sin mover el apoyo de las botas.
	ritmo.fase = 0.0
	ritmo.sincronizar(caballero.sprite)
	var apoyo_0: float = (39.0 + caballero.sprite.offset.y) * caballero.sprite.scale.y
	var escala_0: Vector2 = caballero.sprite.scale
	ritmo.fase = 1.0
	ritmo.sincronizar(caballero.sprite)
	var apoyo_1: float = (39.0 + caballero.sprite.offset.y) * caballero.sprite.scale.y
	assert(is_equal_approx(apoyo_0, apoyo_1))
	assert(escala_0 != caballero.sprite.scale)
	# Un salto largo o irregular no deja acumular desfase entre sprites.
	for delta in [0.0, 0.13, 0.42, 1.7, 9.8]:
		ritmo._process(delta)
		_comprobar_sincronia()

	await caballero.movimiento(Vector2i.DOWN)
	_comprobar_sincronia()
	await caballero.atacar(3)
	await dragon.tween_herida.finished
	_comprobar_sincronia()
	await caballero.defender(1)
	_comprobar_sincronia()
	dragon.recibir_dano(1)
	await create_timer(0.03).timeout
	dragon.recibir_dano(1)
	await dragon.tween_herida.finished
	_comprobar_sincronia()

	var fase_antes: float = ritmo.fase
	paused = true
	await create_timer(0.08, true).timeout
	assert(ritmo.fase == fase_antes)
	_comprobar_sincronia()
	paused = false
	for velocidad in [0.5, 1.75, 1.0]:
		Engine.time_scale = velocidad
		await create_timer(0.12).timeout
		_comprobar_sincronia()
	print("OK: idle de dos poses, pies estables y fase compartida tras acciones, heridas, pausas y cambios de velocidad.")
	quit()
