# Ejecutar: Godot --headless --path . --script res://Tests/verificar_vida.gd
extends SceneTree


func _initialize() -> void:
	_verificar.call_deferred()


func _verificar() -> void:
	var escena := load("res://Scenes/main.tscn").instantiate() as Node2D
	var turno := escena.get_node("Turno")
	escena.remove_child(turno)
	turno.free()
	root.add_child(escena)
	current_scene = escena
	await process_frame
	var caballero := escena.get_node("Personaje") as Node2D
	var dragon := escena.get_node("Enemigo") as Node2D
	var vida_caballero := escena.get_node("VidaCaballero") as Node2D
	var vida_dragon := escena.get_node("VidaDragon") as Node2D
	assert(caballero.puntos_vida == 10 and caballero.vida_maxima == 10)
	assert(dragon.puntos_vida == 20 and dragon.vida_maxima == 20)
	assert(vida_caballero.puntos_vida == 10 and vida_caballero.vida_maxima == 10)
	assert(vida_dragon.puntos_vida == 20 and vida_dragon.vida_maxima == 20)
	assert(vida_caballero.zona_hover.size == Vector2(306, 24))
	assert(vida_dragon.zona_hover.size == Vector2(306, 52))
	assert(vida_caballero.position.y - 12 > 160)
	assert(vida_caballero.position.y + 12 < escena.get_node("Mano").position.y - 64)
	assert(vida_dragon.position.y - 26 > dragon.position.y)
	assert(vida_dragon.position.y + 26 < -160)
	vida_dragon._actualizar_hover(Vector2(1000, 1000))
	assert(vida_dragon.z_index < caballero.z_index)
	assert(is_equal_approx(vida_dragon.modulate.a, 0.5))
	vida_dragon._actualizar_hover(vida_dragon.global_position)
	assert(vida_dragon.z_index > caballero.z_index)
	assert(is_equal_approx(vida_dragon.modulate.a, 1.0))
	vida_dragon._actualizar_hover(Vector2(1000, 1000))
	assert(caballero.recibir_dano(3) == 3)
	assert(caballero.puntos_vida == 7 and vida_caballero.puntos_vida == 7)
	assert(dragon.recibir_dano(5) == 5)
	assert(dragon.puntos_vida == 15 and vida_dragon.puntos_vida == 15)
	vida_dragon._actualizar_hover(Vector2(1000, 1000))
	assert(is_equal_approx(vida_dragon.modulate.a, 1.0))
	assert(vida_dragon.z_index > caballero.z_index)
	assert(vida_caballero.vida_maxima == 10 and vida_dragon.vida_maxima == 20)
	assert(caballero.recibir_dano(-2) == 0)
	assert(caballero.puntos_vida == 7)
	await process_frame # Dibuja tambien los marcos vacios despues del dano.
	if "--capturar" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/corazones-dano.png")
	assert(caballero.recibir_dano(100) == 7)
	assert(caballero.puntos_vida == 0 and vida_caballero.puntos_vida == 0)
	assert(dragon.recibir_dano(100) == 15)
	assert(dragon.puntos_vida == 0 and vida_dragon.puntos_vida == 0)
	assert(vida_caballero.vida_maxima == 10 and vida_dragon.vida_maxima == 20)
	assert(dragon.recibir_dano(1) == 0)

	# El valor de ataque de la carta se aplica una vez en el fotograma de impacto.
	dragon.puntos_vida = 20
	var impactos: Array[int] = []
	dragon.vida_cambiada.connect(func(_actual: int, _maxima: int) -> void:
		impactos.append(caballero.sprite.frame)
	)
	var carta := load("res://Scenes/carta.tscn").instantiate() as Carta
	carta.ataque = 3
	escena.add_child(carta)
	await carta.ejecutar(caballero)
	assert(dragon.puntos_vida == 17 and vida_dragon.puntos_vida == 17)
	assert(impactos == [2])
	await create_timer(0.35).timeout
	assert(is_zero_approx(dragon.material_herida.get_shader_parameter("intensidad")))
	assert(dragon.sprite.position == dragon.posicion_reposo)
	assert(is_zero_approx(dragon.sprite.rotation))
	assert(dragon.sprite.is_playing() and dragon.sprite.animation == &"idle")
	# Reiniciar el efecto ante dos impactos seguidos no deja desplazamientos ni tintes.
	dragon.recibir_dano(1)
	assert(dragon.material_herida.get_shader_parameter("intensidad") == 1.0)
	await create_timer(0.03).timeout
	dragon.recibir_dano(1)
	await create_timer(0.35).timeout
	assert(dragon.puntos_vida == 15)
	assert(is_zero_approx(dragon.material_herida.get_shader_parameter("intensidad")))
	assert(dragon.sprite.position == dragon.posicion_reposo)
	await create_timer(0.6).timeout
	vida_dragon._actualizar_hover(Vector2(1000, 1000))
	assert(is_equal_approx(vida_dragon.modulate.a, 0.5))
	assert(vida_dragon.z_index < caballero.z_index)
	vida_dragon._actualizar_hover(vida_dragon.global_position)
	assert(is_equal_approx(vida_dragon.modulate.a, 1.0))
	assert(vida_dragon.z_index > caballero.z_index)
	print("OK: vida, dano sincronizado, transparencia y resaltado temporal por dano o mouse.")
	quit()
