extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

var puede_saltar: bool = false

func _ready() -> void:
	video_player.loop = false
	video_player.finished.connect(_on_video_finished)
	video_player.play()
	
	# Retraso breve para evitar que clics residuales salten el video de golpe
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
	
	# Reinicio del estado local del nivel de Bryan
	if typeof(GestorEstadoNivelBryan) != TYPE_NIL:
		GestorEstadoNivelBryan.laser_resuelto = false
		GestorEstadoNivelBryan.cilindros_resuelto = false
		GestorEstadoNivelBryan.cilindros_valores_guardados.clear()
		GestorEstadoNivelBryan.laser_posiciones_hojas.clear()
		GestorEstadoNivelBryan.laser_texturas_hojas.clear()
		GestorEstadoNivelBryan.laser_incisos_guardados.clear()
	
	# Remueve la sala actual y solicita la siguiente de la ruleta
	var escena_destino = GestorRutaJuego.obtener_siguiente_sala("res://Nivel_Bryan/intro_video.tscn")
	
	print("--- TOUR DE NIVELES ---")
	print("Salas pendientes restantes: ", GestorRutaJuego.salas_pendientes)
	print("Destino seleccionado: ", escena_destino)
	
	if escena_destino != "":
		get_tree().change_scene_to_file(escena_destino)
	else:
		print("¡Todas las salas concluidas! Subiendo telemetría final completa a Firestore...")
		# SUBIDA ÚNICA A FIRESTORE
		if get_tree().root.has_node("GestorTelemetria"):
			GestorTelemetria.enviar_reporte_acumulado("victoria")
		
		get_tree().change_scene_to_file("res://Menu_lvl/Menu.tscn")
