extends Node2D

func _ready():
	# 1. Checar estado del Bote de Basura
	if GestorEstadoNivelE.bote_tirado:
		$BoteBasura.disabled = true
		# Aplicamos la rotación y posición final de tu animación para que ya aparezca tirado
		$BoteBasura.rotation_degrees = -90.0
		
		# ¿Ya recogimos la tuerca de aquí?
		if not GestorEstadoNivelE.engranaje_bote_recogido:
			$EngranajeBote.show()
		else:
			$EngranajeBote.hide()
	else:
		$EngranajeBote.hide()

	# 2. Checar estado de la Puerta del Escritorio
	if GestorEstadoNivelE.puerta_abierta:
		$PuertaEscritorio.disabled = true
		$PuertaEscritorio.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$PuertaEscritorio.texture_normal = preload("res://Nivel_E/Assets/Puerta Abierta.png") # Descomenta si usas imagen
		
		if not GestorEstadoNivelE.engranaje_puerta_recogido:
			$EngranajePuerta.show()
		else:
			$EngranajePuerta.hide()
	else:
		$EngranajePuerta.hide()

func _on_bote_basura_pressed():
	GestorEstadoNivelE.bote_tirado = true
	# 1. Desactiva el botón para evitar que el jugador lo presione 20 veces
	$BoteBasura.disabled = true
	
	# 2. Creamos la animación (Tween)
	var tween = create_tween()
	tween.set_parallel(true) # Ejecuta rotación y movimiento al mismo tiempo
	
	# 3. Rota el bote 90 grados y lo mueve ligeramente hacia abajo/derecha
	tween.tween_property($BoteBasura, "rotation_degrees", -90.0, 0.3).set_trans(Tween.TRANS_SPRING)
	
	
	# 4. Cuando termina de caer, hace visible el engranaje
	tween.chain().tween_callback($EngranajeBote.show)
	
func _on_puerta_escritorio_pressed():
	GestorEstadoNivelE.puerta_abierta = true
	$PuertaEscritorio.disabled = true
	$PuertaEscritorio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Si tienes la imagen del cajón abierto, quita el '#' de la siguiente línea y pon tu ruta exacta:
	$PuertaEscritorio.texture_normal = preload("res://Nivel_E/Assets/Puerta abierta.png")
	$EngranajePuerta.show()

func _on_engranaje_puerta_pressed():
	GestorEstadoNivelE.engranaje_puerta_recogido = true
	GestorEstadoNivelE.engranajes_recolectados += 1
	$EngranajePuerta.queue_free() # Lo borra de la escena

func _on_engranaje_bote_pressed():
	GestorEstadoNivelE.engranaje_bote_recogido = true
	GestorEstadoNivelE.engranajes_recolectados += 1
	$EngranajeBote.queue_free()

func _on_boton_volver_pressed():
	TransicionGlobal.cambiar_escena("res://Nivel_E/Hub_Principal.tscn")


func _on_boton_buho_pressed():
	# Bloquea el botón un momento para evitar que el jugador haga spam de clics
	$BotonBuho.disabled = true
	
	var tween = create_tween()
	
	# 1. Enciende los ojos rápidamente (Sube la transparencia a 1 en 0.2 segundos)
	tween.tween_property($BotonBuho/OjosRojos, "modulate:a", 1.0, 0.3)
	
	tween.tween_interval(1.5)
	
	# 2. Los apaga lentamente (Baja la transparencia a 0 en 0.6 segundos)
	tween.tween_property($BotonBuho/OjosRojos, "modulate:a", 0.0, 0.5)
	
	# 3. Vuelve a habilitar el botón cuando el destello termina
	tween.chain().tween_callback(func(): $BotonBuho.disabled = false)
