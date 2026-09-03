extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

# Lista con las 4 rutas de las salas iniciales del equipo
const NIVELES_POSIBLES: Array[String] = [
	"res://Nivel_Bryan/sala_1.tscn",
	"res://Nivel_E/Hub_Principal.tscn",
	"res://Nivel_Melyssa/intro_esferas.tscn",
	"res://Nivel_Sofia/nivel_carrito.tscn",
]

# Ruta de tu propia sala que deseas excluir para que no te toque a ti mismo
const RUTA_PROPIA: String = "res://Nivel_Bryan/sala_1.tscn"

# Escena de respaldo por si las demás no existen
const ESCENA_RESPALDO: String = "res://Nivel_E/Hub_Principal.tscn"

var puede_saltar: bool = false

func _ready() -> void:
	video_player.loop = false
	video_player.finished.connect(_on_video_finished)
	video_player.play()
	
	# Retraso breve para evitar que clics residuales del menú salten el video de golpe
	get_tree().create_timer(0.6).timeout.connect(func(): puede_saltar = true)

func _input(event: InputEvent) -> void:
	if not puede_saltar:
		return
		
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		_finalizar()

func _on_video_finished() -> void:
	_finalizar()

func _finalizar() -> void:
	set_process_input(false)
	
	# Reinicio del estado del nivel
	if typeof(GestorEstadoNivelBryan) != TYPE_NIL:
		GestorEstadoNivelBryan.laser_resuelto = false
		GestorEstadoNivelBryan.cilindros_resuelto = false
		GestorEstadoNivelBryan.cilindros_valores_guardados.clear()
		GestorEstadoNivelBryan.laser_posiciones_hojas.clear()
		GestorEstadoNivelBryan.laser_texturas_hojas.clear()
		GestorEstadoNivelBryan.laser_incisos_guardados.clear()
	
	# Filtrar las rutas que existen y excluir tu propia sala
	var niveles_validos: Array[String] = []
	for ruta in NIVELES_POSIBLES:
		if ruta != RUTA_PROPIA and ResourceLoader.exists(ruta):
			niveles_validos.append(ruta)
			
	# Seleccionar de forma aleatoria entre las de tus compañeros
	var escena_destino: String = ESCENA_RESPALDO
	if not niveles_validos.is_empty():
		escena_destino = niveles_validos.pick_random()
	
	print("--- TRANSICIÓN ALEATORIA (EXCLUYENDO PROPIA) ---")
	print("Salas válidas de otros compañeros: ", niveles_validos)
	print("Sala seleccionada al azar: ", escena_destino)
	
	get_tree().change_scene_to_file(escena_destino)
