extends Node

# Las 4 rutas iniciales del equipo
const TODAS_LAS_SALAS: Array[String] = [
	"res://Nivel_Bryan/intro_video.tscn",
	"res://Nivel_E/Hub_Principal.tscn",
	"res://Nivel_Melyssa/intro_esferas.tscn",
	"res://Nivel_Sofia/nivel_carrito.tscn"
]

var salas_pendientes: Array[String] = []

func _ready() -> void:
	reiniciar_recorridos()

# Inicializa y baraja aleatoriamente los niveles
func reiniciar_recorridos() -> void:
	salas_pendientes = TODAS_LAS_SALAS.duplicate()
	salas_pendientes.shuffle()

# Obtiene la siguiente sala única sin repetición en orden aleatorio
func obtener_siguiente_sala(sala_actual: String = "") -> String:
	if salas_pendientes.is_empty():
		reiniciar_recorridos()
	
	if sala_actual in salas_pendientes:
		salas_pendientes.erase(sala_actual)
		
	if salas_pendientes.is_empty():
		return "res://Nivel_Bryan/intro_video.tscn"
		
	return salas_pendientes.pop_front()
