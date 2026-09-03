extends Node2D

# --- TEXTURAS PEDESTAL ---
const TEX_CON_HOJA = preload("res://Assets/PedestalHoja.png")
const TEX_QUEMADA  = preload("res://Assets/PedestalIncendiada.png")
const TEX_VACIO    = preload("res://Assets/PedestalVacio.png")

# --- TEXTURAS INCISOS ---
const TEX_INCISOS = [
	preload("res://Assets/Inciso_A.png"),
	preload("res://Assets/Inciso_B.png"),
	preload("res://Assets/Inciso_C.png")
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

const RADIO_LENTE: float = 68.0
const LETRAS: Array[String] = ["A)", "B)", "C)"]

func _ready() -> void:
	laser_entrada.visible = false
	laser_salida.visible = false
	
	slots_fijos = [hoja1.global_position, hoja2.global_position, hoja3.global_position]
	
	if GameManager.laser_resuelto:
		_restaurar_estado_resuelto()
	else:
		if GameManager.laser_datos_activos.is_empty():
			_cargar_trivia_laser_json()
		else:
			_aplicar_datos_trivia(GameManager.laser_datos_activos, false)
			
		boton_disparar.input_event.connect(_on_boton_disparar_input)
		boton_disparar.mouse_entered.connect(func(): if not bloqueado: Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
		boton_disparar.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))
	
	if has_node("Flecha/Area2D"):
		var area_flecha = $Flecha/Area2D
		area_flecha.input_event.connect(_on_flecha_input)
		area_flecha.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
		area_flecha.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))

func _restaurar_estado_resuelto() -> void:
	bloqueado = true
	boton_disparar.input_pickable = false
	
	for lente in $Contenedor_piezas.get_children():
		if lente.has_node("CollisionShape2D"):
			lente.get_node("CollisionShape2D").disabled = true
	
	if GameManager.laser_lente_ganador != "":
		var lente_ganador = $Contenedor_piezas.get_node_or_null(GameManager.laser_lente_ganador)
		if lente_ganador:
			lente_ganador.global_position = slot_central.global_position
			lente_actual = lente_ganador
	
	var pedestales = [hoja1, hoja2, hoja3]
	var sprites_incisos = [sprite_inciso_1, sprite_inciso_2, sprite_inciso_3]
	
	for i in range(pedestales.size()):
		if i < GameManager.laser_posiciones_hojas.size():
			pedestales[i].global_position = GameManager.laser_posiciones_hojas[i]
		if i < GameManager.laser_texturas_hojas.size():
			pedestales[i].texture = GameManager.laser_texturas_hojas[i]
		if i < GameManager.laser_incisos_guardados.size() and sprites_incisos[i] != null:
			var idx_tex = GameManager.laser_incisos_guardados[i]
			if idx_tex >= 0 and idx_tex < TEX_INCISOS.size():
				sprites_incisos[i].texture = TEX_INCISOS[idx_tex]
				sprites_incisos[i].visible = (pedestales[i].texture != TEX_VACIO)
	
	if label_pregunta and GameManager.laser_pregunta_guardada != "":
		label_pregunta.text = GameManager.laser_pregunta_guardada

func _cargar_trivia_laser_json() -> void:
	var path = "res://acertijos.json"
	if not FileAccess.file_exists(path):
		_fallback_pregunta_local()
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fallback_pregunta_local()
		return
		
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_str)
	if error != OK or not (json.data is Dictionary):
		_fallback_pregunta_local()
		return
	
	var data: Dictionary = {}
	
	if json.data.has("laser_puzzles") and json.data["laser_puzzles"] is Array:
		var lista: Array = json.data["laser_puzzles"]
		if not lista.is_empty():
			data = lista[randi() % lista.size()]
	elif json.data.has("laser_puzzle") and json.data["laser_puzzle"] is Dictionary:
		data = json.data["laser_puzzle"]
	
	if data.is_empty():
		_fallback_pregunta_local()
		return
	
	GameManager.laser_datos_activos = data
	_aplicar_datos_trivia(data, true)

func _fallback_pregunta_local() -> void:
	var fallback_data = {
		"pregunta": "¿QUÉ COMPONENTE ÓPTICO SE UTILIZA PARA DESVIAR O REFRACTAR EL HAZ DE LUZ?",
		"opciones": [
			{ "texto": "LENTE CONVERGENTE", "correcta": true },
			{ "texto": "ESPEJO CÓNCAVO", "correcta": false },
			{ "texto": "FILTRO POLARIZADO", "correcta": false }
		]
	}
	GameManager.laser_datos_activos = fallback_data
	_aplicar_datos_trivia(fallback_data, true)

func _aplicar_datos_trivia(data: Dictionary, mezclar: bool = true) -> void:
	var pregunta: String = str(data.get("pregunta", "¿QUÉ COMPONENTE SE UTILIZA?"))
	var opciones: Array = data.get("opciones", []).duplicate()
	
	if mezclar:
		opciones.shuffle()
		data["opciones"] = opciones
	
	var texto_pergamino = pregunta + "\n\n"
	var pedestales = [hoja1, hoja2, hoja3]
	var sprites_incisos = [sprite_inciso_1, sprite_inciso_2, sprite_inciso_3]
	
	GameManager.laser_incisos_guardados = []
	
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
			
			GameManager.laser_incisos_guardados.append(i)
			
			if opciones[i].get("correcta", false):
				hoja_ganadora = pedestales[i]
				GameManager.laser_idx_ganador = i
	
	if label_pregunta:
		label_pregunta.text = texto_pergamino
		GameManager.laser_pregunta_guardada = texto_pergamino

func intentar_encajar_lente(pieza: Node, _dir_num: int) -> bool:
	if bloqueado or GameManager.laser_resuelto:
		return false
	
	var dist = pieza.global_position.distance_to(slot_central.global_position)
	if dist < 160.0:
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
	if bloqueado or GameManager.laser_resuelto or lente_actual == null:
		return
	
	bloqueado = true
	
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
	
	var sprite_hijo = hoja.get_node_or_null("TextoInciso")
	if sprite_hijo:
		var tween_texto = create_tween()
		tween_texto.tween_property(sprite_hijo, "modulate:a", 0.0, 0.3)
		
	var tween_color = create_tween()
	tween_color.tween_property(hoja, "modulate", Color(1, 1, 1, 1), 0.4)
	
	if es_correcta:
		GameManager.laser_resuelto = true
		GameManager.laser_lente_ganador = String(lente_actual.name) if lente_actual != null else ""
		GameManager.laser_posiciones_hojas = [hoja1.global_position, hoja2.global_position, hoja3.global_position]
		GameManager.laser_texturas_hojas = [hoja1.texture, hoja2.texture, hoja3.texture]
		
		var timer_exito = get_tree().create_timer(1.2)
		timer_exito.timeout.connect(func():
			_apagar_lasers()
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			get_tree().change_scene_to_file("res://sala_3.tscn")
		)
	else:
		var timer_fallo = get_tree().create_timer(0.6)
		timer_fallo.timeout.connect(func():
			_apagar_lasers()
			hoja.texture = TEX_VACIO
			_expulsar_lente_actual()
			_revolver_posiciones()
		)

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
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		if GameManager.laser_resuelto:
			get_tree().change_scene_to_file("res://sala_3.tscn")
		else:
			get_tree().change_scene_to_file("res://sala_2.tscn")
