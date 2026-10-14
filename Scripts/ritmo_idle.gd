extends Node

const FOTOGRAMAS := 2
const FPS := 3.0

var fase := 0.0
var participantes: Array[AnimatedSprite2D] = []


func _ready() -> void:
	# Corrige la fase despues de que los sprites y las acciones se actualicen.
	process_priority = 100


func registrar(sprite: AnimatedSprite2D) -> void:
	if not participantes.has(sprite):
		participantes.append(sprite)
	sincronizar(sprite)


func _process(delta: float) -> void:
	# Delta respeta pausa y velocidad del juego; no depende del reloj del sistema.
	fase = fposmod(fase + delta * FPS, FOTOGRAMAS)
	for indice in range(participantes.size() - 1, -1, -1):
		var sprite := participantes[indice]
		if not is_instance_valid(sprite):
			participantes.remove_at(indice)
			continue
		sincronizar(sprite)


func sincronizar(sprite: AnimatedSprite2D) -> void:
	var nombre := String(sprite.animation)
	if not sprite.is_playing() or not (nombre == "idle" or nombre.begins_with("reposo_")):
		return
	sprite.set_frame_and_progress(floori(fase), fposmod(fase, 1.0))
