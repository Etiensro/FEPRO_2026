extends Area2D

@export var velocidad: float = 300.0

var cayendo: bool = false
var velocidad_y: float = 0.0

func _process(delta: float) -> void:
	if not cayendo:
		# La lanza se mueve hacia "arriba" en su propia dirección local
		var direccion_local = Vector2.UP.rotated(rotation)
		position += direccion_local * velocidad * delta
		
		# Si la flecha sube demasiado y no chocó con nada (falló)
		if global_position.y < 50:
			rebotar()
	else:
		# Lógica de caída libre
		velocidad_y += 1200.0 * delta # Gravedad
		position.y += velocidad_y * delta
		rotation += 3.0 * delta # Girar mientras cae
		
		if global_position.y > 1000: # Si sale de la pantalla por abajo, destruirla
			queue_free()

func rebotar() -> void:
	cayendo = true
	velocidad_y = -300.0
	print("¡Fallo! La lanza se pierde.")

func _on_area_entered(area: Area2D) -> void:
	# Verificamos si chocó contra una esfera
	if area.is_in_group("esferas_respuestas"):
		var id_golpeado = area.get_meta("id_esfera")
		print("Lanza golpeó a la esfera: ", id_golpeado)
		
		var fondo = get_tree().current_scene.get_node_or_null("FondoPrincipal")
		if not fondo:
			fondo = get_tree().current_scene
		
		if id_golpeado == GlobalEsferas.indice_correcto:
			print("¡RESPUESTA CORRECTA!")
			area.get_parent().self_modulate = Color(2.0, 2.0, 0.0, 1.0) # Brillo amarillo
			
			var texto_opcion = "Opción Correcta"
			if GlobalEsferas.opciones_cargadas.size() > id_golpeado:
				texto_opcion = str(GlobalEsferas.opciones_cargadas[id_golpeado])
			
			# REGISTRO GLOBAL: Acumula el acierto en GestorTelemetria sin subir a Firestore aún
			if get_tree().root.has_node("GestorTelemetria"):
				GestorTelemetria.registrar_respuesta("Nivel_Melyssa", true, texto_opcion)
			
			# Reproduce el sonido y el video de la puerta (la sala se encarga de cambiar de escena al terminar)
			if fondo and fondo.has_method("reproducir_acierto"):
				fondo.reproducir_acierto()
				
		else:
			print("¡Respuesta incorrecta!")
			if fondo and fondo.has_method("reproducir_error"):
				fondo.reproducir_error()
				
			area.get_parent().self_modulate = Color(1.0, 0.0, 0.0, 1.0) # Rojo (error)
			
			var texto_opcion = "Opción Incorrecta"
			if GlobalEsferas.opciones_cargadas.size() > id_golpeado:
				texto_opcion = str(GlobalEsferas.opciones_cargadas[id_golpeado])
				
			# REGISTRO GLOBAL: Acumula el error en GestorTelemetria
			if get_tree().root.has_node("GestorTelemetria"):
				GestorTelemetria.registrar_respuesta("Nivel_Melyssa", false, texto_opcion)
			
		# Destruimos la lanza al chocar
		queue_free()
