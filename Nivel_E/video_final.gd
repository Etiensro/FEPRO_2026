extends VideoStreamPlayer

var ya_avanzo: bool = false

func _ready() -> void:
	set_process_input(true)
	# Conectamos la señal finished por código para asegurar que responda
	if not finished.is_connected(_on_finished):
		finished.connect(_on_finished)
	play()

func _process(_delta: float) -> void:
	pass

func _on_finished() -> void:
	print("Video terminado. Avanzando en el tour de niveles...")
	_avanzar_siguiente_nivel()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		print("Video saltado por el usuario. Avanzando en el tour...")
		_avanzar_siguiente_nivel()

func _avanzar_siguiente_nivel() -> void:
	if ya_avanzo:
		return
	ya_avanzo = true
	set_process_input(false)
	
	# Solicita la siguiente sala excluyendo la entrada de Etienne
	var siguiente_destino = GestorRutaJuego.obtener_siguiente_sala("res://Nivel_E/Hub_Principal.tscn")
	
	print("--- TOUR DE NIVELES ---")
	print("Salas pendientes restantes: ", GestorRutaJuego.salas_pendientes)
	print("Cambiando a la sala: ", siguiente_destino)
	
	if siguiente_destino != "":
		if get_tree().root.has_node("TransicionGlobal"):
			TransicionGlobal.cambiar_escena(siguiente_destino)
		else:
			get_tree().change_scene_to_file(siguiente_destino)
	else:
		print("¡Todas las salas concluidas! Subiendo telemetría final completa a Firestore...")
		# SUBIDA ÚNICA A FIRESTORE
		if get_tree().root.has_node("GestorTelemetria"):
			GestorTelemetria.enviar_reporte_acumulado("victoria")
			
		if get_tree().root.has_node("TransicionGlobal"):
			TransicionGlobal.cambiar_escena("res://Menu_lvl/Menu.tscn")
		else:
			get_tree().change_scene_to_file("res://Menu_lvl/Menu.tscn")
