extends Node

# --- CONFIGURACIÓN DE ESCENAS ---
const ESCENA_GAME_OVER: String = "res://game_over.tscn"
const ESCENA_MENU: String = "res://Menu_lvl/Menu.tscn"

const VIDAS_MAXIMAS: int = 3
var vidas: int = VIDAS_MAXIMAS

signal vidas_cambiadas(vidas_actuales: int)
signal partida_perdida()

# --- NODOS DE VENTANA EMERGENTE SUPERIOR ---
var capa_ui: CanvasLayer
var panel_emergente: PanelContainer
var label_vidas: Label
var tween_banner: Tween

# Símbolos visuales de corazones
const CORAZON_LLENO: String = "♥"
const CORAZON_VACIO: String = "♡"

# Tiempos de permanencia en pantalla (segundos)
const TIEMPO_ALERTA: float = 4.0
const TIEMPO_DERROTA: float = 2.5

var procesando_fin_juego: bool = false

func _ready() -> void:
	_crear_ui_emergente()
	print("\n========================================")
	print("   [GESTOR VIDAS INICIALIZADO]")
	print("   Estado inicial: VIDAS: %s %s %s" % [CORAZON_LLENO, CORAZON_LLENO, CORAZON_LLENO])
	print("========================================\n")
	vidas = VIDAS_MAXIMAS
	procesando_fin_juego = false

func _crear_ui_emergente() -> void:
	# Capa superior para mantenerse siempre visible
	capa_ui = CanvasLayer.new()
	capa_ui.layer = 120
	add_child(capa_ui)
	
	panel_emergente = PanelContainer.new()
	panel_emergente.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel_emergente.offset_left = 120
	panel_emergente.offset_right = -120
	panel_emergente.offset_top = -140
	panel_emergente.offset_bottom = -20
	panel_emergente.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Estilo tipo ventana emergente/pergamino oscuro
	var estilo_caja = StyleBoxFlat.new()
	estilo_caja.bg_color = Color(0.1, 0.08, 0.08, 0.94)
	estilo_caja.border_color = Color(0.85, 0.3, 0.25, 0.95)
	estilo_caja.set_border_width_all(3)
	estilo_caja.set_corner_radius_all(10)
	estilo_caja.content_margin_top = 16
	estilo_caja.content_margin_bottom = 16
	estilo_caja.content_margin_left = 24
	estilo_caja.content_margin_right = 24
	panel_emergente.add_theme_stylebox_override("panel", estilo_caja)
	
	label_vidas = Label.new()
	label_vidas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_vidas.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_vidas.add_theme_font_size_override("font_size", 26)
	label_vidas.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9, 1.0))
	label_vidas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_vidas.text = ""
	
	panel_emergente.add_child(label_vidas)
	capa_ui.add_child(panel_emergente)
	panel_emergente.modulate.a = 0.0

func _obtener_texto_corazones() -> String:
	var texto_corazones = ""
	for i in range(VIDAS_MAXIMAS):
		if i < vidas:
			texto_corazones += CORAZON_LLENO + " "
		else:
			texto_corazones += CORAZON_VACIO + " "
	return texto_corazones.strip_edges()

# Llamar al superar un puzzle o iniciar una sala nueva
func restablecer_a_tres() -> void:
	vidas = VIDAS_MAXIMAS
	procesando_fin_juego = false
	vidas_cambiadas.emit(vidas)
	ocultar_emergente_inmediato()
	
	var corazones = _obtener_texto_corazones()
	print("\n>>> [SALA / RETO SUPERADO] <<<")
	print("--> VIDAS: %s\n" % corazones)

# Llamar cada vez que el jugador falla un intento
func restar_vida() -> void:
	if procesando_fin_juego:
		return
		
	var vidas_previas: int = vidas
	vidas = max(vidas - 1, 0)
	vidas_cambiadas.emit(vidas)
	
	var corazones = _obtener_texto_corazones()
	
	print("\n----------------------------------------")
	print(" [!] ERROR COMETIDO")
	print(" Vidas antes del fallo: ", vidas_previas)
	print(" VIDAS: ", corazones)
	print("----------------------------------------\n")
	
	if vidas == 2:
		var mensaje = "VIDAS: %s" % corazones
		mostrar_ventana_emergente(mensaje, TIEMPO_ALERTA)
	elif vidas == 1:
		var mensaje = "VIDAS: %s - ATENCIÓN: REFRESCANDO NIVEL" % corazones
		mostrar_ventana_emergente(mensaje, TIEMPO_ALERTA)
	elif vidas <= 0:
		procesando_fin_juego = true
		var mensaje = "VIDAS: %s - ¡PARTIDA TERMINADA!" % corazones
		mostrar_ventana_emergente(mensaje, TIEMPO_DERROTA)
		print("========================================")
		print("       [GAME OVER: 0 VIDAS RESTANTES]")
		print("========================================\n")
		partida_perdida.emit()
		_procesar_derrota()

func mostrar_ventana_emergente(texto: String, duracion: float) -> void:
	if not label_vidas or not panel_emergente:
		return
		
	label_vidas.text = texto
	
	if tween_banner and tween_banner.is_running():
		tween_banner.kill()
		
	tween_banner = create_tween()
	panel_emergente.offset_top = -120
	panel_emergente.offset_bottom = -20
	panel_emergente.modulate.a = 0.0
	
	# Entrada descendente suave con rebote
	tween_banner.set_parallel(true)
	tween_banner.tween_property(panel_emergente, "offset_top", 30.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_banner.tween_property(panel_emergente, "offset_bottom", 105.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_banner.tween_property(panel_emergente, "modulate:a", 1.0, 0.2)
	
	# Pausa para lectura
	tween_banner.chain().tween_interval(duracion)
	
	# Salida desvaneciéndose hacia arriba (solo si el juego no ha terminado)
	if not procesando_fin_juego:
		tween_banner.chain().set_parallel(true)
		tween_banner.tween_property(panel_emergente, "offset_top", -120.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween_banner.tween_property(panel_emergente, "offset_bottom", -20.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween_banner.tween_property(panel_emergente, "modulate:a", 0.0, 0.3)

func ocultar_emergente_inmediato() -> void:
	if tween_banner and tween_banner.is_running():
		tween_banner.kill()
	if panel_emergente:
		panel_emergente.modulate.a = 0.0
		panel_emergente.offset_top = -140
		panel_emergente.offset_bottom = -20

func _procesar_derrota() -> void:
	print("--- [GESTOR VIDAS] Subiendo reporte consolidado de derrota a Firestore ---")
	if get_tree().root.has_node("GestorTelemetria"):
		GestorTelemetria.enviar_reporte_acumulado("derrota")
	
	# Limpieza de estados guardados del nivel para evitar bloqueos en partidas futuras
	if typeof(GestorEstadoNivelBryan) != TYPE_NIL:
		GestorEstadoNivelBryan.laser_resuelto = false
		GestorEstadoNivelBryan.laser_datos_activos = {}
		GestorEstadoNivelBryan.cilindros_resuelto = false
	
	# Espera el tiempo de visualización del cartel antes de lanzar el video
	var timer = get_tree().create_timer(TIEMPO_DERROTA)
	timer.timeout.connect(func():
		ocultar_emergente_inmediato()
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		
		# Comprobar si existe la escena del video de Game Over
		if ResourceLoader.exists(ESCENA_GAME_OVER):
			print("--- [GESTOR VIDAS] Lanzando cinemática de Game Over: ", ESCENA_GAME_OVER)
			get_tree().change_scene_to_file(ESCENA_GAME_OVER)
		else:
			print("--- [GESTOR VIDAS] No se encontró game_over.tscn. Enviando a menú: ", ESCENA_MENU)
			get_tree().change_scene_to_file(ESCENA_MENU)
	)
