extends Node2D

func _ready() -> void:
	var contenedor_vidas = get_node_or_null("ContenedorVidas")
	if contenedor_vidas:
		# Mostrar solo las vidas restantes
		for i in range(contenedor_vidas.get_child_count()):
			if i < GlobalEsferas.intentos_restantes:
				contenedor_vidas.get_child(i).show()
			else:
				contenedor_vidas.get_child(i).hide()

func reproducir_acierto() -> void:
	# Buscamos el nodo de sonido (puede estar como hijo de FondoPrincipal o del Node2D raíz)
	var sonido = get_node_or_null("SonidoAcierto")
	if not sonido: sonido = get_tree().current_scene.get_node_or_null("SonidoAcierto")
	
	if sonido:
		sonido.play()
		
	print("¡VICTORIA! Reproduciendo video de la puerta...")
	
	# Buscamos el video
	var video = get_node_or_null("VideoPuerta")
	if not video: video = get_tree().current_scene.get_node_or_null("VideoPuerta")
	
	if video:
		video.show()
		video.play()
		# Conectamos para que salte al siguiente nivel al terminar de abrir la puerta
		if not video.finished.is_connected(_on_video_puerta_terminado):
			video.finished.connect(_on_video_puerta_terminado)

func _on_video_puerta_terminado():
	# Le pedimos al nuevo cerebro (GestorRutaJuego) a dónde ir
	var siguiente_nivel = GestorRutaJuego.obtener_siguiente_sala("res://Nivel_Melyssa/intro_esferas.tscn")
	if siguiente_nivel != "":
		get_tree().change_scene_to_file(siguiente_nivel)
	else:
		print("¡Juego terminado! Regresando al menú...")
		get_tree().change_scene_to_file("res://Menu_lvl/Menu.tscn")

func reproducir_error() -> void:
	var sonido = get_node_or_null("SonidoError")
	if not sonido: sonido = get_tree().current_scene.get_node_or_null("SonidoError")
	
	if sonido:
		sonido.play()
	print("Fallaste esta esfera.")

func mostrar_mensaje_reinicio() -> void:
	# Buscamos la plaquita en la escena
	var placa = get_tree().current_scene.get_node_or_null("PlacaMensaje")
	if placa:
		# Creamos una animación fluida (Tween)
		var tween = create_tween()
		
		# 1. Baja la placa hasta la posición Y = 150 en 1 segundo (con efecto rebote)
		tween.tween_property(placa, "position:y", 150, 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
		# 2. Espera 4 segundos para que el jugador lo lea, y luego la vuelve a subir (desaparece)
		tween.tween_property(placa, "position:y", -300, 1.0).set_delay(4.0).set_trans(Tween.TRANS_SINE)
	else:
		print("Falta crear el nodo PlacaMensaje en el editor.")

func _on_palanca_pressed() -> void:
	get_tree().change_scene_to_file("res://Nivel_Melyssa/escena_dos.tscn")

func _on_esfera_reloj_pressed() -> void:
	print("--- [CLIC] Esfera presionada ---")
	print("Estado pregunta_vista: ", GlobalEsferas.pregunta_vista)
	print("Opciones en memoria: ", GlobalEsferas.opciones_cargadas)
	
	if GlobalEsferas.pregunta_vista == true:
		GlobalEsferas.esferas_vistas[0] = true
		if GlobalEsferas.opciones_cargadas.size() > 0:
			# Usamos % limpio y el nombre correcto del nodo: TextoOpcion1
			%TextoOpcion1.text = str(GlobalEsferas.opciones_cargadas[0])
		else:
			%TextoOpcion1.text = "ERROR: JSON VACÍO"
			
		%ZoomEsfera1.show()
		%TextoOpcion1.show()


func _on_esfera_dos_pressed() -> void:

	if GlobalEsferas.pregunta_vista == true:
		GlobalEsferas.esferas_vistas[1] = true
		if GlobalEsferas.opciones_cargadas.size() > 1: # Chequeamos que exista más de una opción
			
			# Aquí cambiamos [0] por [1] para mostrar la segunda opción del JSON
			%TextoOpcion2.text = str(GlobalEsferas.opciones_cargadas[1]) 
			
		else:
			%TextoOpcion2.text = "ERROR: JSON VACÍO"
			
		# Y mostramos el Zoom 2
		%ZoomEsfera2.show()
		%TextoOpcion2.show()
	else:
		print("Acción bloqueada: Ve a la placa primero.")


func _on_esfera_tres_pressed() -> void:
	if GlobalEsferas.pregunta_vista == true:
		GlobalEsferas.esferas_vistas[2] = true
		if GlobalEsferas.opciones_cargadas.size() > 1: # Chequeamos que exista más de una opción
			
			# Aquí cambiamos [0] por [1] para mostrar la segunda opción del JSON
			%TextoOpcion3.text = str(GlobalEsferas.opciones_cargadas[2]) 
			
		else:
			%TextoOpcion3.text = "ERROR: JSON VACÍO"
			
		# Y mostramos el Zoom 2
		%ZoomEsfera3.show()
		%TextoOpcion3.show()
	else:
		print("Acción bloqueada: Ve a la placa primero.")


func _on_esfera_cuatro_pressed() -> void:
	if GlobalEsferas.pregunta_vista == true:
		GlobalEsferas.esferas_vistas[3] = true
		if GlobalEsferas.opciones_cargadas.size() > 1: # Chequeamos que exista más de una opción
			
			# Aquí cambiamos [0] por [1] para mostrar la segunda opción del JSON
			%TextoOpcion4.text = str(GlobalEsferas.opciones_cargadas[3]) 
			
		else:
			%TextoOpcion4.text = "ERROR: JSON VACÍO"
			
		# Y mostramos el Zoom 2
		%ZoomEsfera4.show()
		%TextoOpcion4.show()
	else:
		print("Acción bloqueada: Ve a la placa primero.")


#Botones flecha para volver despues de zoom
func _on_boton_cerrar_zoom_1_pressed() -> void:
	print("--- [CLIC] Botón cerrar presionado ---")
	%ZoomEsfera1.hide()


func _on_boton_cerrar_zoom_2_pressed() -> void:
	%ZoomEsfera2.hide()


func _on_boton_cerrar_zoom_3_pressed() -> void:
	%ZoomEsfera3.hide()


func _on_boton_cerrar_zoom_4_pressed() -> void:
	%ZoomEsfera4.hide()
