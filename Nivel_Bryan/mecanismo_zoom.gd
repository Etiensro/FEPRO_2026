extends Node2D

const ESCENA_RODILLO = preload("res://Nivel_Bryan/Cilindro.tscn")

# --- TEXTURAS BOTÓN COMPROBAR ---
const TEX_BTN_NORMAL = preload("res://Nivel_Bryan/Assets/Boton_Up_Atlas.tres")
const TEX_BTN_DOWN   = preload("res://Nivel_Bryan/Assets/Boton_Down_Atlas.tres")
const TEX_BTN_ERROR  = preload("res://Nivel_Bryan/Assets/Boton_Rojo_Atlas.tres")
const TEX_BTN_EXITO  = preload("res://Nivel_Bryan/Assets/Boton_Verde_Atlas.tres")

const ALFABETO = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
const NUMEROS = ["0","1","2","3","4","5","6","7","8","9"]
const ALFANUMERICO = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]

@onready var contenedor: HBoxContainer = $ContCilindros
@onready var label_pregunta: Label = $LabelPregunta
@onready var btn_comprobar: TextureButton = ($BtnComprobar if has_node("BtnComprobar") else ($BtnComprobador if has_node("BtnComprobador") else null))

var lista_rodillos: Array = []
var clave_correcta: String = ""
var datos_acertijos: Dictionary = {}
var bloqueado: bool = false

# Telemetría pedagógica
var intentos_cilindros: int = 0
var errores_cilindros: Array = []

func _ready() -> void:
	if has_node("Flecha/Area2D"):
		$Flecha/Area2D.input_event.connect(_on_flecha_volver)
		$Flecha/Area2D.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
		$Flecha/Area2D.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))
	
	if btn_comprobar != null:
		btn_comprobar.ignore_texture_size = true
		btn_comprobar.stretch_mode = TextureButton.STRETCH_SCALE
		btn_comprobar.texture_normal = TEX_BTN_NORMAL
		btn_comprobar.texture_pressed = TEX_BTN_DOWN
		btn_comprobar.texture_hover = TEX_BTN_NORMAL
		if not btn_comprobar.pressed.is_connected(_on_btn_comprobar_pressed):
			btn_comprobar.pressed.connect(_on_btn_comprobar_pressed)
	
	if GestorEstadoNivelBryan.cilindros_resuelto:
		_restaurar_estado_resuelto()
	else:
		if get_tree().root.has_node("GestorTelemetria"):
			GestorTelemetria.preguntas_listas.connect(_on_preguntas_listas, CONNECT_ONE_SHOT)
			var clave_elegida = "tema_1" if randf() > 0.5 else "tema_2"
			GestorEstadoNivelBryan.cilindros_id_actual = clave_elegida
			GestorTelemetria.descargar_preguntas(clave_elegida)
		else:
			_fallback_local()

func _on_preguntas_listas(datos_recibidos) -> void:
	var info_acertijo: Dictionary = {}
	
	if datos_recibidos is Dictionary and not datos_recibidos.is_empty():
		info_acertijo = datos_recibidos
	elif datos_recibidos is Array and datos_recibidos.size() > 0:
		info_acertijo = datos_recibidos[0]
		
	if not info_acertijo.is_empty() and info_acertijo.has("objetivo"):
		GestorEstadoNivelBryan.cilindros_pregunta_guardada = str(info_acertijo.get("pregunta", ""))
		GestorEstadoNivelBryan.cilindros_tipo_guardado = str(info_acertijo.get("tipo", "numeros"))
		
		if label_pregunta:
			label_pregunta.text = GestorEstadoNivelBryan.cilindros_pregunta_guardada
		
		var objetivo = str(info_acertijo.get("objetivo", "")).to_upper().strip_edges()
		generar_cilindros_multiples(objetivo, GestorEstadoNivelBryan.cilindros_tipo_guardado)
	else:
		_fallback_local()

func _fallback_local() -> void:
	cargar_json("res://Nivel_Bryan/acertijos.json")
	if GestorEstadoNivelBryan.cilindros_id_actual != "" and datos_acertijos.has(GestorEstadoNivelBryan.cilindros_id_actual):
		cargar_acertijo_desde_json(GestorEstadoNivelBryan.cilindros_id_actual)
	else:
		cargar_acertijo_aleatorio()

func cargar_json(ruta_archivo: String) -> void:
	if not FileAccess.file_exists(ruta_archivo):
		return
	var archivo = FileAccess.open(ruta_archivo, FileAccess.READ)
	var contenido = archivo.get_as_text()
	archivo.close()
	
	var json = JSON.new()
	if json.parse(contenido) == OK and json.data is Dictionary:
		datos_acertijos = json.data

func cargar_acertijo_aleatorio() -> void:
	var claves_validas: Array = []
	for k in datos_acertijos.keys():
		if k != "laser_puzzle" and k != "laser_puzzles":
			claves_validas.append(k)
			
	if claves_validas.is_empty():
		return
		
	var id_seleccionado: String = claves_validas[randi() % claves_validas.size()]
	cargar_acertijo_desde_json(id_seleccionado)

func cargar_acertijo_desde_json(id_acertijo: String) -> void:
	if not datos_acertijos.has(id_acertijo):
		return
		
	var info = datos_acertijos[id_acertijo]
	var tipo = str(info.get("tipo", "numeros"))
	
	GestorEstadoNivelBryan.cilindros_id_actual = id_acertijo
	GestorEstadoNivelBryan.cilindros_pregunta_guardada = str(info.get("pregunta", ""))
	GestorEstadoNivelBryan.cilindros_tipo_guardado = tipo
	
	if label_pregunta:
		label_pregunta.text = GestorEstadoNivelBryan.cilindros_pregunta_guardada
	
	var objetivo = str(info.get("objetivo", "0")).to_upper().strip_edges()
	generar_cilindros_multiples(objetivo, tipo)

func generar_cilindros_multiples(objetivo: String, tipo: String) -> void:
	clave_correcta = objetivo

	for hijo in contenedor.get_children():
		hijo.free()
	lista_rodillos.clear()

	contenedor.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var num_letras = objetivo.length()
	if num_letras >= 5:
		contenedor.add_theme_constant_override("separation", 2)
	elif num_letras == 4:
		contenedor.add_theme_constant_override("separation", 8)
	elif num_letras == 3:
		contenedor.add_theme_constant_override("separation", 16)
	else:
		contenedor.add_theme_constant_override("separation", 24)

	var conjunto = NUMEROS
	if tipo == "letras":
		conjunto = ALFABETO
	elif tipo == "mixto":
		conjunto = ALFANUMERICO

	for i in range(num_letras):
		var nuevo_rodillo = ESCENA_RODILLO.instantiate()
		contenedor.add_child(nuevo_rodillo)
		
		if num_letras >= 5:
			nuevo_rodillo.scale = Vector2(0.85, 0.85)
		else:
			nuevo_rodillo.scale = Vector2(1.0, 1.0)
			
		var valor_inicial = "0" if tipo == "numeros" else ("A" if tipo == "letras" else "0")
		if nuevo_rodillo.has_method("configurar"):
			nuevo_rodillo.configurar(conjunto, valor_inicial)
		lista_rodillos.append(nuevo_rodillo)

func _restaurar_estado_resuelto() -> void:
	bloqueado = true
	
	if btn_comprobar:
		btn_comprobar.texture_normal = TEX_BTN_EXITO
		btn_comprobar.texture_hover = TEX_BTN_EXITO
		btn_comprobar.texture_pressed = TEX_BTN_EXITO
		btn_comprobar.disabled = true
		
	if label_pregunta:
		label_pregunta.text = GestorEstadoNivelBryan.cilindros_pregunta_guardada if GestorEstadoNivelBryan.cilindros_pregunta_guardada != "" else "¡CORRECTO! MECANISMO DESBLOQUEADO"
	
	for hijo in contenedor.get_children():
		hijo.free()
	lista_rodillos.clear()
	
	var letras = GestorEstadoNivelBryan.cilindros_valores_guardados
	var num_letras = letras.size()
	
	var tiene_letras = false
	for c in letras:
		if str(c).to_upper() in ALFABETO and not str(c) in NUMEROS:
			tiene_letras = true
			break
	var conjunto = ALFABETO if tiene_letras else NUMEROS

	contenedor.alignment = BoxContainer.ALIGNMENT_CENTER
	if num_letras >= 5:
		contenedor.add_theme_constant_override("separation", 2)
	elif num_letras == 4:
		contenedor.add_theme_constant_override("separation", 8)
	elif num_letras == 3:
		contenedor.add_theme_constant_override("separation", 16)
	else:
		contenedor.add_theme_constant_override("separation", 24)

	for char_val in letras:
		var nuevo_rodillo = ESCENA_RODILLO.instantiate()
		contenedor.add_child(nuevo_rodillo)
		
		if num_letras >= 5:
			nuevo_rodillo.scale = Vector2(0.85, 0.85)
		else:
			nuevo_rodillo.scale = Vector2(1.0, 1.0)
			
		if nuevo_rodillo.has_method("configurar"):
			nuevo_rodillo.configurar(conjunto, str(char_val))
			
		if nuevo_rodillo.has_node("BtnArriba"):
			nuevo_rodillo.get_node("BtnArriba").disabled = true
		if nuevo_rodillo.has_node("BtnAbajo"):
			nuevo_rodillo.get_node("BtnAbajo").disabled = true
			
		lista_rodillos.append(nuevo_rodillo)

func _on_btn_comprobar_pressed() -> void:
	if bloqueado or GestorEstadoNivelBryan.cilindros_resuelto:
		return
	
	intentos_cilindros += 1
	var respuesta_jugador: String = ""
	for rodillo in lista_rodillos:
		if is_instance_valid(rodillo) and rodillo.has_method("obtener_valor"):
			respuesta_jugador += str(rodillo.obtener_valor()).strip_edges().to_upper()
	
	if respuesta_jugador == clave_correcta:
		_efecto_acierto()
	else:
		var pregunta = GestorEstadoNivelBryan.cilindros_pregunta_guardada
		var detalle_error = "Falló con: '%s' (Pregunta: %s)" % [respuesta_jugador, pregunta]
		errores_cilindros.append(str(detalle_error))
		_efecto_error()

func _efecto_acierto() -> void:
	bloqueado = true
	GestorEstadoNivelBryan.cilindros_resuelto = true
	GestorEstadoNivelBryan.cilindros_valores_guardados = []
	for r in lista_rodillos:
		if is_instance_valid(r) and r.has_method("obtener_valor"):
			GestorEstadoNivelBryan.cilindros_valores_guardados.append(str(r.obtener_valor()).strip_edges().to_upper())

	if btn_comprobar:
		btn_comprobar.texture_normal = TEX_BTN_EXITO
		btn_comprobar.texture_pressed = TEX_BTN_EXITO
		btn_comprobar.texture_hover = TEX_BTN_EXITO
		btn_comprobar.disabled = true
	
	if label_pregunta:
		label_pregunta.text = "¡CORRECTO! MECANISMO DESBLOQUEADO"
	
	var pregunta = GestorEstadoNivelBryan.cilindros_pregunta_guardada
	var detalle_acierto: Array = [
		"Acertó con: '%s' (Pregunta: %s)" % [clave_correcta, pregunta]
	]
	
	# Genera el ID legible con la hora exacta
	var hora_actual = Time.get_time_string_from_system().replace(":", "-")
	var nombre_doc = "Juego_Cilindros_" + hora_actual
	
	_enviar_a_firestore_con_nombre(
		nombre_doc,
		"jugador_bryan",
		"victoria",
		intentos_cilindros,
		detalle_acierto,
		errores_cilindros
	)
	
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.chain().tween_callback(func():
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		_redirigir_sala()
	)

func _enviar_a_firestore_con_nombre(id_documento: String, alumno: String, estado: String, disparos: int, aciertos: Array, errores: Array) -> void:
	var http_custom = HTTPRequest.new()
	add_child(http_custom)
	
	http_custom.request_completed.connect(func(_result, code, _headers, _body):
		if code == 200:
			print("¡Documento de Cilindros creado con éxito! ID: ", id_documento)
		else:
			print("Error al guardar reporte de Cilindros: ", code)
		http_custom.queue_free()
	)
	
	var project_id = "lore-fepro"
	var url = "https://firestore.googleapis.com/v1/projects/" + project_id + "/databases/(default)/documents/telemetria_resultados/" + id_documento
	var headers = ["Content-Type: application/json"]
	
	var array_errores = []
	for e in errores:
		array_errores.append({"stringValue": str(e)})
		
	var array_aciertos = []
	for a in aciertos:
		array_aciertos.append({"stringValue": str(a)})
	
	var cuerpo = {
		"fields": {
			"alumno_id": { "stringValue": str(alumno) },
			"estado_final": { "stringValue": str(estado) },
			"total_disparos": { "integerValue": str(disparos) },
			"historial_aciertos": { "arrayValue": { "values": array_aciertos } },
			"historial_errores": { "arrayValue": { "values": array_errores } }
		}
	}
	
	http_custom.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(cuerpo))

func _efecto_error() -> void:
	bloqueado = true

	if not btn_comprobar:
		bloqueado = false
		return
		
	btn_comprobar.texture_normal = TEX_BTN_ERROR
	btn_comprobar.texture_hover = TEX_BTN_ERROR
	btn_comprobar.texture_pressed = TEX_BTN_ERROR
	
	var pos_original = btn_comprobar.position
	var tween = create_tween()
	tween.tween_property(btn_comprobar, "position:x", pos_original.x + 6.0, 0.04)
	tween.tween_property(btn_comprobar, "position:x", pos_original.x - 6.0, 0.04)
	tween.tween_property(btn_comprobar, "position:x", pos_original.x + 4.0, 0.04)
	tween.tween_property(btn_comprobar, "position:x", pos_original.x, 0.04)
	
	tween.tween_interval(0.4)
	tween.chain().tween_callback(func():
		btn_comprobar.texture_normal = TEX_BTN_NORMAL
		btn_comprobar.texture_hover = TEX_BTN_NORMAL
		btn_comprobar.texture_pressed = TEX_BTN_DOWN
		bloqueado = false
	)

func _on_flecha_volver(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		_redirigir_sala()

func _redirigir_sala() -> void:
	if GestorEstadoNivelBryan.cilindros_resuelto and GestorEstadoNivelBryan.laser_resuelto:
		get_tree().change_scene_to_file("res://Nivel_Bryan/sala_3.tscn")
	elif GestorEstadoNivelBryan.cilindros_resuelto:
		get_tree().change_scene_to_file("res://Nivel_Bryan/sala_2.tscn")
	else:
		get_tree().change_scene_to_file("res://Nivel_Bryan/sala_1.tscn")
