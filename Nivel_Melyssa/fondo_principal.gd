extends Node2D

func _ready() -> void:
	# Monitoreo y sincronización inicial de vidas
	var vidas_inicio = 3
	if get_tree().root.has_node("GestorVidas"):
		var gestor = get_tree().root.get_node("GestorVidas")
		vidas_inicio = gestor.vidas
		# Escuchar cambios globales de vidas para actualizar los iconos locales
		if not gestor.vidas_cambiadas.is_connected(_actualizar_iconos_vidas):
			gestor.vidas_cambiadas.connect(_actualizar_iconos_vidas)
			
	print("\n========================================")
	print(" [SALA ESFERAS (MELYSSA) INICIADA]")
	print(" Vidas disponibles del jugador: %d / 3" % vidas_inicio)
	print("========================================\n")

	_configurar_contenedor_vidas(vidas_inicio)
				
	# Mostrar pista inicial si aún no ven la pregunta
	if not GlobalEsferas.pregunta_vista:
		mostrar_subtitulo_superior("¿Qué pasará si presiono esa palanca?", 4.0)
		
	# Mostrar segunda pista si ya vieron la pregunta pero aún no revisan las esferas
	elif GlobalEsferas.pregunta_vista and GlobalEsferas.esferas_vistas.has(false):
		mostrar_subtitulo_superior("Tal vez si revisas todas las esferas podrías desbloquear el cañón...", 5.0)

func _configurar_contenedor_vidas(vidas_actuales: int) -> void:
	var contenedor_vidas = get_node_or_null("ContenedorVidas")
	if contenedor_vidas:
		var canvas_vidas = CanvasLayer.new()
		var texto_vidas = Label.new()
		texto_vidas.text = "Intentos:"
		texto_vidas.add_theme_font_size_override("font_size", 30)
		texto_vidas.add_theme_color_override("font_color", Color.WHITE)
		texto_vidas.add_theme_color_override("font_shadow_color", Color.BLACK)
		texto_vidas.position = Vector2(40, 30)
		canvas_vidas.add_child(texto_vidas)
		add_child(canvas_vidas)
		
		_actualizar_iconos_vidas(vidas_actuales)

func _actualizar_iconos_vidas(vidas_actuales: int) -> void:
	var contenedor_vidas = get_node_or_null("ContenedorVidas")
	if contenedor_vidas:
		for i in range(contenedor_vidas.get_child_count()):
			if i < vidas_actuales:
				contenedor_vidas.get_child(i).show()
			else:
				contenedor_vidas.get_child(i).hide()

func reproducir_acierto() -> void:
	var sonido = get_node_or_null("SonidoAcierto")
	if not sonido: sonido = get_tree().current_scene.get_node_or_null("SonidoAcierto")
	
	if sonido:
		sonido.play()
		
	print("¡VICTORIA! Reproduciendo video de la puerta...")
	
	var video = get_node_or_null("VideoPuerta")
	if not video: video = get_tree().current_scene.get_node_or_null("VideoPuerta")
	
	if video:
		video.show()
		video.play()
		if not video.finished.is_connected(_on_video_puerta_terminado):
			video.finished.connect(_on_video_puerta_terminado)
	else:
		_on_video_puerta_terminado()

func _on_video_puerta_terminado() -> void:
	# GESTIÓN GLOBAL DE VIDAS: Restaurar vidas a 3 al superar la sala completa
	if get_tree().root.has_node("GestorVidas"):
		get_tree().root.get_node("GestorVidas").restablecer_a_tres()
		print("\n[¡SALA COMPLETADA!] Vidas restauradas a 3 para el siguiente reto.\n")

	# Reiniciar el estado local del nivel de Melyssa
	GlobalEsferas.pregunta_vista = false
	GlobalEsferas.esferas_vistas = [false, false, false, false]
	GlobalEsferas.intentos_restantes = 3
	GlobalEsferas.opciones_cargadas.clear()
	GlobalEsferas.historial_aciertos.clear()
	GlobalEsferas.historial_errores.clear()
	GlobalEsferas.total_disparos = 0
	
	# Siguiente nivel en la rotación
	var siguiente_nivel = GestorRutaJuego.obtener_siguiente_sala("res://Nivel_Melyssa/intro_esferas.tscn")
	
	if siguiente_nivel != "":
		get_tree().change_scene_to_file(siguiente_nivel)
	else:
		print("¡Todas las salas concluidas! Subiendo telemetría final completa a Firestore...")
		if get_tree().root.has_node("GestorTelemetria"):
			GestorTelemetria.enviar_reporte_acumulado("victoria")
			
		get_tree().change_scene_to_file("res://Menu_lvl/Menu.tscn")

func reproducir_error() -> void:
	var sonido = get_node_or_null("SonidoError")
	if not sonido: sonido = get_tree().current_scene.get_node_or_null("SonidoError")
	
	if sonido:
		sonido.play()
	print("Fallaste esta esfera.")
	
	# GESTIÓN GLOBAL DE VIDAS: Restar vida y desplegar banner de corazones
	if get_tree().root.has_node("GestorVidas"):
		get_tree().root.get_node("GestorVidas").restar_vida()

func mostrar_mensaje_reinicio() -> void:
	var placa = get_tree().current_scene.get_node_or_null("PlacaMensaje")
	if placa:
		var tween = create_tween()
		tween.tween_property(placa, "position:y", 150, 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
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
			%TextoOpcion1.text = str(GlobalEsferas.opciones_cargadas[0])
		else:
			%TextoOpcion1.text = "ERROR: JSON VACÍO"
			
		%ZoomEsfera1.show()
		%TextoOpcion1.show()

func _on_esfera_dos_pressed() -> void:
	if GlobalEsferas.pregunta_vista == true:
		GlobalEsferas.esferas_vistas[1] = true
		if GlobalEsferas.opciones_cargadas.size() > 1:
			%TextoOpcion2.text = str(GlobalEsferas.opciones_cargadas[1])
		else:
			%TextoOpcion2.text = "ERROR: JSON VACÍO"
			
		%ZoomEsfera2.show()
		%TextoOpcion2.show()
	else:
		print("Acción bloqueada: Ve a la placa primero.")

func _on_esfera_tres_pressed() -> void:
	if GlobalEsferas.pregunta_vista == true:
		GlobalEsferas.esferas_vistas[2] = true
		if GlobalEsferas.opciones_cargadas.size() > 2:
			%TextoOpcion3.text = str(GlobalEsferas.opciones_cargadas[2])
		else:
			%TextoOpcion3.text = "ERROR: JSON VACÍO"
			
		%ZoomEsfera3.show()
		%TextoOpcion3.show()
	else:
		print("Acción bloqueada: Ve a la placa primero.")

func _on_esfera_cuatro_pressed() -> void:
	if GlobalEsferas.pregunta_vista == true:
		GlobalEsferas.esferas_vistas[3] = true
		if GlobalEsferas.opciones_cargadas.size() > 3:
			%TextoOpcion4.text = str(GlobalEsferas.opciones_cargadas[3])
		else:
			%TextoOpcion4.text = "ERROR: JSON VACÍO"
			
		%ZoomEsfera4.show()
		%TextoOpcion4.show()
	else:
		print("Acción bloqueada: Ve a la placa primero.")

func _on_boton_cerrar_zoom_1_pressed() -> void:
	%ZoomEsfera1.hide()

func _on_boton_cerrar_zoom_2_pressed() -> void:
	%ZoomEsfera2.hide()

func _on_boton_cerrar_zoom_3_pressed() -> void:
	%ZoomEsfera3.hide()

func _on_boton_cerrar_zoom_4_pressed() -> void:
	%ZoomEsfera4.hide()

func mostrar_subtitulo_superior(texto: String, duracion: float) -> void:
	var canvas = CanvasLayer.new()
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_top", 80)
	
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var estilo_panel = StyleBoxFlat.new()
	estilo_panel.bg_color = Color(0, 0, 0, 0.6)
	estilo_panel.corner_radius_top_left = 8
	estilo_panel.corner_radius_top_right = 8
	estilo_panel.corner_radius_bottom_left = 8
	estilo_panel.corner_radius_bottom_right = 8
	estilo_panel.content_margin_left = 20
	estilo_panel.content_margin_right = 20
	estilo_panel.content_margin_top = 10
	estilo_panel.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", estilo_panel)
	
	var pista = Label.new()
	pista.text = texto
	pista.add_theme_font_size_override("font_size", 24)
	pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pista.add_theme_color_override("font_shadow_color", Color.BLACK)
	pista.add_theme_constant_override("shadow_offset_x", 2)
	pista.add_theme_constant_override("shadow_offset_y", 2)
	
	panel.add_child(pista)
	margin.add_child(panel)
	canvas.add_child(margin)
	add_child(canvas)
	
	var t = get_tree().create_timer(duracion)
	t.timeout.connect(canvas.queue_free)
