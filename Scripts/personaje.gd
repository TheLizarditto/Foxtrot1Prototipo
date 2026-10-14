extends Node2D

const DIRECCIONES := [
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
]
const NOMBRES_DIRECCION := ["abajo", "abajo_izquierda", "izquierda", "arriba_izquierda", "arriba", "arriba_derecha", "derecha", "abajo_derecha"]
@export var ruta_tablero: NodePath = "../Tablero"
@export_range(0.1, 1.0, 0.01) var duracion_paso := 0.32
@export_range(1.0, 30.0, 1.0) var velocidad_ataque := 10.0
@export_range(1.0, 30.0, 1.0) var velocidad_defensa := 8.0
@export_range(0.2, 2.0, 0.05) var duracion_sostener_defensa := 0.65

@onready var tablero = get_node(ruta_tablero)
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var brillo_defensa: Node2D = $BrilloDefensa

var posicion := Vector2.ZERO
var direccion_actual := Vector2i(0, -1)
var accion_en_curso := false


func _ready() -> void:
	_preparar_animaciones()
	sprite.frame_changed.connect(_ajustar_fotograma)
	sprite.animation_changed.connect(_ajustar_fotograma)
	_actualizar_posicion_centro()
	_mostrar_reposo()


# Camina hasta la celda vecina y espera a que termine el desplazamiento.
func movimiento(direccion: Vector2i) -> bool:
	if accion_en_curso:
		return false
	var paso := Vector2i(signi(direccion.x), signi(direccion.y))
	if paso == Vector2i.ZERO:
		return false
	var destino := Vector2i(posicion) + paso
	if not tablero.es_posicion_valida(destino.x, destino.y):
		return false

	accion_en_curso = true
	direccion_actual = paso
	posicion = destino
	sprite.play(_nombre_animacion("caminar"))
	var tween := create_tween()
	tween.tween_property(self, "global_position", _posicion_global_celda(), duracion_paso).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	_mostrar_reposo()
	accion_en_curso = false
	return true


# Todas las acciones mantienen la vista de espaldas, sin girar el sprite.
func atacar(valor := 1) -> void:
	if valor > 0:
		await _animar_accion("ataque")


func defender(valor := 1) -> void:
	if valor > 0:
		await _animar_accion("defensa")


func _animar_accion(accion: String) -> void:
	if accion_en_curso:
		return
	accion_en_curso = true
	sprite.play(_nombre_animacion(accion))
	await sprite.animation_finished
	_mostrar_reposo()
	accion_en_curso = false


# Cada personaje usa una copia para poder ajustar las velocidades desde el Inspector.
func _preparar_animaciones() -> void:
	sprite.sprite_frames = sprite.sprite_frames.duplicate() as SpriteFrames
	for direccion in NOMBRES_DIRECCION:
		sprite.sprite_frames.set_animation_speed(StringName("caminar_" + direccion), 4.0 / duracion_paso)
		sprite.sprite_frames.set_animation_speed(StringName("ataque_" + direccion), velocidad_ataque)
		var nombre_defensa := StringName("defensa_" + direccion)
		sprite.sprite_frames.set_animation_speed(nombre_defensa, velocidad_defensa)
		# Los dos fotogramas de guardia comparten la pausa con el escudo levantado.
		for indice in [1, 2]:
			sprite.sprite_frames.set_frame(nombre_defensa, indice, sprite.sprite_frames.get_frame_texture(nombre_defensa, indice), duracion_sostener_defensa * velocidad_defensa / 2.0)


# El reposo usa el PNG original; las poses del atlas mantienen su escala y apoyo.
func _ajustar_fotograma() -> void:
	if String(sprite.animation).begins_with("defensa_") and sprite.frame == 1:
		brillo_defensa.reproducir(duracion_sostener_defensa)
	var textura := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if textura is AtlasTexture:
		sprite.scale = sprite.sprite_frames.get_meta("escala_atlas", Vector2(0.52, 0.52))
		# El golpe tiene un lienzo mas ancho; conserva el mismo apoyo del personaje.
		var origen: Vector2 = sprite.sprite_frames.get_meta("origen_atlas", textura.get_size() * 0.5)
		sprite.offset = textura.get_size() * 0.5 - origen
	else:
		sprite.scale = Vector2(0.52, 0.52)
		sprite.offset = Vector2.ZERO


func _nombre_animacion(accion: String) -> StringName:
	return StringName(accion + "_" + NOMBRES_DIRECCION[DIRECCIONES.find(direccion_actual)])


func _mostrar_reposo() -> void:
	brillo_defensa.ocultar()
	sprite.play(_nombre_animacion("reposo"))


func _actualizar_posicion_centro() -> void:
	posicion = tablero.obtener_centro_tablero()
	global_position = _posicion_global_celda()


func _posicion_global_celda() -> Vector2:
	return tablero.to_global(tablero.obtener_posicion_en_tablero(int(posicion.x), int(posicion.y)))
