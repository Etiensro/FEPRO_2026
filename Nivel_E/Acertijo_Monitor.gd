extends Node2D
var respuesta_prueba: String = "primera guerra mundial"
var pregunta_prueba: String = "¿Qué conflicto bélico global, desarrollado entre 1914 y 1918, comenzó tras el asesinato del archiduque Francisco Fernando de Austria y enfrentó a los Aliados contra las Potencias Centrales?"
var cursor_encendido: bool = true

# --- VARIABLES DE TELEMETRÍA ---
var intentos_teclado: int = 0
var errores_jugador: Array = []
var aciertos_jugador: Array = []

var lista_preguntas: Array = []
var fallos_consecutivos: int = 0

func _ready() -> void:
	$Interfaz/ScrollContainer/TextoPantalla.text = "SISTEMA INICIADO...\nDescargando datos del servidor central..."
	$Interfaz/BarraCarga.value = 0
	$Interfaz/VisorRespuesta.hide()
	$Interfaz/CapturaTeclado.hide()
	$Interfaz/BotonConfirmar.hide()
	
	GestorTelemetria.preguntas_listas.connect(_on_preguntas_listas, CONNECT_ONE_SHOT)
	# 1. Apuntamos al bloque maestro de tu nivel
	GestorTelemetria.descargar_preguntas("nivel_1")

func _on_preguntas_listas(datos: Array) -> void:
	if datos.size() > 0:
		var datos_nivel = datos[0]
		# 2. Desempaquetamos tu escena
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

func cargar_nueva_pregunta():
	if lista_preguntas.size() > 0:
		lista_preguntas.shuffle()
		var puzzle_actual = lista_preguntas[0] 
		pregunta_prueba = puzzle_actual["pregunta_texto"]
		respuesta_prueba = puzzle_actual["respuesta_correcta"].to_lower()
		
		# Ajustar el input a la nueva palabra
		if has_node("Interfaz/CapturaTeclado"):
			var letras_totales = respuesta_prueba.replace(" ", "").length()
			$Interfaz/CapturaTeclado.max_length = letras_totales
			$Interfaz/CapturaTeclado.text = ""
			actualizar_visor("")

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
	
	intentos_teclado += 1
	
	if texto_jugador == respuesta_limpia:
		aciertos_jugador.append(texto_jugador)
		# 3. Enviamos los 3 parámetros unificados
		GestorTelemetria.enviar_reporte_final(intentos_teclado, aciertos_jugador, errores_jugador)
		
		GestorEstadoNivelE.computadora_resuelta = true
		await get_tree().create_timer(1.0).timeout
		$Interfaz/ScrollContainer/TextoPantalla.text = "✓"
		$Interfaz/ScrollContainer/TextoPantalla.add_theme_color_override("font_color", Color.GREEN)
		$Interfaz/ScrollContainer/TextoPantalla.add_theme_font_size_override("font_size",120)
		await get_tree().create_timer(1.0).timeout
		TransicionGlobal.cambiar_escena("res://Nivel_E/Hub_Principal.tscn")
	else:
		errores_jugador.append(texto_jugador)
		fallos_consecutivos += 1
		
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
		
		if fallos_consecutivos >= 3:
			fallos_consecutivos = 0
			cargar_nueva_pregunta()
		
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
	# Asegurarnos de que sea una tecla y que esté siendo presionada (no soltada)
	if event is InputEventKey and event.pressed:
		
		# 1. Si presiona Enter (teclado principal) o el Enter del teclado numérico
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			# Evitar que se envíe con el campo vacío
			if $Interfaz/CapturaTeclado.text.strip_edges().length() > 0:
				_on_boton_confirmar_pressed()
				get_viewport().set_input_as_handled()
				
		# 2. Bloqueamos las flechas direccionales y los botones de salto
		elif event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_HOME, KEY_END]:
			get_viewport().set_input_as_handled()


func _on_timer_timeout() -> void:
	cursor_encendido = !cursor_encendido
	actualizar_visor($Interfaz/CapturaTeclado.text)
