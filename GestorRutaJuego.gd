extends Node

const TODAS_LAS_SALAS: Array[String] = [
	"res://Nivel_Bryan/intro_video.tscn",
	"res://Nivel_E/Hub_Principal.tscn",
	"res://Nivel_Melyssa/intro_esferas.tscn",
	"res://Nivel_Sofia/nivel_carrito.tscn"
]

# Cinemática final al completar todas las salas
const ESCENA_GAME_WIN: String = "res://game_win.tscn"
const ESCENA_MENU_FALLBACK: String = "res://Menu_lvl/Menu.tscn"

var salas_pendientes: Array[String] = []
var sala_visitada_actual: String = ""

func _ready() -> void:
	reiniciar_recorridos()

# Inicializa y baraja el orden de las salas para una nueva partida
func reiniciar_recorridos() -> void:
	salas_pendientes = TODAS_LAS_SALAS.duplicate()
	salas_pendientes.shuffle()
	sala_visitada_actual = ""
	
	if get_tree().root.has_node("GestorTelemetria"):
		GestorTelemetria.reiniciar_telemetria()
		
	print("\n========================================")
	print(" [GESTOR RUTA] Tour reiniciado y barajado:")
	for i in range(salas_pendientes.size()):
		print("  %d. %s" % [i + 1, salas_pendientes[i]])
	print("========================================\n")

# Para iniciar la partida directamente desde el Menú Principal
func iniciar_nueva_partida() -> void:
	reiniciar_recorridos()
	var primera_sala: String = salas_pendientes.pop_front()
	sala_visitada_actual = primera_sala
	print("--- [GESTOR RUTA] Primera sala asignada: %s (Restantes en cola: %d) ---" % [primera_sala, salas_pendientes.size()])
	get_tree().change_scene_to_file(primera_sala)

# Método pasivo: Devuelve la ruta de la siguiente sala o del video final
func obtener_siguiente_sala(sala_actual: String = "") -> String:
	# 1. Eliminar de pendientes la sala que acaba de terminarse
	if not sala_actual.is_empty():
		salas_pendientes.erase(sala_actual)
	elif not sala_visitada_actual.is_empty():
		salas_pendientes.erase(sala_visitada_actual)

	# 2. Si la cola quedó vacía, se completó todo el juego
	if salas_pendientes.is_empty():
		print("\n==================================================")
		print(" ¡TODAS LAS SALAS COMPLETADAS! LANZANDO CINEMÁTICA")
		print("==================================================\n")
		
		# Registro y reporte final a Firestore
		if get_tree().root.has_node("GestorTelemetria"):
			GestorTelemetria.enviar_reporte_acumulado("victoria")
		
		if ResourceLoader.exists(ESCENA_GAME_WIN):
			return ESCENA_GAME_WIN
		else:
			print("Aviso: No se encontró game_win.tscn. Devolviendo menú.")
			return ESCENA_MENU_FALLBACK
		
	# 3. Si aún hay salas, extrae la siguiente
	var siguiente: String = salas_pendientes.pop_front()
	sala_visitada_actual = siguiente
	print("--- [GESTOR RUTA] Próxima sala obtenida: %s (Quedan: %d) ---" % [siguiente, salas_pendientes.size()])
	return siguiente

# Método activo: Realiza el cambio de escena automáticamente
func avanzar_siguiente_sala(sala_actual: String = "") -> void:
	var prox: String = obtener_siguiente_sala(sala_actual)
	get_tree().change_scene_to_file(prox)
