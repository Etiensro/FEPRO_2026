extends Node2D

@onready var pantalla_acertijo = $Escenario/PantallaAcertijo
@onready var letrero_izq = $Escenario/LetreroIzquierda
@onready var letrero_frente = $Escenario/LetreroFrente
@onready var letrero_der = $Escenario/LetreroDerecha

@onready var video_izq = $VideoIzquierda
@onready var video_frente = $VideoFrente
@onready var video_der = $VideoDerecha

var respuesta_correcta = ""

func _ready():
	configurar_estilo_textos()
	
	# Ocultamos los videos al iniciar
	if video_izq: video_izq.visible = false
	if video_frente: video_frente.visible = false
	if video_der: video_der.visible = false
	
	# Conectamos las señales de fin de video
	if video_izq: video_izq.finished.connect(_on_video_terminado)
	if video_frente: video_frente.finished.connect(_on_video_terminado)
	if video_der: video_der.finished.connect(_on_video_terminado)
	
	cargar_json_tuneles()

func cargar_json_tuneles():
	if pantalla_acertijo: pantalla_acertijo.text = "Cargando datos desde la nube..."
	# Conectarnos a la señal maestra
	GestorTelemetria.preguntas_listas.connect(_on_preguntas_listas, CONNECT_ONE_SHOT)
	# Pedir la etiqueta de Sofia
	GestorTelemetria.descargar_preguntas("tuneles_fase")

func _on_preguntas_listas(array_preguntas: Array) -> void:
	if array_preguntas.size() > 0:
		# Elegir pregunta aleatoria
		array_preguntas.shuffle()
		var puzzle_actual = array_preguntas[0]
		
		respuesta_correcta = puzzle_actual["correcta"]
		if pantalla_acertijo: pantalla_acertijo.text = puzzle_actual["pregunta"]
		if letrero_izq: letrero_izq.text = puzzle_actual["opciones"]["izquierda"]
		if letrero_frente: letrero_frente.text = puzzle_actual["opciones"]["frente"]
		if letrero_der: letrero_der.text = puzzle_actual["opciones"]["derecha"]
	else:
		if pantalla_acertijo: pantalla_acertijo.text = "Error al descargar preguntas de internet"

func configurar_estilo_textos():
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

func _on_boton_izquierda_pressed():
	procesar_eleccion("izquierda")

func _on_boton_frente_pressed():
	procesar_eleccion("frente")

func _on_boton_derecha_pressed():
	procesar_eleccion("derecha")

func procesar_eleccion(eleccion):
	print("El jugador eligió: ", eleccion)
	
	# Desactivar botones
	if has_node("Escenario/BotonIzquierda"): $Escenario/BotonIzquierda.disabled = true
	if has_node("Escenario/BotonFrente"): $Escenario/BotonFrente.disabled = true
	if has_node("Escenario/BotonDerecha"): $Escenario/BotonDerecha.disabled = true
	
	# Reproducir video elegido
	if eleccion == "izquierda" and video_izq:
		video_izq.size = get_viewport_rect().size
		video_izq.visible = true
		video_izq.play()
	elif eleccion == "frente" and video_frente:
		video_frente.size = get_viewport_rect().size
		video_frente.visible = true
		video_frente.play()
	elif eleccion == "derecha" and video_der:
		video_der.size = get_viewport_rect().size
		video_der.visible = true
		video_der.play()
		
	var texto_elegido = ""
	if eleccion == "izquierda" and letrero_izq: texto_elegido = letrero_izq.text
	elif eleccion == "frente" and letrero_frente: texto_elegido = letrero_frente.text
	elif eleccion == "derecha" and letrero_der: texto_elegido = letrero_der.text
	
	if eleccion == respuesta_correcta:
		print("Resultado: ¡CORRECTO!")
		Global.suma_niveles += 1
		GestorTelemetria.enviar_reporte_final("jugador_sofia_tuneles", "victoria", 1, [texto_elegido], [])
	else:
		print("Resultado: ¡INCORRECTO!")
		Global.intentos_restantes -= 1
		GestorTelemetria.enviar_reporte_final("jugador_sofia_tuneles", "derrota", 1, [], [texto_elegido])

func _on_video_terminado():
	print("El video del túnel ha finalizado. Saltando a la siguiente sala...")
	
	# Llamado al gestor global para avanzar en el tour aleatorio sin repetición
	var siguiente_destino = GestorRutaJuego.obtener_siguiente_sala()
	print("Siguiente destino en la ruleta: ", siguiente_destino)
	
	get_tree().change_scene_to_file(siguiente_destino)
