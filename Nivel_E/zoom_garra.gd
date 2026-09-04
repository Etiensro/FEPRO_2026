extends Node2D

var respuesta_correcta = "Oxigeno"
var pregunta_actual = "¿Qué elemento de la tabla periódica, representado por el símbolo O, es indispensable para la respiración humana y constituye aproximadamente el 21% del aire de la Tierra?"
var bloqueado = false
var posicion_y_original_garra = 0
var tamano_y_original_cadena = 0

# --- VARIABLES DE CONTROL LOCAL ---
var intentos_garra: int = 0
var errores_jugador: Array = []
var aciertos_jugador: Array = []
var lista_preguntas: Array = []
var fallos_consecutivos_garra: int = 0

func _ready() -> void:
	posicion_y_original_garra = $GarraMecanica.position.y
	tamano_y_original_cadena = $CadenaInfinita.size.y
	
	if GestorEstadoNivelE.computadora_resuelta:
		$PlacaPregunta.text = "DESCARGANDO SISTEMA HIDRÁULICO DESDE LA NUBE..."
		$GarraMecanica.show()
		$CadenaInfinita.show()
		$FiltroOscuridad.hide()
		
		var ancho_pantalla = get_viewport_rect().size.x
		var alto_pantalla = get_viewport_rect().size.y
		$CapaUI/BotonSalir.position = Vector2(ancho_pantalla - 400, alto_pantalla - 250)
		$CapaUI/FiltroBotonSalir.hide()
		
		bloqueado = false
		
		if get_tree().root.has_node("GestorTelemetria"):
			GestorTelemetria.preguntas_listas.connect(_on_preguntas_listas, CONNECT_ONE_SHOT)
			# 1. Apuntamos al bloque maestro
			GestorTelemetria.descargar_preguntas("nivel_1")
		else:
			_on_preguntas_listas([])
	else:
		$PlacaPregunta.text = "SISTEMA HIDRÁULICO APAGADO.\nREQUIERE ENERGÍA."
		for esfera in $RepisaOpciones.get_children():
			esfera.get_node("Label").hide()
			
		$GarraMecanica.hide()
		$CadenaInfinita.hide()
		$FiltroOscuridad.show()
		$CapaUI/FiltroBotonSalir.show()

func _process(_delta: float) -> void:
	pass

func _on_preguntas_listas(datos: Array) -> void:
	if datos.size() > 0:
		var datos_nivel = datos[0]
		if datos_nivel.has("escena_garra"):
			lista_preguntas = datos_nivel["escena_garra"]
			cargar_nueva_pregunta_garra()
		else:
			$PlacaPregunta.text = "ERROR: FORMATO INCORRECTO"
			bloqueado = true
	else:
		$PlacaPregunta.text = "ERROR AL DESCARGAR DATOS"
		bloqueado = true

func cargar_nueva_pregunta_garra():
	if lista_preguntas.size() > 0:
		lista_preguntas.shuffle()
		var puzzle_actual = lista_preguntas[0]
		pregunta_actual = puzzle_actual["pregunta_texto"]
		respuesta_correcta = puzzle_actual["respuesta_correcta"]
		
		var opciones = puzzle_actual["opciones"].duplicate()
		opciones.shuffle()
		
		for esfera in $RepisaOpciones.get_children():
			esfera.disabled = false
			esfera.texture_normal = preload("res://Nivel_E/Assets/Esfera.png")
		
		$RepisaOpciones/EsferaA/Label.text = opciones[0]
		$RepisaOpciones/EsferaB/Label.text = opciones[1]
		$RepisaOpciones/EsferaC/Label.text = opciones[2]
		$RepisaOpciones/EsferaD/Label.text = opciones[3]
		
		$PlacaPregunta.text = pregunta_actual

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
	
	var centro_x_esfera = nodo_esfera.global_position.x + (nodo_esfera.size.x / 2.0)
	var centro_y_esfera = nodo_esfera.global_position.y + (nodo_esfera.size.y / 2.0)
	
	# FASE 1: Movimiento Horizontal
	tween.tween_property($GarraMecanica, "global_position:x", centro_x_esfera, 1.2)
	
	var compensacion_cadena = $CadenaInfinita.size.x / 2.0
	tween.parallel().tween_property($CadenaInfinita, "global_position:x", centro_x_esfera - compensacion_cadena, 1.2)
	
	var distancia_x = centro_x_esfera - $GarraMecanica.global_position.x
	var angulo_balanceo = -distancia_x * 0.05
	tween.parallel().tween_property($GarraMecanica, "rotation_degrees", angulo_balanceo, 0.3)
	tween.parallel().tween_property($GarraMecanica, "rotation_degrees", 0.0, 0.3).set_delay(0.3)
	
	# FASE 2: Movimiento Vertical
	tween.chain().tween_property($GarraMecanica, "global_position:y", centro_y_esfera - 300, 1.2)
	
	var distancia_y = (centro_y_esfera - 300) - posicion_y_original_garra
	tween.parallel().tween_property($CadenaInfinita, "size:y", tamano_y_original_cadena + distancia_y, 1.2)
	
	# FASE 3: Agarrar
	tween.chain().tween_callback(func(): agarrar_y_evaluar(nodo_esfera))

func agarrar_y_evaluar(nodo_esfera: TextureButton):
	$GarraMecanica.texture = preload("res://Nivel_E/Assets/Garra Cerrada - copia.png")
	var texto_seleccionado = nodo_esfera.get_node("Label").text
	
	intentos_garra += 1
	
	if texto_seleccionado == respuesta_correcta:
		aciertos_jugador.append(texto_seleccionado)
		
		# REGISTRO GLOBAL: Guarda únicamente el texto literal de la respuesta correcta
		if get_tree().root.has_node("GestorTelemetria"):
			GestorTelemetria.registrar_respuesta("Nivel_E", true, respuesta_correcta)
		
		$PlacaPregunta.text = "RESPUESTA CORRECTA. EXTRACCIÓN INICIADA..."
		secuencia_victoria(nodo_esfera)
	else:
		errores_jugador.append(texto_seleccionado)
		fallos_consecutivos_garra += 1
		
		# REGISTRO GLOBAL: Guarda únicamente el texto literal que seleccionó erróneamente
		if get_tree().root.has_node("GestorTelemetria"):
			GestorTelemetria.registrar_respuesta("Nivel_E", false, texto_seleccionado)
		
		$PlacaPregunta.text = "SISTEMA HIDRÁULICO INESTABLE. REINTENTE."
		nodo_esfera.disabled = true
		animar_temblor_y_romper(nodo_esfera)
		
		if fallos_consecutivos_garra >= 2:
			fallos_consecutivos_garra = 0
			await get_tree().create_timer(1.5).timeout
			cargar_nueva_pregunta_garra()
			
		soltar_y_regresar()

func animar_temblor_y_romper(nodo_esfera: TextureButton):
	var tween_shake = create_tween()
	var pos_original = nodo_esfera.position
	
	for i in range(4):
		tween_shake.tween_property(nodo_esfera, "position:x", pos_original.x + 6, 0.05)
		tween_shake.tween_property(nodo_esfera, "position:x", pos_original.x - 6, 0.05)
		
	tween_shake.tween_property(nodo_esfera, "position:x", pos_original.x, 0.05)
	
	tween_shake.tween_callback(func():
		nodo_esfera.texture_disabled = preload("res://Nivel_E/Assets/Esfera rota.png")
	)

func secuencia_victoria(nodo_esfera: TextureButton):
	nodo_esfera.reparent(self)
	move_child(nodo_esfera, $GarraMecanica.get_index())
	
	var tween = create_tween()
	var centro_pantalla_x = get_viewport_rect().size.x / 2.0
	
	# FASE 1: Centrar la garra y la esfera en el pozo
	tween.set_parallel(true)
	tween.tween_property($GarraMecanica, "global_position:x", centro_pantalla_x, 1.0)
	
	var compensacion_cadena = $CadenaInfinita.size.x / 2.0
	tween.tween_property($CadenaInfinita, "global_position:x", centro_pantalla_x - compensacion_cadena, 1.0)
	
	var compensacion_esfera = nodo_esfera.size.x / 2.0
	tween.tween_property(nodo_esfera, "global_position:x", centro_pantalla_x - compensacion_esfera, 1.0)
	
	# FASE 2: Subir y desaparecer por el techo
	tween.chain().set_parallel(true)
	var altura_fuera_pantalla = -300
	
	tween.chain().tween_property($GarraMecanica, "global_position:y", altura_fuera_pantalla, 1.5)
	tween.tween_property(nodo_esfera, "global_position:y", altura_fuera_pantalla + 193, 1.5)
	tween.tween_property($CadenaInfinita, "size:y", 0, 1.5)
	
	# FASE 3: Viaje al Hub
	tween.chain().tween_callback(func():
		print("Viaje al Hub completado")
		GestorEstadoNivelE.foso_resuelto = true
		TransicionGlobal.cambiar_escena("res://Nivel_E/Hub_Principal.tscn")
	)

func soltar_y_regresar():
	await get_tree().create_timer(1.5).timeout
	
	$GarraMecanica.texture = preload("res://Nivel_E/Assets/Garra Abierta.png")
	$PlacaPregunta.text = pregunta_actual
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property($GarraMecanica, "position:y", posicion_y_original_garra, 0.8)
	tween.tween_property($CadenaInfinita, "size:y", tamano_y_original_cadena, 0.8)
	tween.chain().tween_callback(func(): bloqueado = false)

func _on_boton_salir_pressed() -> void:
	TransicionGlobal.cambiar_escena("res://Nivel_E/Hub_Principal.tscn")
