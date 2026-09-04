extends Node

const TODAS_LAS_SALAS: Array[String] = [
	"res://Nivel_Bryan/intro_video.tscn",
	"res://Nivel_E/Hub_Principal.tscn",
	"res://Nivel_Melyssa/intro_esferas.tscn",
	"res://Nivel_Sofia/nivel_carrito.tscn"
]

# Cambia esta ruta si tienes una escena de fin de juego o créditos; si no, volverá a main.tscn
const ESCENA_FINAL: String = "res://main.tscn"

var salas_pendientes: Array[String] = []
var sala_visitada_actual: String = ""

func _ready() -> void:
	reiniciar_recorridos()

func reiniciar_recorridos() -> void:
	salas_pendientes = TODAS_LAS_SALAS.duplicate()
	salas_pendientes.shuffle()
	sala_visitada_actual = ""
	if get_tree().root.has_node("GestorTelemetria"):
		GestorTelemetria.reiniciar_telemetria()
	print("--- TOUR REINICIADO Y BARAJADO ---")
	print("Orden: ", salas_pendientes)

# Llama a esta función para saltar de sala en sala
func avanzar_siguiente_sala(sala_actual: String = "") -> void:
	var prox = obtener_siguiente_sala(sala_actual)
	
	if prox == "":
		print("¡Todas las salas concluidas! Subiendo telemetría final...")
		if get_tree().root.has_node("GestorTelemetria"):
			GestorTelemetria.enviar_reporte_acumulado("victoria")
		
		get_tree().change_scene_to_file(ESCENA_FINAL)
	else:
		get_tree().change_scene_to_file(prox)

func obtener_siguiente_sala(sala_actual: String = "") -> String:
	if not sala_actual.is_empty():
		salas_pendientes.erase(sala_actual)
	elif not sala_visitada_actual.is_empty():
		salas_pendientes.erase(sala_visitada_actual)

	if salas_pendientes.is_empty():
		return ""
		
	var siguiente = salas_pendientes.pop_front()
	sala_visitada_actual = siguiente
	return siguiente
