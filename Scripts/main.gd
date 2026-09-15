extends Node2D

const BarajaScript := preload("res://Scripts/baraja.gd")

const CARTAS_BARAJA: Array[Dictionary] = [
	{
		"movimientos": [Vector2i(0, -1)],
		"ataque": 1,
		"defensa": 0,
	},
	{
		"movimientos": [],
		"ataque": 1,
		"defensa": 2,
	},
	{
		"movimientos": [Vector2i(-1, 0)],
		"ataque": 2,
		"defensa": 0,
	},
	{
		"movimientos": [Vector2i(1, 0)],
		"ataque": 1,
		"defensa": 1,
	},
	{
		"movimientos": [Vector2i(0, -2)],
		"ataque": 2,
		"defensa": 1,
	},
	{
		"movimientos": [Vector2i(0, 2)],
		"ataque": 0,
		"defensa": 3,
	},
	{
		"movimientos": [Vector2i(-2, 0)],
		"ataque": 3,
		"defensa": 1,
	},
	{
		"movimientos": [Vector2i(2, 0)],
		"ataque": 1,
		"defensa": 2,
	},
	{
		"movimientos": [Vector2i(0, -1), Vector2i(1, 0)],
		"ataque": 2,
		"defensa": 2,
	},
	{
		"movimientos": [Vector2i(-1, 0), Vector2i(-1, 0), Vector2i(0, 1)],
		"ataque": 3,
		"defensa": 0,
	},
	{
		"movimientos": [Vector2i(1, -1), Vector2i(1, -1)],
		"ataque": 1,
		"defensa": 3,
	},
	{
		"movimientos": [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1)],
		"ataque": 2,
		"defensa": 1,
	},
]

var baraja: Variant


func _ready() -> void:
	baraja = BarajaScript.new()
	baraja.visible = false
	add_child(baraja)
	baraja.crear_cartas(CARTAS_BARAJA)
	baraja.mezclar()
