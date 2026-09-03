extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# --- 1. ESTADO DEL ESCRITORIO ---
	if GestorEstadoNivelE.bote_tirado:
		$BoteTirado.show()
		$BoteNormal.hide()
	else:
		$BoteNormal.show()
		$BoteTirado.hide()

	if GestorEstadoNivelE.puerta_abierta:
		$PuertaAbierta.show()
		$PuertaCerrada.hide()
	else:
		$PuertaCerrada.show()
		$PuertaAbierta.hide()
		
	# Variable para el tamaño original de la cadena (cámbialo si tu cadena en el editor no mide 0)
	var tamano_cadena_original = 0 
	
	# --- 2. LÓGICA DE LA GARRA Y LA CADENA ---
	if GestorEstadoNivelE.computadora_resuelta:
		if not GestorEstadoNivelE.animacion_garra_vista:
			# PRIMERA VEZ: Animación de bajar
			GestorEstadoNivelE.animacion_garra_vista = true
			
			var tween = create_tween()
			tween.tween_property($Garra, "position:y", 750, 2.5).set_trans(Tween.TRANS_SINE)
			tween.parallel().tween_property($Cadena, "size:y", 750, 2.5)
			
			tween.chain().tween_callback(func(): TransicionGlobal.cambiar_escena("res://Nivel_E/Zoom_Garra.tscn"))
			
		elif not GestorEstadoNivelE.foso_resuelto:
			# VOLVIÓ DEL FOSO PERO NO HA GANADO: 
			# Mantenemos la concordancia visual (La garra está abajo, solo se ve la cadena tensa)
			$Garra.hide()
			$Cadena.size.y = 1116 # Mantiene la cadena estirada hacia el pozo
	
	# --- 3. VERIFICACIÓN DE VICTORIA FINAL ---
	if GestorEstadoNivelE.foso_resuelto:
		$Garra.hide() # Nos aseguramos de ocultar la garra normal vacía
		
		if not GestorEstadoNivelE.animacion_victoria_vista:
			# Es la primera vez que entra tras ganar, reproducimos la cinemática
			GestorEstadoNivelE.animacion_victoria_vista = true
			
			var posicion_y_final_garra = 0 # Cámbialo si tu garra no termina en Y = 0
			
			# 1. Posicionamos la garra y la cadena en el fondo del pozo (estado inicial de la animación)
			$GarraCerrada.position.y = 750 
			$Cadena.size.y = 750
			
			$GarraCerrada.show()
			$PuertaAbiertaMain.hide() 
			
			# 2. Creamos la animación de subida (La garra sube y la cadena se encoge al mismo tiempo)
			var tween = create_tween().set_parallel(true)
			tween.tween_property($GarraCerrada, "position:y", posicion_y_final_garra, 2.0).set_trans(Tween.TRANS_SINE)
			tween.tween_property($Cadena, "size:y", tamano_cadena_original, 2.0).set_trans(Tween.TRANS_SINE)
			
			# 3. Al terminar de subir, abrimos la gran compuerta
			tween.chain().tween_callback(func():
				$PuertaAbiertaMain.show()
				print("¡Puerta abierta! Listo para el video final.")
			)
			
		else:
			# Si el jugador ya vio la animación y vuelve a cargar el Hub,
			# mostramos el estado estático final.
			$GarraCerrada.show()
			$PuertaAbiertaMain.show()
			
			# Restauramos tamaño para que la cadena se vea normal
			$Cadena.size.y = tamano_cadena_original 
			$GarraCerrada.position.y = 0 # O la posición final que hayas elegido

func _on_zona_puerta_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if GestorEstadoNivelE.foso_resuelto:
			# Si ya ganó, reproducimos el video de finalización (cambiamos a esa escena)
			TransicionGlobal.cambiar_escena("res://Nivel_E/Video_Final.tscn")
		else:
			# Si el jugador da clic antes de tiempo, podemos darle un mensaje o no hacer nada
			print("La pesada compuerta está sellada. Aún no puedes escapar.")

# Si el jugador da clic al pozo manualmente (haya resuelto o no la computadora)
func _on_zona_garra_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		TransicionGlobal.cambiar_escena("res://Nivel_E/Zoom_Garra.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_zona_escritorio_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		TransicionGlobal.cambiar_escena("res://Nivel_E/Zoom_Escritorio.tscn")
		#get_tree().change_scene_to_file("res://Nivel_E/Zoom_Escritorio.tscn")


func _on_zona_computadora_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		TransicionGlobal.cambiar_escena("res://Nivel_E/Zoom_Computadora.tscn")
		#get_tree().change_scene_to_file("res://Nivel_E/Zoom_Computadora.tscn")
