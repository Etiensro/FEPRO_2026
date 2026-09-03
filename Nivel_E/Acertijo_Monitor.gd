extends Node2D
var respuesta_prueba: String = "primera guerra mundial"
var pregunta_prueba: String = "¿Qué conflicto bélico global, desarrollado entre 1914 y 1918, comenzó tras el asesinato del archiduque Francisco Fernando de Austria y enfrentó a los Aliados contra las Potencias Centrales?"
var cursor_encendido: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Interfaz/ScrollContainer/TextoPantalla.text = "SISTEMA INICIADO...\nDescargando datos del servidor central..."
	$Interfaz/BarraCarga.value = 0
	$Interfaz/VisorRespuesta.hide()
	$Interfaz/CapturaTeclado.hide()
	$Interfaz/BotonConfirmar.hide()
	
	# Conectarnos a la señal maestra
	GestorTelemetria.preguntas_listas.connect(_on_preguntas_listas, CONNECT_ONE_SHOT)
	GestorTelemetria.descargar_preguntas("escena_computadora")

func _on_preguntas_listas(datos: Array) -> void:
	if datos.size() > 0:
		datos.shuffle() # Elegimos una al azar de la lista
		var puzzle_actual = datos[0] 
		pregunta_prueba = puzzle_actual["pregunta_texto"]
		respuesta_prueba = puzzle_actual["respuesta_correcta"].to_lower()
	else:
		pregunta_prueba = "Error: No se encontró la escena_computadora en la base de datos."
		respuesta_prueba = "error"
		
	var tween = create_tween()
	# 2. Barra de carga
	tween.tween_property($Interfaz/BarraCarga, "value", 100, 2.5)
	tween.tween_callback(mostrar_pregunta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func mostrar_pregunta():
	$Interfaz/BarraCarga.hide()
	$Interfaz/ScrollContainer/TextoPantalla.text = pregunta_prueba
	$Interfaz/VisorRespuesta.show()
	$Interfaz/BotonConfirmar.show()
	# Restringir la longitud del input a la cantidad exacta de letras (ignorando espacios)
	var letras_totales = respuesta_prueba.replace(" ", "").length()
	$Interfaz/CapturaTeclado.max_length = letras_totales
	$Interfaz/CapturaTeclado.show()
	$Interfaz/CapturaTeclado.grab_focus()
	actualizar_visor("")

func actualizar_visor(texto_tecleado: String):
	var texto_final = ""
	var indice = 0
	var cursor_dibujado = false
	
	for caracter in respuesta_prueba:
		if caracter == " ":
			texto_final += "   " # Triple espacio visual para separar palabras
		else:
			if indice < texto_tecleado.length():
				texto_final += texto_tecleado[indice].to_upper() + " "
				indice += 1
			else:
				# Dibuja el cursor solo en el primer espacio vacío detectado
				if not cursor_dibujado:
					if cursor_encendido:
						texto_final += "| " 
					else:
						texto_final += "_ "
					cursor_dibujado = true
				else:
					texto_final += "_ "
				
		$Interfaz/VisorRespuesta.text = texto_final

func _on_boton_confirmar_pressed():
	var texto_jugador = $Interfaz/CapturaTeclado.text.strip_edges().to_lower()
	var respuesta_limpia = respuesta_prueba.replace(" ", "").to_lower()
	
	if texto_jugador == respuesta_limpia:
		GestorEstadoNivelE.computadora_resuelta = true
		await get_tree().create_timer(1.0).timeout
		$Interfaz/ScrollContainer/TextoPantalla.text = "✓"
		$Interfaz/ScrollContainer/TextoPantalla.add_theme_color_override("font_color", Color.GREEN)
		$Interfaz/ScrollContainer/TextoPantalla.add_theme_font_size_override("font_size",120)
		await get_tree().create_timer(1.0).timeout
		TransicionGlobal.cambiar_escena("res://Nivel_E/Hub_Principal.tscn")
	else:
		# 1. Bloqueamos el teclado y ocultamos la respuesta del jugador
		$Interfaz/VisorRespuesta.hide()
		$Interfaz/BotonConfirmar.hide()
		$Interfaz/CapturaTeclado.release_focus()
		
		# 2. Transformamos el texto principal a rojo y mostramos el error
		$Interfaz/ScrollContainer/TextoPantalla.text = "Respuesta incorrecta"
		$Interfaz/ScrollContainer/TextoPantalla.add_theme_color_override("font_color", Color.RED)
		$Interfaz/ScrollContainer/TextoPantalla.add_theme_font_size_override("font_size",90)
		
		# 3. Congelamos la función durante 1.0 segundo
		await get_tree().create_timer(1.0).timeout
		
		# 4. Restauramos la pregunta y eliminamos el color rojo
		$Interfaz/ScrollContainer/TextoPantalla.text = pregunta_prueba
		$Interfaz/ScrollContainer/TextoPantalla.remove_theme_color_override("font_color")
		$Interfaz/ScrollContainer/TextoPantalla.add_theme_font_size_override("font_size",43)
		
		# 5. Reactivamos toda la interfaz visual y mecánica
		$Interfaz/VisorRespuesta.show()
		$Interfaz/BotonConfirmar.show()
		$Interfaz/CapturaTeclado.text = ""
		actualizar_visor("")
		$Interfaz/CapturaTeclado.grab_focus()


func _on_texture_button_pressed() -> void:
	TransicionGlobal.cambiar_escena("res://Nivel_E/Zoom_Computadora.tscn")


func _on_captura_teclado_text_changed(new_text: String) -> void:
	# Eliminar espacios si el jugador intenta teclearlos por accidente
	var texto_limpio = new_text.replace(" ","")
	if texto_limpio != new_text:
		$Interfaz/CapturaTeclado.text = texto_limpio
		$Interfaz/CapturaTeclado.caret_column = texto_limpio.length()
		
	actualizar_visor(texto_limpio)


func _on_captura_teclado_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		# Bloqueamos las flechas direccionales y los botones de salto
		if event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_HOME, KEY_END]:
			get_viewport().set_input_as_handled()


func _on_timer_timeout() -> void:
	cursor_encendido = !cursor_encendido
	actualizar_visor($Interfaz/CapturaTeclado.text)
