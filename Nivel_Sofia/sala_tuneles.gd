extends Node2D

@onready var pantalla_acertijo = $Escenario/PantallaAcertijo
@onready var letrero_izq = $Escenario/LetreroIzquierda
@onready var letrero_frente = $Escenario/LetreroFrente
@onready var letrero_der = $Escenario/LetreroDerecha

@onready var video_izq = $VideoIzquierda
@onready var video_frente = $VideoFrente
@onready var video_der = $VideoDerecha

var respuesta_correcta: String = ""
var pregunta_texto_actual: String = ""
var lista_preguntas_tuneles: Array = []
var fallos_consecutivos: int = 0
var ultimo_intento_correcto: bool = false
var bloqueado: bool = false

func _ready() -> void:
	configurar_estilo_textos()
	
	var vidas_inicio = 3
	if get_tree().root.has_node("GestorVidas"):
		vidas_inicio = get_tree().root.get_node("GestorVidas").vidas
	print("\n========================================")
	print(" [NIVEL SOFÍA: TÚNELES INICIADO]")
	print(" Vidas disponibles del jugador: %d / 3" % vidas_inicio)
	print("========================================\n")
	
	if video_izq: video_izq.visible = false
	if video_frente: video_frente.visible = false
	if video_der: video_der.visible = false
	
	if video_izq and not video_izq.finished.is_connected(_on_video_terminado):
		video_izq.finished.connect(_on_video_terminado)
	if video_frente and not video_frente.finished.is_connected(_on_video_terminado):
		video_frente.finished.connect(_on_video_terminado)
	if video_der and not video_der.finished.is_connected(_on_video_terminado):
		video_der.finished.connect(_on_video_terminado)
	
	cargar_json_tuneles()

func cargar_json_tuneles() -> void:
	if pantalla_acertijo: pantalla_acertijo.text = "Cargando datos desde la nube..."
	
	if get_tree().root.has_node("GestorTelemetria"):
		GestorTelemetria.preguntas_listas.connect(_on_preguntas_listas, CONNECT_ONE_SHOT)
		GestorTelemetria.descargar_preguntas("nivel_2")
	else:
		_cargar_respaldo_tuneles()

func _on_preguntas_listas(array_nivel: Array) -> void:
	if array_nivel.size() > 0:
		var datos_nivel = array_nivel[0]
		if datos_nivel.has("tuneles_fase"):
			lista_preguntas_tuneles = datos_nivel["tuneles_fase"]
			_seleccionar_nueva_pregunta_tuneles()
			return
		else:
			print("Aviso: Formato desconocido en tuneles_fase. Usando respaldo...")
	else:
		print("Aviso: No se recibieron preguntas para túneles. Usando respaldo...")
		
	_cargar_respaldo_tuneles()

func _seleccionar_nueva_pregunta_tuneles() -> void:
	if lista_preguntas_tuneles.size() > 0:
		var candidatas = []
		for p in lista_preguntas_tuneles:
			if p.get("pregunta", "") != pregunta_texto_actual:
				candidatas.append(p)
				
		var puzzle_actual = {}
		if candidatas.size() > 0:
			candidatas.shuffle()
			puzzle_actual = candidatas[0]
		else:
			lista_preguntas_tuneles.shuffle()
			puzzle_actual = lista_preguntas_tuneles[0]
			
		pregunta_texto_actual = puzzle_actual.get("pregunta", "")
		respuesta_correcta = puzzle_actual.get("correcta", "frente")
		if pantalla_acertijo: pantalla_acertijo.text = pregunta_texto_actual
		
		var opciones = puzzle_actual.get("opciones", {})
		if letrero_izq: letrero_izq.text = opciones.get("izquierda", "Túnel A")
		if letrero_frente: letrero_frente.text = opciones.get("frente", "Túnel B")
		if letrero_der: letrero_der.text = opciones.get("derecha", "Túnel C")
	else:
		_cargar_respaldo_tuneles()

func _cargar_respaldo_tuneles() -> void:
	pregunta_texto_actual = "¿Qué compuerta lógica produce un 1 lógico únicamente cuando todas sus entradas son 1?"
	respuesta_correcta = "frente"
	if pantalla_acertijo: pantalla_acertijo.text = pregunta_texto_actual
	if letrero_izq: letrero_izq.text = "OR"
	if letrero_frente: letrero_frente.text = "AND"
	if letrero_der: letrero_der.text = "XOR"

func configurar_estilo_textos() -> void:
	if letrero_izq:
		letrero_izq.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letrero_izq.add_theme_font_size_override("normal_font_size", 32)
	if letrero_frente:
		letrero_frente.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letrero_frente.add_theme_font_size_override("normal_font_size", 32)
	if letrero_der:
		letrero_der.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letrero_der.add_theme_font_size_override("normal_font_size", 32)
	if pantalla_acertijo:
		pantalla_acertijo.add_theme_font_size_override("normal_font_size", 28)

func _on_boton_izquierda_pressed() -> void:
	procesar_eleccion("izquierda")

func _on_boton_frente_pressed() -> void:
	procesar_eleccion("frente")

func _on_boton_derecha_pressed() -> void:
	procesar_eleccion("derecha")

func procesar_eleccion(eleccion: String) -> void:
	if bloqueado:
		return
	bloqueado = true
	
	print("El jugador eligió: ", eleccion)
	
	if has_node("Escenario/BotonIzquierda"): $Escenario/BotonIzquierda.disabled = true
	if has_node("Escenario/BotonFrente"): $Escenario/BotonFrente.disabled = true
	if has_node("Escenario/BotonDerecha"): $Escenario/BotonDerecha.disabled = true
	
	var texto_elegido = eleccion
	if eleccion == "izquierda" and letrero_izq: texto_elegido = letrero_izq.text
	elif eleccion == "frente" and letrero_frente: texto_elegido = letrero_frente.text
	elif eleccion == "derecha" and letrero_der: texto_elegido = letrero_der.text
	
	ultimo_intento_correcto = (eleccion == respuesta_correcta)
	
	# REGISTRO GLOBAL TELEMETRÍA
	if get_tree().root.has_node("GestorTelemetria"):
		GestorTelemetria.registrar_respuesta("Nivel_Sofia", ultimo_intento_correcto, texto_elegido)
	
	if ultimo_intento_correcto:
		fallos_consecutivos = 0
		print("Resultado: ¡CORRECTO!")
		if typeof(Global) != TYPE_NIL and "suma_niveles" in Global:
			Global.suma_niveles += 1
	else:
		fallos_consecutivos += 1
		print("Resultado: ¡INCORRECTO! Túnel erróneo.")
		
		# GESTIÓN GLOBAL DE VIDAS
		if get_tree().root.has_node("GestorVidas"):
			get_tree().root.get_node("GestorVidas").restar_vida()
	
	# Reproducción del video correspondiente
	var video_reproducido: VideoStreamPlayer = null
	if eleccion == "izquierda" and video_izq:
		video_reproducido = video_izq
	elif eleccion == "frente" and video_frente:
		video_reproducido = video_frente
	elif eleccion == "derecha" and video_der:
		video_reproducido = video_der
		
	if video_reproducido:
		video_reproducido.size = get_viewport_rect().size
		video_reproducido.visible = true
		video_reproducido.play()
	else:
		_on_video_terminado()

func _on_video_terminado() -> void:
	# Ocultar todos los videos de túnel
	if video_izq: video_izq.visible = false
	if video_frente: video_frente.visible = false
	if video_der: video_der.visible = false

	# SI FUE ACIERTO: Se restauran vidas a 3 y se avanza a la siguiente sala
	if ultimo_intento_correcto:
		if get_tree().root.has_node("GestorVidas"):
			get_tree().root.get_node("GestorVidas").restablecer_a_tres()
			print("\n[¡ÉXITO TÚNELES!] Camino superado. Vidas restauradas a 3.\n")
		
		var siguiente_destino = GestorRutaJuego.obtener_siguiente_sala("res://Nivel_Sofia/nivel_carrito.tscn")
		print("Siguiente destino en la ruleta: ", siguiente_destino)
		
		if siguiente_destino != "":
			get_tree().change_scene_to_file(siguiente_destino)
		else:
			print("¡Todas las salas concluidas! Subiendo telemetría final a Firestore...")
			if get_tree().root.has_node("GestorTelemetria"):
				GestorTelemetria.enviar_reporte_acumulado("victoria")
			get_tree().change_scene_to_file("res://Menu_lvl/Menu.tscn")
		return

	# SI FUE ERROR: Comprobar vidas restantes
	var vidas_actuales = 0
	if get_tree().root.has_node("GestorVidas"):
		vidas_actuales = get_tree().root.get_node("GestorVidas").vidas
	
	# Derrota total: permanece bloqueado; GestorVidas redirigirá a Menu.tscn
	if vidas_actuales <= 0:
		return
		
	# Si van 2 fallos consecutivos: rota pregunta preservando la última vida
	if fallos_consecutivos >= 2:
		fallos_consecutivos = 0
		_seleccionar_nueva_pregunta_tuneles()
		
	# Reactivar botones para reintentar el túnel
	if has_node("Escenario/BotonIzquierda"): $Escenario/BotonIzquierda.disabled = false
	if has_node("Escenario/BotonFrente"): $Escenario/BotonFrente.disabled = false
	if has_node("Escenario/BotonDerecha"): $Escenario/BotonDerecha.disabled = false
	bloqueado = false
