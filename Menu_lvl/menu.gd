extends Control

@onready var input_usuario: LineEdit = $Interfaz/InputUsuario
@onready var input_sala: LineEdit = $Interfaz/InputSala
@onready var btn_confirmar: Button = $Interfaz/BtnConfirmar
@onready var btn_profesor: Button = $Interfaz/BtnProfesor
@onready var label_estado: Label = $Interfaz/LabelEstado
@onready var peticion_http: HTTPRequest = $HTTPRequest

const PROJECT_ID: String = "lore-fepro"

# Rutas de inicio de cada sala
const SALA_BRYAN: String = "res://Nivel_Bryan/intro_video.tscn"
const SALA_ETIENNE: String = "res://Nivel_E/Hub_Principal.tscn"

func _ready() -> void:
	label_estado.text = ""
	btn_confirmar.pressed.connect(_on_btn_confirmar_pressed)
	peticion_http.request_completed.connect(_on_sala_verificada)
	
	if btn_profesor:
		btn_profesor.pressed.connect(_on_btn_profesor_pressed)
	
	input_usuario.text_submitted.connect(func(_t): input_sala.grab_focus())
	input_sala.text_submitted.connect(func(_t): _on_btn_confirmar_pressed())

func _on_btn_confirmar_pressed() -> void:
	var usuario = input_usuario.text.strip_edges()
	var sala = input_sala.text.strip_edges()
	
	if usuario.is_empty():
		_mostrar_error("Por favor, ingresa tu nombre.")
		return
		
	if sala.is_empty():
		_mostrar_error("Por favor, ingresa el PIN de la clase.")
		return
		
	btn_confirmar.disabled = true
	input_usuario.editable = false
	input_sala.editable = false
	label_estado.modulate = Color(1.0, 1.0, 1.0)
	label_estado.text = "Conectando con la sala..."
	
	var url = "https://firestore.googleapis.com/v1/projects/" + PROJECT_ID + "/databases/(default)/documents/salas_activas/" + sala
	var headers = ["Content-Type: application/json"]
	
	var err = peticion_http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		_mostrar_error("Error local de red al enviar petición.")

func _on_sala_verificada(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var raw_text = body.get_string_from_utf8()
		var json = JSON.new()
		var parse_result = json.parse(raw_text)
		
		if parse_result != OK or not (json.data is Dictionary):
			_mostrar_error("Error al procesar la información de la sala.")
			return
			
		var doc_data: Dictionary = json.data
		var campos: Dictionary = doc_data.get("fields", {})
		
		print("--- DEBUG SALA ---")
		print("Campos encontrados en Firestore: ", campos.keys())
		
		# Guardar sesión en el gestor global
		var cod_sala = input_sala.text.strip_edges()
		var nom_usuario = input_usuario.text.strip_edges()
		
		if get_tree().root.has_node("GestorTelemetria"):
			if "codigo_sala" in GestorTelemetria:
				GestorTelemetria.codigo_sala = cod_sala
			if "alumno_id" in GestorTelemetria:
				GestorTelemetria.alumno_id = nom_usuario
		
		# Selección de nivel según los campos devueltos por Firestore
		var escena_destino: String = SALA_BRYAN
		
		if campos.has("escena_computadora") or campos.has("carrito_fase") or campos.has("tuneles_fase"):
			escena_destino = SALA_ETIENNE
		elif campos.has("laser_puzzles") or campos.has("tema_1") or campos.has("tema_2"):
			escena_destino = SALA_BRYAN
		else:
			print("Aviso: Formato desconocido, redirigiendo a intro de Bryan.")
			escena_destino = SALA_BRYAN

		print("Escena elegida: ", escena_destino)
		print("¿El archivo existe físicamente?: ", ResourceLoader.exists(escena_destino))

		if not ResourceLoader.exists(escena_destino):
			print("ERROR: La ruta '", escena_destino, "' no existe en el proyecto. Forzando a SALA_BRYAN.")
			escena_destino = SALA_BRYAN
			
		label_estado.modulate = Color(0.4, 1.0, 0.4)
		label_estado.text = "¡Sala encontrada! Entrando al nivel..."
		
		var timer = get_tree().create_timer(1.0)
		timer.timeout.connect(func():
			get_tree().change_scene_to_file(escena_destino)
		)
		
	elif response_code == 404:
		_mostrar_error("El PIN de clase no existe en la base de datos.")
	else:
		_mostrar_error("Error del servidor (" + str(response_code) + ")")

func _mostrar_error(msg: String) -> void:
	label_estado.modulate = Color(1.0, 0.4, 0.4)
	label_estado.text = msg
	btn_confirmar.disabled = false
	input_usuario.editable = true
	input_sala.editable = true

func _on_btn_profesor_pressed() -> void:
	print("Abriendo panel de profesores...")
