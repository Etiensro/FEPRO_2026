extends Node

# Las 4 rutas iniciales del equipo
const TODAS_LAS_SALAS: Array[String] = [
	"res://Nivel_Bryan/intro_video.tscn",
	"res://Nivel_E/Hub_Principal.tscn",
	"res://Nivel_Melyssa/intro_esferas.tscn",
	"res://Nivel_Sofia/nivel_carrito.tscn"
]

var salas_pendientes: Array[String] = []
var sala_visitada_actual: String = ""

func _ready() -> void:
	reiniciar_recorridos()

# Inicializa y baraja aleatoriamente los niveles desde cero
func reiniciar_recorridos() -> void:
	salas_pendientes = TODAS_LAS_SALAS.duplicate()
	salas_pendientes.shuffle()
	sala_visitada_actual = ""
	print("--- TOUR REINICIADO Y BARAJADO ---")
	print("Orden aleatorio de esta sesión: ", salas_pendientes)

# Obtiene la siguiente sala única sin repetición
func obtener_siguiente_sala(sala_actual: String = "") -> String:
	# Si la escena actual viene especificada, la borramos de pendientes de inmediato
	if not sala_actual.is_empty():
		salas_pendientes.erase(sala_actual)
	elif not sala_visitada_actual.is_empty():
		salas_pendientes.erase(sala_visitada_actual)

	# Si ya recorrimos todas, terminamos o reiniciamos el ciclo
	if salas_pendientes.is_empty():
		print("¡Todas las salas del tour han sido completadas!")
		return "" # Aquí puedes redirigir a una pantalla de créditos o victoria si lo deseas
		
	# Tomamos el siguiente elemento de la lista barajada
	var siguiente = salas_pendientes.pop_front()
	sala_visitada_actual = siguiente
	
	print("Salas pendientes restantes en la ruleta: ", salas_pendientes)
	print("Siguiente destino asignado: ", siguiente)
	
	return siguiente
