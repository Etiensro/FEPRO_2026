extends Node2D

# --- FONDOS Y VIDEO DE ENTRADA ---
const VIDEO_TRANSICION = preload("res://Nivel_Bryan/Assets/Zoom_Cil.ogv")
const FONDO_SALA_1 = preload("res://Nivel_Bryan/Imagenes_Back/Sala_1.jpg")

const ESCENA_RODILLO = preload("res://Nivel_Bryan/Cilindro.tscn")

# --- TEXTURAS BOTÓN COMPROBAR ---
const TEX_BTN_NORMAL = preload("res://Nivel_Bryan/Assets/Boton_Up_Atlas.tres")
const TEX_BTN_DOWN   = preload("res://Nivel_Bryan/Assets/Boton_Down_Atlas.tres")
const TEX_BTN_ERROR  = preload("res://Nivel_Bryan/Assets/Boton_Rojo_Atlas.tres")
const TEX_BTN_EXITO  = preload("res://Nivel_Bryan/Assets/Boton_Verde_Atlas.tres")

const ALFABETO = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
const CARACTERES_ESPECIALES = ["(", ")", ",", ".", "?", "¿", "+", "-", "x"]
const NUMEROS = ["0","1","2","3","4","5","6","7","8","9","+","-","x",".",","]
const ALFANUMERICO = [
	"0","1","2","3","4","5","6","7","8","9",
	"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"(", ")", ",", ".", "?", "¿", "+", "-", "x"
]

@onready var contenedor: HBoxContainer = $ContCilindros
@onready var label_pregunta: Label = $LabelPregunta
@onready var btn_comprobar: TextureButton = ($BtnComprobar if has_node("BtnComprobar") else ($BtnComprobador if has_node("BtnComprobador") else null))

var lista_rodillos: Array = []
var clave_correcta: String = ""
var datos_acertijos: Dictionary = {}
var bloqueado: bool = false
var indice_escritura: int = 0

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
		_reproducir_video_transicion()
			
		if get_tree().root.has_node("GestorTelemetria"):
			GestorTelemetria.preguntas_listas.connect(_on_preguntas_listas, CONNECT_ONE_SHOT)
			var clave_elegida = "tema_1" if randf() > 0.5 else "tema_2"
			GestorEstadoNivelBryan.cilindros_id_actual = clave_elegida
			GestorTelemetria.descargar_preguntas("nivel_3")
		else:
			_fallback_local()

func _reproducir_video_transicion() -> void:
	bloqueado = true
	
	var capa_video = CanvasLayer.new()
	capa_video.layer = 100
	add_child(capa_video)
	
	var fondo_respaldo = TextureRect.new()
	fondo_respaldo.texture = FONDO_SALA_1
	fondo_respaldo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo_respaldo.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_video.add_child(fondo_respaldo)
	
	var player = VideoStreamPlayer.new()
	player.stream = VIDEO_TRANSICION
	player.expand = true
	player.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_video.add_child(player)
	
	var finalizar_video = func():
		if is_instance_valid(capa_video):
			capa_video.queue_free()
		bloqueado = false
		if TransicionGlobal.has_method("mostrar_subtitulo"):
			TransicionGlobal.mostrar_subtitulo("Quizá si encuentro la combinación...", 4.0)

	player.finished.connect(finalizar_video)
	player.play()

func _input(event: InputEvent) -> void:
	if bloqueado or GestorEstadoNivelBryan.cilindros_resuelto or lista_rodillos.is_empty():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			
			if btn_comprobar and not btn_comprobar.disabled:
				btn_comprobar.texture_normal = TEX_BTN_DOWN
				var t = create_tween()
				t.tween_interval(0.12)
				t.chain().tween_callback(func():
					if not bloqueado:
						btn_comprobar.texture_normal = TEX_BTN_NORMAL
					_on_btn_comprobar_pressed()
				)
			else:
				_on_btn_comprobar_pressed()
			return

		var total_rodillos = lista_rodillos.size()

		if event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
			indice_escritura = (indice_escritura - 1 + total_rodillos) % total_rodillos
			var rodillo_borrar = lista_rodillos[indice_escritura]
			if is_instance_valid(rodillo_borrar) and rodillo_borrar.has_method("asignar_valor"):
				var simbolo_vacio = rodillo_borrar.opciones[0] if not rodillo_borrar.opciones.is_empty() else "0"
				rodillo_borrar.asignar_valor(simbolo_vacio)
			get_viewport().set_input_as_handled()
			return

		var char_pulsado = ""
		if event.unicode > 0:
			char_pulsado = char(event.unicode).to_upper()
		elif event.keycode != KEY_NONE:
			char_pulsado = OS.get_keycode_string(event.keycode).to_upper()

		if char_pulsado.length() == 1:
			var rodillo_actual = lista_rodillos[indice_escritura]
			if is_instance_valid(rodillo_actual) and rodillo_actual.has_method("asignar_valor"):
				var exito = rodillo_actual.asignar_valor(char_pulsado)
				if exito:
					indice_escritura = (indice_escritura + 1) % total_rodillos
					get_viewport().set_input_as_handled()

func _on_preguntas_listas(datos_recibidos) -> void:
	if datos_recibidos is Array and datos_recibidos.size() > 0:
		var datos_nivel = datos_recibidos[0]
		var clave_actual = GestorEstadoNivelBryan.cilindros_id_actual
		
		if datos_nivel.has(clave_actual):
			var info_acertijo = datos_nivel[clave_actual]
			GestorEstadoNivelBryan.cilindros_pregunta_guardada = str(info_acertijo.get("pregunta", ""))
			GestorEstadoNivelBryan.cilindros_tipo_guardado = str(info_acertijo.get("tipo", "numeros"))
			
			if label_pregunta:
				label_pregunta.text = GestorEstadoNivelBryan.cilindros_pregunta_guardada
			
			var objetivo = str(info_acertijo.get("objetivo", "")).to_upper().strip_edges()
			generar_cilindros_multiples(objetivo, GestorEstadoNivelBryan.cilindros_tipo_guardado)
		else:
			_fallback_local()
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
	indice_escritura = 0

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
	elif tipo == "mixto" or tipo == "completo":
		conjunto = ALFANUMERICO
	elif tipo == "especiales":
		conjunto = CARACTERES_ESPECIALES

	for i in range(num_letras):
		var nuevo_rodillo = ESCENA_RODILLO.instantiate()
		contenedor.add_child(nuevo_rodillo)
		
		if num_letras >= 5:
			nuevo_rodillo.scale = Vector2(0.85, 0.85)
		else:
			nuevo_rodillo.scale = Vector2(1.0, 1.0)
			
		var valor_inicial = conjunto[0]
		if nuevo_rodillo.has_method("configurar"):
			nuevo_rodillo.configurar(conjunto, valor_inicial)
		lista_rodillos.append(nuevo_rodillo)

func _restaurar_estado_resuelto() -> void:
	bloqueado = true
	
	if TransicionGlobal.has_method("ocultar_subtitulo"):
		TransicionGlobal.ocultar_subtitulo()
	
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
	var tiene_especiales = false
	for c in letras:
		var c_str = str(c).to_upper()
		if c_str in CARACTERES_ESPECIALES:
			tiene_especiales = true
		elif c_str in ALFABETO and not c_str in NUMEROS:
			tiene_letras = true
	
	var conjunto = NUMEROS
	if tiene_especiales and tiene_letras:
		conjunto = ALFANUMERICO
	elif tiene_letras:
		conjunto = ALFABETO
	elif tiene_especiales:
		conjunto = ALFANUMERICO

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
	
	var respuesta_jugador: String = ""
	for rodillo in lista_rodillos:
		if is_instance_valid(rodillo) and rodillo.has_method("obtener_valor"):
			respuesta_jugador += str(rodillo.obtener_valor()).strip_edges().to_upper()
	
	if respuesta_jugador == clave_correcta:
		_efecto_acierto()
	else:
		# REGISTRO GLOBAL: Guarda solo el valor literal ingresado por el jugador (ej: "000")
		if get_tree().root.has_node("GestorTelemetria"):
			GestorTelemetria.registrar_respuesta("Nivel_Bryan", false, respuesta_jugador)
		_efecto_error()

func _efecto_acierto() -> void:
	bloqueado = true
	
	if TransicionGlobal.has_method("ocultar_subtitulo"):
		TransicionGlobal.ocultar_subtitulo()
		
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
	
	# REGISTRO GLOBAL: Guarda solo el valor literal de la clave correcta (ej: "100")
	if get_tree().root.has_node("GestorTelemetria"):
		GestorTelemetria.registrar_respuesta("Nivel_Bryan", true, clave_correcta)
	
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.chain().tween_callback(func():
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		_redirigir_sala()
	)

func _efecto_error() -> void:
	bloqueado = true

	if TransicionGlobal.has_method("ocultar_subtitulo"):
		TransicionGlobal.ocultar_subtitulo()

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
		indice_escritura = 0
	)

func _on_flecha_volver(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if TransicionGlobal.has_method("ocultar_subtitulo"):
			TransicionGlobal.ocultar_subtitulo()
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		_redirigir_sala()

func _redirigir_sala() -> void:
	if GestorEstadoNivelBryan.cilindros_resuelto and GestorEstadoNivelBryan.laser_resuelto:
		get_tree().change_scene_to_file("res://Nivel_Bryan/sala_3.tscn")
	elif GestorEstadoNivelBryan.cilindros_resuelto:
		get_tree().change_scene_to_file("res://Nivel_Bryan/sala_2.tscn")
	else:
		get_tree().change_scene_to_file("res://Nivel_Bryan/sala_1.tscn")
