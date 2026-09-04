extends Node2D

# --- VIDEO DE TRANSICIÓN ---
const VIDEO_TRANSICION = preload("res://Nivel_Bryan/Assets/Zoom_Lacer.ogv")

# --- TEXTURAS PEDESTAL ---
const TEX_CON_HOJA = preload("res://Nivel_Bryan/Assets/PedestalHoja.png")
const TEX_QUEMADA  = preload("res://Nivel_Bryan/Assets/PedestalIncendiada.png")
const TEX_VACIO    = preload("res://Nivel_Bryan/Assets/PedestalVacio.png")

# --- TEXTURAS INCISOS ---
const TEX_INCISOS = [
	preload("res://Nivel_Bryan/Assets/Inciso_A.png"),
	preload("res://Nivel_Bryan/Assets/Inciso_B.png"),
	preload("res://Nivel_Bryan/Assets/Inciso_C.png")
]

# --- REFERENCIAS A NODOS ---
@onready var slot_central: Area2D = $SlotCentral
@onready var boton_disparar: Area2D = $BotonDisparar
@onready var laser_entrada: Line2D = $LaserInt
@onready var laser_salida: Line2D = $LaserOut

@onready var p_emisor: Marker2D = $PuntoLasers/Emisor

# Pedestales
@onready var hoja1: Sprite2D = $Hojas/Hoja1
@onready var hoja2: Sprite2D = $Hojas/Hoja2
@onready var hoja3: Sprite2D = $Hojas/Hoja3

# Sprites hijos con las letras
@onready var sprite_inciso_1: Sprite2D = $Hojas/Hoja1/TextoInciso
@onready var sprite_inciso_2: Sprite2D = $Hojas/Hoja2/TextoInciso
@onready var sprite_inciso_3: Sprite2D = $Hojas/Hoja3/TextoInciso

# Pergamino
@onready var label_pregunta: Label = $Pregunta if has_node("Pregunta") else null

var lente_actual: Node = null
var bloqueado: bool = false

var slots_fijos: Array[Vector2] = []
var hoja_ganadora: Sprite2D = null

# Banco de preguntas descargadas
var lista_puzzles_disponibles: Array = []

# Telemetría y control de intentos
var intentos_totales: int = 0
var errores_cometidos: Array = []
var aciertos_logrados: Array = []

var intentos_pregunta_actual: int = 0
var respuestas_erroneas_pregunta_actual: Array = []

const RADIO_LENTE: float = 68.0
const LETRAS: Array[String] = ["A)", "B)", "C)"]

func _ready() -> void:
	laser_entrada.visible = false
	laser_salida.visible = false
	
	slots_fijos = [hoja1.global_position, hoja2.global_position, hoja3.global_position]
	
	if GestorEstadoNivelBryan.laser_resuelto:
		_restaurar_estado_resuelto()
	else:
		# Reproduce la animación de entrada antes de mostrar el puzzle
		_reproducir_video_transicion()
			
		if GestorEstadoNivelBryan.laser_datos_activos.is_empty():
			if get_tree().root.has_node("GestorTelemetria"):
				GestorTelemetria.preguntas_listas.connect(_on_preguntas_listas, CONNECT_ONE_SHOT)
				GestorTelemetria.descargar_preguntas("laser_puzzles")
			else:
				_fallback_local_laser()
		else:
			_aplicar_datos_trivia(GestorEstadoNivelBryan.laser_datos_activos, false)
			
		boton_disparar.input_event.connect(_on_boton_disparar_input)
		boton_disparar.mouse_entered.connect(func(): if not bloqueado: Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
		boton_disparar.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))
	
	if has_node("Flecha/Area2D"):
		var area_flecha = $Flecha/Area2D
		area_flecha.input_event.connect(_on_flecha_input)
		area_flecha.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
		area_flecha.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))

func _reproducir_video_transicion() -> void:
	bloqueado = true
	
	# Capa por encima de toda la escena para tapar el minijuego
	var capa_video = CanvasLayer.new()
	capa_video.layer = 100
	add_child(capa_video)
	
	var player = VideoStreamPlayer.new()
	player.stream = VIDEO_TRANSICION
	player.expand = true
	player.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa_video.add_child(player)
	
	var finalizar_video = func():
		if is_instance_valid(capa_video):
			capa_video.queue_free()
		bloqueado = false
		# Lanza la pista una vez que el video termina
		if TransicionGlobal.has_method("mostrar_subtitulo"):
			TransicionGlobal.mostrar_subtitulo("Hmmm quizas si pongo una de esas lentes que brilla sobre al soporte que saca chispas", 4.5)

	player.finished.connect(finalizar_video)
	player.play()

func _on_preguntas_listas(datos_recibidos) -> void:
	if datos_recibidos is Array and datos_recibidos.size() > 0:
		lista_puzzles_disponibles = datos_recibidos.duplicate()
		_seleccionar_nueva_pregunta()
	elif datos_recibidos is Dictionary and not datos_recibidos.is_empty():
		lista_puzzles_disponibles = [datos_recibidos]
		GestorEstadoNivelBryan.laser_datos_activos = datos_recibidos
		_aplicar_datos_trivia(datos_recibidos, true)
	else:
		_fallback_local_laser()

func _fallback_local_laser() -> void:
	var path = "res://Nivel_Bryan/acertijos.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
			if json.data.has("laser_puzzles") and not json.data["laser_puzzles"].is_empty():
				lista_puzzles_disponibles = json.data["laser_puzzles"].duplicate()
				_seleccionar_nueva_pregunta()
				return
				
	var fallback_data = {
		"pregunta": "¿QUÉ COMPONENTE ÓPTICO SE UTILIZA PARA DESVIAR O REFRACTAR EL HAZ DE LUZ?",
		"opciones": [
			{ "texto": "LENTE CONVERGENTE", "correcta": true },
			{ "texto": "ESPEJO CÓNCAVO", "correcta": false },
			{ "texto": "FILTRO POLARIZADO", "correcta": false }
		]
	}
	lista_puzzles_disponibles = [fallback_data]
	GestorEstadoNivelBryan.laser_datos_activos = fallback_data
	_aplicar_datos_trivia(fallback_data, true)

func _seleccionar_nueva_pregunta() -> void:
	if lista_puzzles_disponibles.is_empty():
		return
		
	intentos_pregunta_actual = 0
	respuestas_erroneas_pregunta_actual.clear()
	
	var candidatas: Array = []
	var pregunta_actual_texto = str(GestorEstadoNivelBryan.laser_datos_activos.get("pregunta", ""))
	
	for p in lista_puzzles_disponibles:
		if str(p.get("pregunta", "")) != pregunta_actual_texto:
			candidatas.append(p)
			
	var elegida = {}
	if not candidatas.is_empty():
		elegida = candidatas[randi() % candidatas.size()]
	else:
		elegida = lista_puzzles_disponibles[randi() % lista_puzzles_disponibles.size()]
		
	GestorEstadoNivelBryan.laser_datos_activos = elegida
	_aplicar_datos_trivia(elegida, true)

func _restaurar_estado_resuelto() -> void:
	bloqueado = true
	boton_disparar.input_pickable = false
	
	if TransicionGlobal.has_method("ocultar_subtitulo"):
		TransicionGlobal.ocultar_subtitulo()
	
	for lente in $Contenedor_piezas.get_children():
		if lente.has_node("CollisionShape2D"):
			lente.get_node("CollisionShape2D").disabled = true
	
	if GestorEstadoNivelBryan.laser_lente_ganador != "":
		var lente_ganador = $Contenedor_piezas.get_node_or_null(GestorEstadoNivelBryan.laser_lente_ganador)
		if lente_ganador:
			lente_ganador.global_position = slot_central.global_position
			lente_actual = lente_ganador
	
	var pedestales = [hoja1, hoja2, hoja3]
	var sprites_incisos = [sprite_inciso_1, sprite_inciso_2, sprite_inciso_3]
	
	for i in range(pedestales.size()):
		if i < GestorEstadoNivelBryan.laser_posiciones_hojas.size():
			pedestales[i].global_position = GestorEstadoNivelBryan.laser_posiciones_hojas[i]
		if i < GestorEstadoNivelBryan.laser_texturas_hojas.size():
			pedestales[i].texture = GestorEstadoNivelBryan.laser_texturas_hojas[i]
		if i < GestorEstadoNivelBryan.laser_incisos_guardados.size() and sprites_incisos[i] != null:
			var idx_tex = GestorEstadoNivelBryan.laser_incisos_guardados[i]
			if idx_tex >= 0 and idx_tex < TEX_INCISOS.size():
				sprites_incisos[i].texture = TEX_INCISOS[idx_tex]
				sprites_incisos[i].visible = (pedestales[i].texture != TEX_VACIO)
	
	if label_pregunta and GestorEstadoNivelBryan.laser_pregunta_guardada != "":
		label_pregunta.text = GestorEstadoNivelBryan.laser_pregunta_guardada

func _aplicar_datos_trivia(data: Dictionary, mezclar: bool = true) -> void:
	var pregunta: String = str(data.get("pregunta", "¿QUÉ COMPONENTE SE UTILIZA?"))
	var opciones: Array = data.get("opciones", []).duplicate()
	
	if mezclar:
		opciones.shuffle()
		data["opciones"] = opciones
	
	var texto_pergamino = pregunta + "\n\n"
	var pedestales = [hoja1, hoja2, hoja3]
	var sprites_incisos = [sprite_inciso_1, sprite_inciso_2, sprite_inciso_3]
	
	GestorEstadoNivelBryan.laser_incisos_guardados = []
	
	for i in range(pedestales.size()):
		pedestales[i].texture = TEX_CON_HOJA
		pedestales[i].modulate = Color(1, 1, 1, 1)
		
		if i < opciones.size():
			var letra = LETRAS[i]
			var texto_opcion = str(opciones[i].get("texto", ""))
			texto_pergamino += letra + " " + texto_opcion + "\n"
			
			if sprites_incisos[i] != null:
				sprites_incisos[i].texture = TEX_INCISOS[i]
				sprites_incisos[i].modulate.a = 1.0
				sprites_incisos[i].visible = true
			
			pedestales[i].set_meta("texto_opcion", texto_opcion)
			GestorEstadoNivelBryan.laser_incisos_guardados.append(i)
			
			if opciones[i].get("correcta", false):
				hoja_ganadora = pedestales[i]
				GestorEstadoNivelBryan.laser_idx_ganador = i
	
	if label_pregunta:
		label_pregunta.text = texto_pergamino
		GestorEstadoNivelBryan.laser_pregunta_guardada = texto_pergamino

func intentar_encajar_lente(pieza: Node, _dir_num: int) -> bool:
	if bloqueado or GestorEstadoNivelBryan.laser_resuelto:
		return false
	
	var dist = pieza.global_position.distance_to(slot_central.global_position)
	if dist < 160.0:
		if TransicionGlobal.has_method("ocultar_subtitulo"):
			TransicionGlobal.ocultar_subtitulo()
			
		if lente_actual != null and lente_actual != pieza:
			lente_actual.resetear_posicion()
		
		lente_actual = pieza
		
		var tween = create_tween()
		tween.tween_property(pieza, "global_position", slot_central.global_position, 0.1)
		
		_apagar_lasers()
		return true
	
	if lente_actual == pieza:
		lente_actual = null
		_apagar_lasers()
		
	return false

func _on_boton_disparar_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		ejecutar_disparo()

func ejecutar_disparo() -> void:
	if bloqueado or GestorEstadoNivelBryan.laser_resuelto or lente_actual == null:
		return
	
	if TransicionGlobal.has_method("ocultar_subtitulo"):
		TransicionGlobal.ocultar_subtitulo()
	
	bloqueado = true
	intentos_totales += 1
	intentos_pregunta_actual += 1
	
	var idx_slot: int = 1
	var nombre_lente = String(lente_actual.name)
	
	if "1" in nombre_lente:
		idx_slot = 0
	elif "2" in nombre_lente:
		idx_slot = 1
	elif "3" in nombre_lente:
		idx_slot = 2
		
	var destino_pos: Vector2 = slots_fijos[idx_slot]
	_dibujar_y_procesar_laser(destino_pos)

func _dibujar_y_procesar_laser(destino_final: Vector2) -> void:
	var centro = slot_central.global_position
	var punto_emisor = p_emisor.global_position
	var punto_toque_lente = centro + Vector2(-RADIO_LENTE, 0)
	
	laser_entrada.clear_points()
	laser_entrada.add_point(punto_emisor)
	laser_entrada.add_point(punto_toque_lente)
	laser_entrada.visible = true
	
	var dir_salida = (destino_final - centro).normalized()
	var salida_borde = centro + (dir_salida * RADIO_LENTE)
	
	laser_salida.clear_points()
	laser_salida.add_point(salida_borde)
	laser_salida.add_point(destino_final)
	laser_salida.visible = true
	
	var tween_laser = create_tween().set_loops(3)
	laser_entrada.modulate.a = 0.4
	laser_salida.modulate.a = 0.4
	tween_laser.tween_property(laser_entrada, "modulate:a", 1.0, 0.08)
	tween_laser.parallel().tween_property(laser_salida, "modulate:a", 1.0, 0.08)
	tween_laser.tween_property(laser_entrada, "modulate:a", 0.4, 0.08)
	tween_laser.parallel().tween_property(laser_salida, "modulate:a", 0.4, 0.08)
	
	var hoja_impactada: Sprite2D = _obtener_hoja_en_posicion(destino_final)
	
	if hoja_impactada != null and hoja_impactada.texture == TEX_CON_HOJA:
		var es_acierto = (hoja_impactada == hoja_ganadora)
		_procesar_impacto(hoja_impactada, es_acierto)
	else:
		var timer = get_tree().create_timer(0.6)
		timer.timeout.connect(func():
			_apagar_lasers()
			_expulsar_lente_actual()
			bloqueado = false
		)

func _procesar_impacto(hoja: Sprite2D, es_correcta: bool) -> void:
	hoja.texture = TEX_QUEMADA
	hoja.modulate = Color(1.3, 0.6, 0.2, 1.0)
	
	var txt_opcion = str(hoja.get_meta("texto_opcion")) if hoja.has_meta("texto_opcion") else "Opción"
	var texto_pregunta = GestorEstadoNivelBryan.laser_datos_activos.get("pregunta", "Pregunta Láser")
	
	var sprite_hijo = hoja.get_node_or_null("TextoInciso")
	if sprite_hijo:
		var tween_texto = create_tween()
		tween_texto.tween_property(sprite_hijo, "modulate:a", 0.0, 0.3)
		
	var tween_color = create_tween()
	tween_color.tween_property(hoja, "modulate", Color(1, 1, 1, 1), 0.4)
	
	if es_correcta:
		if not respuestas_erroneas_pregunta_actual.is_empty():
			var num_fallos = respuestas_erroneas_pregunta_actual.size()
			var palabra_vez = "vez" if num_fallos == 1 else "veces"
			var lista_errs_txt = ", ".join(respuestas_erroneas_pregunta_actual)
			var reg_err = "Falló %d %s con: [%s] (Pregunta: %s)" % [num_fallos, palabra_vez, lista_errs_txt, texto_pregunta]
			# errores_cometidos.append(str(reg_err)) # Ya lo agregamos como palabra suelta arriba

		var registro_acierto = txt_opcion
		aciertos_logrados.append(str(registro_acierto))
		
		GestorEstadoNivelBryan.laser_resuelto = true
		GestorEstadoNivelBryan.laser_lente_ganador = String(lente_actual.name) if lente_actual != null else ""
		GestorEstadoNivelBryan.laser_posiciones_hojas = [hoja1.global_position, hoja2.global_position, hoja3.global_position]
		GestorEstadoNivelBryan.laser_texturas_hojas = [hoja1.texture, hoja2.texture, hoja3.texture]
		
		var hora_actual = Time.get_time_string_from_system().replace(":", "-")
		var nombre_doc = "Juego_Laser_" + hora_actual
		
		# Obtener nombre real del menú
		var nombre_jugador = "jugador_bryan"
		if "alumno_id" in GestorTelemetria:
			if typeof(GestorTelemetria.get("alumno_id")) == TYPE_STRING and not GestorTelemetria.get("alumno_id").is_empty():
				nombre_jugador = GestorTelemetria.get("alumno_id")
		
		_enviar_a_firestore_con_nombre(
			nombre_doc,
			nombre_jugador,
			"victoria",
			intentos_totales,
			aciertos_logrados,
			errores_cometidos
		)
		
		var timer_exito = get_tree().create_timer(1.5)
		timer_exito.timeout.connect(func():
			_apagar_lasers()
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			get_tree().change_scene_to_file("res://Nivel_Bryan/sala_3.tscn")
		)
	else:
		respuestas_erroneas_pregunta_actual.append(txt_opcion)
		errores_cometidos.append(txt_opcion)
		
		if respuestas_erroneas_pregunta_actual.size() >= 2:
			var lista_errs_txt = ", ".join(respuestas_erroneas_pregunta_actual)
			var registro_error = "Falló 2 veces con: [%s] (Pregunta: %s)" % [lista_errs_txt, texto_pregunta]
			errores_cometidos.append(str(registro_error))
			
			var timer_refresh = get_tree().create_timer(0.8)
			timer_refresh.timeout.connect(func():
				_apagar_lasers()
				_expulsar_lente_actual()
				_seleccionar_nueva_pregunta()
				bloqueado = false
			)
		else:
			var timer_fallo = get_tree().create_timer(0.6)
			timer_fallo.timeout.connect(func():
				_apagar_lasers()
				hoja.texture = TEX_VACIO
				_expulsar_lente_actual()
				_revolver_posiciones()
			)

func _enviar_a_firestore_con_nombre(id_documento: String, alumno: String, estado: String, disparos: int, aciertos: Array, errores: Array) -> void:
	var http_custom = HTTPRequest.new()
	add_child(http_custom)
	
	http_custom.request_completed.connect(func(_result, code, _headers, _body):
		if code == 200:
			print("¡Documento de Láser creado con éxito! ID: ", id_documento)
		else:
			print("Error al guardar reporte de Láser: ", code)
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

func _revolver_posiciones() -> void:
	var lista_hojas: Array[Sprite2D] = [hoja1, hoja2, hoja3]
	
	var pos_actuales: Array[Vector2] = []
	for h in lista_hojas:
		pos_actuales.append(h.global_position)
	
	var shift: int = 1 if randf() > 0.5 else 2
	var nuevas_posiciones: Array[Vector2] = []
	
	for i in range(lista_hojas.size()):
		var nuevo_idx = (i + shift) % lista_hojas.size()
		nuevas_posiciones.append(pos_actuales[nuevo_idx])
	
	var tween_shuffle = create_tween().set_parallel(true)
	for i in range(lista_hojas.size()):
		tween_shuffle.tween_property(lista_hojas[i], "global_position", nuevas_posiciones[i], 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween_shuffle.chain().tween_callback(func():
		bloqueado = false
	)

func _expulsar_lente_actual() -> void:
	if lente_actual != null and lente_actual.has_method("resetear_posicion"):
		lente_actual.resetear_posicion()
	lente_actual = null

func _obtener_hoja_en_posicion(pos: Vector2) -> Sprite2D:
	for h in [hoja1, hoja2, hoja3]:
		if h.global_position.distance_to(pos) < 60.0:
			return h
	return null

func _apagar_lasers() -> void:
	laser_entrada.visible = false
	laser_salida.visible = false

func _on_flecha_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if TransicionGlobal.has_method("ocultar_subtitulo"):
			TransicionGlobal.ocultar_subtitulo()
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		if GestorEstadoNivelBryan.laser_resuelto:
			get_tree().change_scene_to_file("res://Nivel_Bryan/sala_3.tscn")
		else:
			get_tree().change_scene_to_file("res://Nivel_Bryan/sala_2.tscn")
