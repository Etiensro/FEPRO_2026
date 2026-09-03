extends Node2D

const ESCENA_RODILLO = preload("res://Cilindro.tscn")

# --- LOS 4 ATLAS RECORTADOS EXACTOS ---
const TEX_BTN_NORMAL = preload("res://Assets/Boton_Up_Atlas.tres")
const TEX_BTN_DOWN   = preload("res://Assets/Boton_Down_Atlas.tres")
const TEX_BTN_ERROR  = preload("res://Assets/Boton_Rojo_Atlas.tres")
const TEX_BTN_EXITO  = preload("res://Assets/Boton_Verde_Atlas.tres")

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
	
	cargar_json("res://acertijos.json")
	
	if GameManager.cilindros_resuelto:
		_restaurar_estado_resuelto()
	else:
		# Si ya se eligió un acertijo anteriormente, mantenerlo fijo
		if GameManager.cilindros_id_actual != "" and datos_acertijos.has(GameManager.cilindros_id_actual):
			cargar_acertijo_desde_json(GameManager.cilindros_id_actual)
		else:
			cargar_acertijo_aleatorio()

func _restaurar_estado_resuelto() -> void:
	bloqueado = true
	
	if btn_comprobar:
		btn_comprobar.texture_normal = TEX_BTN_EXITO
		btn_comprobar.texture_hover = TEX_BTN_EXITO
		btn_comprobar.texture_pressed = TEX_BTN_EXITO
		btn_comprobar.disabled = true
		
	if label_pregunta:
		label_pregunta.text = GameManager.cilindros_pregunta_guardada if GameManager.cilindros_pregunta_guardada != "" else "¡CORRECTO! MECANISMO DESBLOQUEADO"
	
	for hijo in contenedor.get_children():
		hijo.free()
	lista_rodillos.clear()
	
	var letras = GameManager.cilindros_valores_guardados
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

func cargar_json(ruta_archivo: String) -> void:
	if not FileAccess.file_exists(ruta_archivo):
		return
	var archivo = FileAccess.open(ruta_archivo, FileAccess.READ)
	var contenido = archivo.get_as_text()
	archivo.close()
	
	var json = JSON.new()
	var error = json.parse(contenido)
	if error == OK and json.data is Dictionary:
		datos_acertijos = json.data

func cargar_acertijo_aleatorio() -> void:
	var claves_validas: Array = []
	for k in datos_acertijos.keys():
		if k != "laser_puzzle" and k != "laser_puzzles":
			claves_validas.append(k)
			
	if claves_validas.is_empty():
		return
		
	var indice_aleatorio: int = randi() % claves_validas.size()
	var id_seleccionado: String = claves_validas[indice_aleatorio]
	cargar_acertijo_desde_json(id_seleccionado)

func cargar_acertijo_desde_json(id_acertijo: String) -> void:
	if not datos_acertijos.has(id_acertijo):
		return
		
	var info = datos_acertijos[id_acertijo]
	var tipo = str(info.get("tipo", "numeros"))
	
	GameManager.cilindros_id_actual = id_acertijo
	GameManager.cilindros_pregunta_guardada = str(info.get("pregunta", ""))
	GameManager.cilindros_tipo_guardado = tipo
	
	if label_pregunta:
		label_pregunta.text = GameManager.cilindros_pregunta_guardada
	
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

func _on_btn_comprobar_pressed() -> void:
	if bloqueado or GameManager.cilindros_resuelto:
		return
	
	var respuesta_jugador: String = ""
	for rodillo in lista_rodillos:
		if is_instance_valid(rodillo) and rodillo.has_method("obtener_valor"):
			respuesta_jugador += str(rodillo.obtener_valor()).strip_edges().to_upper()
	
	if respuesta_jugador == clave_correcta:
		_efecto_acierto()
	else:
		_efecto_error()

func _efecto_acierto() -> void:
	bloqueado = true
	GameManager.cilindros_resuelto = true
	GameManager.cilindros_valores_guardados = []
	for r in lista_rodillos:
		if is_instance_valid(r) and r.has_method("obtener_valor"):
			GameManager.cilindros_valores_guardados.append(str(r.obtener_valor()).strip_edges().to_upper())
	
	if btn_comprobar:
		btn_comprobar.texture_normal = TEX_BTN_EXITO
		btn_comprobar.texture_pressed = TEX_BTN_EXITO
		btn_comprobar.texture_hover = TEX_BTN_EXITO
		btn_comprobar.disabled = true
	
	if label_pregunta:
		label_pregunta.text = "¡CORRECTO! MECANISMO DESBLOQUEADO"
	
	var tween = create_tween()
	tween.tween_interval(1.2)
	tween.chain().tween_callback(func():
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		_redirigir_sala()
	)

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

# Redirección coherente con el avance del juego
func _redirigir_sala() -> void:
	if GameManager.cilindros_resuelto and GameManager.laser_resuelto:
		get_tree().change_scene_to_file("res://sala_3.tscn")
	elif GameManager.cilindros_resuelto:
		get_tree().change_scene_to_file("res://sala_2.tscn")
	else:
		get_tree().change_scene_to_file("res://sala_1.tscn")
