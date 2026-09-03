extends Node2D

var respuesta_correcta = "Oxigeno"
var pregunta_actual = "¿Qué elemento de la tabla periódica, representado por el símbolo O, es indispensable para la respiración humana y constituye aproximadamente el 21% del aire de la Tierra?"
var bloqueado = false
var posicion_y_original_garra = 0
var tamano_y_original_cadena = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PlacaPregunta.text = pregunta_actual
	posicion_y_original_garra = $GarraMecanica.position.y
	tamano_y_original_cadena = $CadenaInfinita.size.y
	
	# Asignamos las respuestas a cada esfera
	$RepisaOpciones/EsferaA/Label.text = "Mercurio"
	$RepisaOpciones/EsferaB/Label.text = "Oro" # Esta es la correcta
	$RepisaOpciones/EsferaC/Label.text = "Helio"
	$RepisaOpciones/EsferaD/Label.text = "Oxigeno"
	# --- VERIFICACIÓN DE ESTADO ---
	if GestorEstadoNivelE.computadora_resuelta:
		# La computadora está resuelta: Escena normal e iluminada
		$PlacaPregunta.text = pregunta_actual
		$GarraMecanica.show()
		$CadenaInfinita.show()
		$FiltroOscuridad.hide() # Apagamos la oscuridad para que el nivel se vea normal
		bloqueado = false
		
		# --- MOVIMIENTO DEL BOTÓN: INFERIOR DERECHA ---
		# Obtenemos el tamaño de tu pantalla para mandarlo a la esquina
		var ancho_pantalla = get_viewport_rect().size.x
		var alto_pantalla = get_viewport_rect().size.y
		# Restamos píxeles para que no se salga de la pantalla (ajusta el 200 y el 150 a tu gusto)
		$CapaUI/BotonSalir.position = Vector2(ancho_pantalla - 400, alto_pantalla - 250)
		$CapaUI/FiltroBotonSalir.hide()
	else:
		# La computadora NO está resuelta: Modo inactivo, oscuro y texto negro
		$PlacaPregunta.text = "SISTEMA HIDRÁULICO APAGADO.\nREQUIERE ENERGÍA."
		
		# Teñimos de negro puro el texto de la placa principal[cite: 1]
		#$PlacaPregunta.add_theme_color_override("font_color", Color.BLACK)
		
		# Teñimos de negro el texto de todas las bolas de piedra en la repisa[cite: 1]
		for esfera in $RepisaOpciones.get_children():
			esfera.get_node("Label").hide()
			
		$GarraMecanica.hide() 
		$CadenaInfinita.hide() 
		$FiltroOscuridad.show() # Encendemos el filtro oscuro
		bloqueado = true # Evita interacciones con las esferas


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_esfera_a_pressed() -> void:
	evaluar_esfera($RepisaOpciones/EsferaA)

func _on_esfera_b_pressed() -> void:
	evaluar_esfera($RepisaOpciones/EsferaB)

func _on_esfera_c_pressed() -> void:
	evaluar_esfera($RepisaOpciones/EsferaC)

func _on_esfera_d_pressed() -> void:
	evaluar_esfera($RepisaOpciones/EsferaD)

func evaluar_esfera(nodo_esfera: TextureButton):
	if bloqueado: return
	bloqueado = true
	
	var tween = create_tween()
	
	# Compensación para el centro exacto de la esfera
	var centro_x_esfera = nodo_esfera.global_position.x + (nodo_esfera.size.x / 2.0)
	var centro_y_esfera = nodo_esfera.global_position.y + (nodo_esfera.size.y / 2.0)
	
	# FASE 1: Movimiento Horizontal (Líder)
	# La primera instrucción marca el ritmo, las siguientes con .parallel() se acoplan a ella
	tween.tween_property($GarraMecanica, "global_position:x", centro_x_esfera, 1.2)
	
	var compensacion_cadena = $CadenaInfinita.size.x / 2.0
	tween.parallel().tween_property($CadenaInfinita, "global_position:x", centro_x_esfera - compensacion_cadena, 1.2)
	
	var distancia_x = centro_x_esfera - $GarraMecanica.global_position.x
	var angulo_balanceo = -distancia_x * 0.05 
	tween.parallel().tween_property($GarraMecanica, "rotation_degrees", angulo_balanceo, 0.3)
	tween.parallel().tween_property($GarraMecanica, "rotation_degrees", 0.0, 0.3).set_delay(0.3)
	
	# FASE 2: Movimiento Vertical (Bloqueado)
	# .chain() crea un muro de tiempo. Nada de lo que sigue iniciará hasta que la Fase 1 termine.
	tween.chain().tween_property($GarraMecanica, "global_position:y", centro_y_esfera - 300, 1.2)
	
	var distancia_y = (centro_y_esfera - 300) - posicion_y_original_garra
	tween.parallel().tween_property($CadenaInfinita, "size:y", tamano_y_original_cadena + distancia_y, 1.2)
	
	# FASE 3: Agarrar
	tween.chain().tween_callback(func(): agarrar_y_evaluar(nodo_esfera))

func agarrar_y_evaluar(nodo_esfera: TextureButton):
	$GarraMecanica.texture = preload("res://Nivel_E/Assets/Garra Cerrada - copia.png")
	var texto_seleccionado = nodo_esfera.get_node("Label").text
	
	if texto_seleccionado == respuesta_correcta:
		$PlacaPregunta.text = "RESPUESTA CORRECTA. EXTRACCIÓN INICIADA..."
		secuencia_victoria(nodo_esfera)
	else:
		$PlacaPregunta.text = "SISTEMA HIDRÁULICO INESTABLE. REINTENTE."
		nodo_esfera.disabled = true
		animar_temblor_y_romper(nodo_esfera)
		soltar_y_regresar()

func animar_temblor_y_romper(nodo_esfera: TextureButton):
	var tween_shake = create_tween()
	var pos_original = nodo_esfera.position
	
	# Hacemos que vibre de izquierda a derecha rápidamente
	for i in range(4):
		tween_shake.tween_property(nodo_esfera, "position:x", pos_original.x + 6, 0.05)
		tween_shake.tween_property(nodo_esfera, "position:x", pos_original.x - 6, 0.05)
		
	tween_shake.tween_property(nodo_esfera, "position:x", pos_original.x, 0.05)
	
	# Al terminar de temblar, asignamos la imagen de la piedra rota
	# Pon el nombre exacto de tu asset de esfera rota aquí:
	tween_shake.tween_callback(func(): 
		nodo_esfera.texture_disabled = preload("res://Nivel_E/Assets/Esfera rota.png")
	)

func secuencia_victoria(nodo_esfera: TextureButton):
	# 1. "Arrancamos" la esfera de la repisa para poder moverla libremente
	nodo_esfera.reparent(self) 
	move_child(nodo_esfera, $GarraMecanica.get_index())
	
	var tween = create_tween()
	var centro_pantalla_x = get_viewport_rect().size.x / 2.0
	
	# FASE 1: Centrar la garra y la esfera en el pozo
	tween.set_parallel(true)
	tween.tween_property($GarraMecanica, "global_position:x", centro_pantalla_x, 1.0)
	
	var compensacion_cadena = $CadenaInfinita.size.x / 2.0
	tween.tween_property($CadenaInfinita, "global_position:x", centro_pantalla_x - compensacion_cadena, 1.0)
	
	# La esfera sigue a la garra
	var compensacion_esfera = nodo_esfera.size.x / 2.0
	tween.tween_property(nodo_esfera, "global_position:x", centro_pantalla_x - compensacion_esfera, 1.0)
	
	# FASE 2: Subir y desaparecer por el techo
	tween.chain().set_parallel(true)
	var altura_fuera_pantalla = -300 # Sube hasta salirse de la pantalla
	
	tween.chain().tween_property($GarraMecanica, "global_position:y", altura_fuera_pantalla, 1.5)
	# Compensamos para que la esfera siga justo en la pinza (ajusta el 150 a la medida de tu garra)
	tween.tween_property(nodo_esfera, "global_position:y", altura_fuera_pantalla + 193, 1.5) 
	tween.tween_property($CadenaInfinita, "size:y", 0, 1.5)
	
	# FASE 3: Viaje a la siguiente sala
	tween.chain().tween_callback(func():
		print("Viaje al Hub completado")
		GestorEstadoNivelE.foso_resuelto = true
		TransicionGlobal.cambiar_escena("res://Nivel_E/Hub_Principal.tscn")
	)

func soltar_y_regresar():
	# Aumentamos el tiempo a 1.5s para que el jugador alcance a leer el error
	await get_tree().create_timer(1.5).timeout 
	
	$GarraMecanica.texture = preload("res://Nivel_E/Assets/Garra Abierta.png")
	$PlacaPregunta.text = pregunta_actual # Restauramos la pregunta original
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property($GarraMecanica, "position:y", posicion_y_original_garra, 0.8)
	tween.tween_property($CadenaInfinita, "size:y", tamano_y_original_cadena, 0.8)
	tween.chain().tween_callback(func(): bloqueado = false)
	


func _on_boton_salir_pressed() -> void:
	TransicionGlobal.cambiar_escena("res://Nivel_E/Hub_Principal.tscn")
