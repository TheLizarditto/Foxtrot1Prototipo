extends Node2D

const FORMA := [
	"..###....###..",
	".#hhh#..#rrr#.",
	"#hllhh##rrrrr#",
	"#hlhhhrrrrrrr#",
	"#hhhrrrrrrrrr#",
	"#hhrrrrrrrrss#",
	".#rrrrrrrrss#.",
	"..#rrrrrrss#..",
	"...#rrrrss#...",
	"....#rrss#....",
	".....#ss#.....",
	"......##......",
]
const PALETA := {
	"#": Color.BLACK,
	"r": Color("c9323d"),
	"h": Color("f07870"),
	"l": Color("ffd1b5"),
	"s": Color("7f2337"),
}
# Tonos de la interfaz: el corazon vacio queda hundido y conserva fondo propio.
const FONDO_VACIO := Color("2c2b46")
const LUZ_VACIO := Color("49465e")
const SOMBRA_VACIO := Color("191824")
const OPACIDAD_REPOSO := 0.5
const DURACION_RESALTADO_DANO := 0.85
const TAMANO_PIXEL := 2
const POR_FILA := 10
const ANCHO_CORAZON := 14 * TAMANO_PIXEL
const ALTO_CORAZON := 12 * TAMANO_PIXEL
const PASO_FILA := ALTO_CORAZON + 4

@export var ruta_combatiente: NodePath

var puntos_vida := 0
var vida_maxima := 0
var zona_hover := Rect2()
var ancho_fila := 306.0
var tiempo_resaltado_dano := 0.0


func _ready() -> void:
	var tablero := get_node("../Tablero")
	ancho_fila = tablero.columnas * tablero.tamano_celda.x - 14.0
	var combatiente := get_node(ruta_combatiente)
	combatiente.vida_cambiada.connect(_actualizar)
	_actualizar(combatiente.puntos_vida, combatiente.vida_maxima)


func _actualizar(actual: int, maxima: int) -> void:
	if actual < puntos_vida and maxima == vida_maxima:
		tiempo_resaltado_dano = DURACION_RESALTADO_DANO
	puntos_vida = actual
	vida_maxima = maxima
	var filas := ceili(float(vida_maxima) / POR_FILA)
	var alto := filas * PASO_FILA - 4
	zona_hover = Rect2(Vector2(-ancho_fila / 2.0, -alto / 2.0), Vector2(ancho_fila, alto))
	_actualizar_hover(get_global_mouse_position())
	queue_redraw()


func _process(delta: float) -> void:
	tiempo_resaltado_dano = maxf(tiempo_resaltado_dano - delta, 0.0)
	_actualizar_hover(get_global_mouse_position())


func _actualizar_hover(posicion_mouse: Vector2) -> void:
	var bajo_mouse := zona_hover.has_point(to_local(posicion_mouse))
	# El dano vuelve a destacar la vida aunque el puntero este en otra parte.
	var intensidad := 1.0 if bajo_mouse else minf(tiempo_resaltado_dano / 0.2, 1.0)
	modulate.a = lerpf(OPACIDAD_REPOSO, 1.0, intensidad)
	z_index = 5 if bajo_mouse or tiempo_resaltado_dano > 0.0 else -1


func _draw() -> void:
	# Cada corazon representa un PV; solo el exterior de la silueta es transparente.
	for indice in range(vida_maxima):
		var columna := indice % POR_FILA
		var fila := floori(float(indice) / POR_FILA)
		var paso_x := (ancho_fila - ANCHO_CORAZON) / (POR_FILA - 1)
		var origen := (zona_hover.position + Vector2(columna * paso_x, fila * PASO_FILA)).round()
		for y in range(FORMA.size()):
			for x in range(FORMA[y].length()):
				var pixel: String = FORMA[y][x]
				if pixel == ".":
					continue
				var color: Color = PALETA[pixel]
				if indice >= puntos_vida and pixel != "#":
					color = FONDO_VACIO
					if y <= 2:
						color = LUZ_VACIO
					elif pixel == "s":
						color = SOMBRA_VACIO
				draw_rect(Rect2(origen + Vector2(x, y) * TAMANO_PIXEL, Vector2.ONE * TAMANO_PIXEL), color)
