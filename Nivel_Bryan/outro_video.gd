extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

# Lista de todas las salas iniciales del equipo
const NIVELES_POSIBLES: Array[String] = [
	"res://Nivel_Bryan/sala_1.tscn",
	"res://Nivel_E/sala_1.tscn",
	"res://Nivel_Melyssa/sala_1.tscn",
	"res://Nivel_Sofia/sala_1.tscn"
]

# Escena de respaldo si las demás no existen todavía
const ESCENA_RESPALDO: String = "res://Nivel_Bryan/sala_1.tscn"

var puede_saltar: bool = false

func _ready() -> void:
	video_player.loop = false
	video_player.finished.connect(_on_video_finished)
	video_player.play()
	
	# Pequeño retraso para evitar que un clic residual del menú salte el video al instante
	get_tree().create_timer(0.6).timeout.connect(func(): puede_saltar = true)

func _input(event: InputEvent) -> void:
	if not puede_saltar:
		return
		
	# Permitir saltar con cualquier tecla o clic del ratón
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		_finalizar()

func _on_video_finished() -> void:
	_finalizar()

func _finalizar() -> void:
	set_process_input(false)
	
	# Reinicio del estado de tu nivel
	GestorEstadoNivelBryan.laser_resuelto = false
	GestorEstadoNivelBryan.cilindros_resuelto = false
	GestorEstadoNivelBryan.cilindros_valores_guardados.clear()
	GestorEstadoNivelBryan.laser_posiciones_hojas.clear()
	GestorEstadoNivelBryan.laser_texturas_hojas.clear()
	GestorEstadoNivelBryan.laser_incisos_guardados.clear()
	
	# Filtrar solo las escenas que realmente existen en el disco
	var niveles_validos: Array[String] = []
	for ruta in NIVELES_POSIBLES:
		if ResourceLoader.exists(ruta):
			niveles_validos.append(ruta)
			
	# Seleccionar una sala aleatoria entre las válidas
	var escena_destino: String = ESCENA_RESPALDO
	if not niveles_validos.is_empty():
		randomize()
		escena_destino = niveles_validos[randi() % niveles_validos.size()]
	
	print("Video finalizado. Transición a: ", escena_destino)
	get_tree().change_scene_to_file(escena_destino)
