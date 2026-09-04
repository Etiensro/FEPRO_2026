extends Node2D

var respuesta_prueba: String = "primera guerra mundial"
var pregunta_prueba: String = "¿Qué conflicto bélico global, desarrollado entre 1914 y 1918, comenzó tras el asesinato del archiduque Francisco Fernando de Austria y enfrentó a los Aliados contra las Potencias Centrales?"
var cursor_encendido: bool = true

# --- VARIABLES DE CONTROL LOCAL ---
var intentos_teclado: int = 0
var errores_jugador: Array = []
var aciertos_jugador: Array = []

var lista_preguntas: Array = []
var fallos_consecutivos: int = 0
var bloqueado: bool = false

func _ready() -> void:
	var vidas_inicio = 3
	if get_tree().root.has_node("GestorVidas"):
		vidas_inicio = get_tree().root.get_node("GestorVidas").vidas
	print("\n========================================")
	print(" [COMPUTADORA HISTORIA INICIADA]")
	print(" Vidas disponibles del jugador: %d / 3" % vidas_inicio)
	print("========================================\n")

	$Interfaz/ScrollContainer/TextoPantalla.text = "SISTEMA INICIADO...\nDescargando datos del servidor central..."
	$Interfaz/BarraCarga.value = 0
	$Interfaz/VisorRespuesta.hide()
	$Interfaz/CapturaTeclado.hide()
	$Interfaz/BotonConfirmar.hide()
	
	if get_tree().root.has_node("GestorTelemetria"):
		GestorTelemetria.preguntas_listas.connect(_on_preguntas_listas, CONNECT_ONE_SHOT)
		GestorTelemetria.descargar_preguntas("nivel_1")
	else:
		_on_preguntas_listas([])

func _on_preguntas_listas(datos: Array) -> void:
	if datos.size() > 0:
		var datos_nivel = datos[0]
		if datos_nivel.has("escena_computadora"):
			lista_preguntas = datos_nivel["escena_computadora"]
			cargar_nueva_pregunta()
		else:
			pregunta_prueba = "Error: No se encontró la escena_computadora."
			respuesta_prueba = "error"
	else:
		pregunta_prueba = "Error: Base de datos vacía."
		respuesta_prueba = "error"
		
	var tween = create_tween()
	tween.tween_property($Interfaz/BarraCarga, "value", 100, 2.5)
	tween.tween_callback(mostrar_pregunta)

func cargar_nueva_pregunta() -> void:
	if lista_preguntas.size() > 0:
		# Filtra para evitar repetir la pregunta activa
		var candidatas = []
		for p in lista_preguntas:
			if p.get("pregunta_texto", "") != pregunta_prueba:
				candidatas.append(p)
				
		var puzzle_actual = {}
		if candidatas.size() > 0:
			candidatas.shuffle()
			puzzle_actual = candidatas[0]
		else:
			lista_preguntas.shuffle()
			puzzle_actual = lista_preguntas[0]
			
		pregunta_prueba = puzzle_actual["pregunta_texto"]
		respuesta_prueba = puzzle_actual["respuesta_correcta"].to_lower()
		
		if has_node("Interfaz/CapturaTeclado"):
			var letras_totales = respuesta_prueba.replace(" ", "").length()
			$Interfaz/CapturaTeclado.max_length = letras_totales
			$Interfaz/CapturaTeclado.text = ""
			actualizar_visor("")

func _process(_delta: float) -> void:
	pass

func mostrar_pregunta() -> void:
	$Interfaz/BarraCarga.hide()
	$Interfaz/ScrollContainer/TextoPantalla.text = pregunta_prueba
	$Interfaz/VisorRespuesta.show()
	$Interfaz/BotonConfirmar.show()
	
	var letras_totales = respuesta_prueba.replace(" ", "").length()
	$Interfaz/CapturaTeclado.max_length = letras_totales
	$Interfaz/CapturaTeclado.show()
	$Interfaz/CapturaTeclado.grab_focus()
	actualizar_visor("")

func actualizar_visor(texto_tecleado: String) -> void:
	var texto_final = ""
	var indice = 0
	var cursor_dibujado = false
	
	for caracter in respuesta_prueba:
		if caracter == " ":
			texto_final += "   "
		else:
			if indice < texto_tecleado.length():
				texto_final += texto_tecleado[indice].to_upper() + " "
				indice += 1
			else:
				if not cursor_dibujado:
					if cursor_encendido:
						texto_final += "| "
					else:
						texto_final += "_ "
					cursor_dibujado = true
				else:
					texto_final += "_ "
				
		$Interfaz/VisorRespuesta.text = texto_final

func _on_boton_confirmar_pressed() -> void:
	if bloqueado:
		return

	var texto_jugador = $Interfaz/CapturaTeclado.text.strip_edges().to_lower()
	var respuesta_limpia = respuesta_prueba.replace(" ", "").to_lower()
	
	intentos_teclado += 1
	
	if texto_jugador == respuesta_limpia:
		bloqueado = true
		fallos_consecutivos = 0
		aciertos_jugador.append(texto_jugador)
		
		# REGISTRO GLOBAL DE TELEMETRÍA
		if get_tree().root.has_node("GestorTelemetria"):
			GestorTelemetria.registrar_respuesta("Nivel_E", true, respuesta_prueba)
		
		# GESTIÓN DE VIDAS: Restablece vidas a 3 al superar el puzzle
		if get_tree().root.has_node("GestorVidas"):
			get_tree().root.get_node("GestorVidas").restablecer_a_tres()
			print("\n[¡ÉXITO COMPUTADORA!] Acertijo resuelto. Vidas restauradas a 3.\n")
		
		GestorEstadoNivelE.computadora_resuelta = true
		await get_tree().create_timer(1.0).timeout
		$Interfaz/ScrollContainer/TextoPantalla.text = "✓"
		$Interfaz/ScrollContainer/TextoPantalla.add_theme_color_override("font_color", Color.GREEN)
		$Interfaz/ScrollContainer/TextoPantalla.add_theme_font_size_override("font_size", 120)
		await get_tree().create_timer(1.0).timeout
		TransicionGlobal.cambiar_escena("res://Nivel_E/Hub_Principal.tscn")
	else:
		bloqueado = true
		errores_jugador.append(texto_jugador)
		fallos_consecutivos += 1
		
		# REGISTRO GLOBAL DE TELEMETRÍA
		if get_tree().root.has_node("GestorTelemetria"):
			GestorTelemetria.registrar_respuesta("Nivel_E", false, texto_jugador)
		
		# GESTIÓN DE VIDAS: Resta vida y activa banner superior
		var vidas_restantes = 0
		if get_tree().root.has_node("GestorVidas"):
			var gestor = get_tree().root.get_node("GestorVidas")
			gestor.restar_vida()
			vidas_restantes = gestor.vidas
		
		print("--------------------------------------------------")
		print(" [FALLO COMPUTADORA] Texto: '%s' | Esperado: '%s'" % [texto_jugador, respuesta_limpia])
		print(" Vidas restantes: %d / 3 | Errores en esta pregunta: %d" % [vidas_restantes, fallos_consecutivos])
		print("--------------------------------------------------")
		
		# 1. Bloqueo temporal y ocultación visual
		$Interfaz/VisorRespuesta.hide()
		$Interfaz/BotonConfirmar.hide()
		$Interfaz/CapturaTeclado.release_focus()
		
		# 2. Mensaje de error visual en pantalla
		$Interfaz/ScrollContainer/TextoPantalla.text = "Respuesta incorrecta"
		$Interfaz/ScrollContainer/TextoPantalla.add_theme_color_override("font_color", Color.RED)
		$Interfaz/ScrollContainer/TextoPantalla.add_theme_font_size_override("font_size", 90)
		
		await get_tree().create_timer(1.0).timeout
		
		# 3. Si se agotaron las vidas: fin de partida (GestorVidas envía a Menu.tscn)
		if vidas_restantes <= 0:
			$Interfaz/CapturaTeclado.editable = false
			return
			
		# 4. Si falló 2 veces seguidas: refresca la pregunta preservando su última vida
		if fallos_consecutivos >= 2:
			fallos_consecutivos = 0
			cargar_nueva_pregunta()
		
		# 5. Restauración de pantalla
		$Interfaz/ScrollContainer/TextoPantalla.text = pregunta_prueba
		$Interfaz/ScrollContainer/TextoPantalla.remove_theme_color_override("font_color")
		$Interfaz/ScrollContainer/TextoPantalla.add_theme_font_size_override("font_size", 43)
		
		# 6. Reactivación de entrada para el usuario
		$Interfaz/VisorRespuesta.show()
		$Interfaz/BotonConfirmar.show()
		$Interfaz/CapturaTeclado.text = ""
		actualizar_visor("")
		bloqueado = false
		$Interfaz/CapturaTeclado.grab_focus()

func _on_texture_button_pressed() -> void:
	if not bloqueado:
		TransicionGlobal.cambiar_escena("res://Nivel_E/Zoom_Computadora.tscn")

func _on_captura_teclado_text_changed(new_text: String) -> void:
	var texto_limpio = new_text.replace(" ", "")
	if texto_limpio != new_text:
		$Interfaz/CapturaTeclado.text = texto_limpio
		$Interfaz/CapturaTeclado.caret_column = texto_limpio.length()
		
	actualizar_visor(texto_limpio)

func _on_captura_teclado_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if $Interfaz/CapturaTeclado.text.strip_edges().length() > 0:
				_on_boton_confirmar_pressed()
				get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_HOME, KEY_END]:
			get_viewport().set_input_as_handled()

func _on_timer_timeout() -> void:
	cursor_encendido = !cursor_encendido
	actualizar_visor($Interfaz/CapturaTeclado.text)
