extends Area2D

@export var velocidad: float = 300.0

var cayendo = false
var velocidad_y = 0.0

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
		velocidad_y += 1200 * delta # Gravedad
		position.y += velocidad_y * delta
		rotation += 3 * delta # Girar mientras cae
		
		if global_position.y > 1000: # Si sale de la pantalla por abajo, destruirla
			queue_free()

func rebotar() -> void:
	cayendo = true
	velocidad_y = -300 # Un pequeño rebote hacia arriba antes de caer
	print("¡Fallo! La lanza se pierde.")

func _on_area_entered(area: Area2D) -> void:
	# Verificamos si chocó contra una esfera
	if area.is_in_group("esferas_respuestas"):
		# Obtenemos el ID de la esfera golpeada
		var id_golpeado = area.get_meta("id_esfera")
		
		print("Lanza golpeó a la esfera: ", id_golpeado)
		
		var fondo = get_tree().current_scene.get_node_or_null("FondoPrincipal")
		
		if id_golpeado == GlobalEsferas.indice_correcto:
			print("¡RESPUESTA CORRECTA!")
			if fondo: fondo.reproducir_acierto()
			# Aquí iluminamos la esfera
			area.get_parent().self_modulate = Color(2.0, 2.0, 0.0, 1.0) # Brillo amarillo
			
			# Guardar estadística de acierto pedagógico
			if GlobalEsferas.opciones_cargadas.size() > id_golpeado:
				var texto_opcion = GlobalEsferas.opciones_cargadas[id_golpeado]
				GlobalEsferas.historial_aciertos.append(texto_opcion)
				print("Registrando acierto en Dashboard: ", texto_opcion)
		else:
			print("¡Respuesta incorrecta!")
			if fondo: fondo.reproducir_error()
			area.get_parent().self_modulate = Color(1.0, 0.0, 0.0, 1.0) # Rojo (error)
			
			# Guardar estadística de error para el Dashboard
			if GlobalEsferas.opciones_cargadas.size() > id_golpeado:
				var texto_opcion = GlobalEsferas.opciones_cargadas[id_golpeado]
				GlobalEsferas.historial_errores.append(texto_opcion)
				print("Registrando error en Dashboard: ", texto_opcion)
			
		# Destruimos la lanza al chocar
		queue_free()
