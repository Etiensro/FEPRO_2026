extends VideoStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process_input(true)
	# Asegurarnos de que el video reproduzca al entrar
	play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_finished() -> void:
	print("Video terminado. Avanzando en el tour de niveles...")
	_avanzar_siguiente_nivel()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		print("Video saltado por el usuario. Avanzando en el tour...")
		_avanzar_siguiente_nivel()

func _avanzar_siguiente_nivel() -> void:
	# 1. Excluir tu propia intro de las pendientes del tour (si aplica)
	GestorRutaJuego.salas_pendientes.erase("res://Nivel_E/Hub_Principal.tscn")
	
	# 2. Pedir al gestor global la siguiente sala única al azar
	var siguiente_destino = GestorRutaJuego.obtener_siguiente_sala()
	
	print("--- TOUR DE NIVELES ---")
	print("Salas pendientes restantes: ", GestorRutaJuego.salas_pendientes)
	print("Cambiando a la sala: ", siguiente_destino)
	
	# 3. Realizar la transición usando tu sistema global actual
	if siguiente_destino != "":
		if Engine.has_singleton("TransicionGlobal"):
			TransicionGlobal.cambiar_escena(siguiente_destino)
		else:
			get_tree().change_scene_to_file(siguiente_destino)
	else:
		print("¡Juego terminado! Regresando al menú...")
		get_tree().change_scene_to_file("res://Menu_lvl/Menu.tscn")
