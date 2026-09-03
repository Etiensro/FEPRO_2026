extends Node2D

var respuesta_correcta = "Oxigeno"
var pregunta_actual = "¿Qué elemento de la tabla periódica, representado por el símbolo O, es indispensable para la respiración humana y constituye aproximadamente el 21% del aire de la Tierra?"
var bloqueado = false
var posicion_y_original_garra = 0
var tamano_y_original_cadena = 0

# --- VARIABLES DE TELEMETRÍA ---
var intentos_garra: int = 0
var errores_jugador: Array = []
var aciertos_jugador: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	posicion_y_original_garra = $GarraMecanica.position.y
	tamano_y_original_cadena = $CadenaInfinita.size.y
	
	# --- VERIFICACIÓN DE ESTADO ---
	if GestorEstadoNivelE.computadora_resuelta:
		$PlacaPregunta.text = "DESCARGANDO SISTEMA HIDRÁULICO DESDE LA NUBE..."
		$GarraMecanica.show()
		$CadenaInfinita.show()
		$FiltroOscuridad.hide() # Apagamos la oscuridad para que el nivel se vea normal
		
		var ancho_pantalla = get_viewport_rect().size.x
		var alto_pantalla = get_viewport_rect().size.y
		$CapaUI/BotonSalir.position = Vector2(ancho_pantalla - 400, alto_pantalla - 250)
		$CapaUI/FiltroBotonSalir.hide()
		
		bloqueado = false
		
		# Conectarnos a la señal maestra
		GestorTelemetria.preguntas_listas.connect(_on_preguntas_listas, CONNECT_ONE_SHOT)
		GestorTelemetria.descargar_preguntas("escena_garra")
	else:
		# La computadora NO está resuelta: Modo inactivo, oscuro y texto negro
		$PlacaPregunta.text = "SISTEMA HIDRÁULICO APAGADO.\nREQUIERE ENERGÍA."
		for esfera in $RepisaOpciones.get_children():
			esfera.get_node("Label").hide()
			
		$GarraMecanica.hide() 
		$CadenaInfinita.hide()
		$FiltroOscuridad.show()
		$CapaUI/FiltroBotonSalir.show()

var lista_preguntas: Array = []
var fallos_consecutivos_garra: int = 0

func _on_preguntas_listas(datos: Array) -> void:
	if datos.size() > 0:
		lista_preguntas = datos
		cargar_nueva_pregunta_garra()
	else:
		$PlacaPregunta.text = "ERROR AL DESCARGAR DATOS"
		bloqueado = true # Evita interacciones con las esferas

func cargar_nueva_pregunta_garra():
	if lista_preguntas.size() > 0:
		lista_preguntas.shuffle()
		var puzzle_actual = lista_preguntas[0] 
		pregunta_actual = puzzle_actual["pregunta_texto"]
		respuesta_correcta = puzzle_actual["respuesta_correcta"]
		
		var opciones = puzzle_actual["opciones"].duplicate()
		opciones.shuffle()
		
		# Reactivar todas las esferas y restaurar textura
		for esfera in $RepisaOpciones.get_children():
			esfera.disabled = false
			esfera.texture_normal = preload("res://Nivel_E/Assets/Esfera.png")
		
		$RepisaOpciones/EsferaA/Label.text = opciones[0]
		$RepisaOpciones/EsferaB/Label.text = opciones[1]
		$RepisaOpciones/EsferaC/Label.text = opciones[2]
		$RepisaOpciones/EsferaD/Label.text = opciones[3]
		
		$PlacaPregunta.text = pregunta_actual

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
	
	intentos_garra += 1
	
	if texto_seleccionado == respuesta_correcta:
		aciertos_jugador.append(texto_seleccionado)
		GestorTelemetria.enviar_reporte_final("jugador_etienne", "victoria_garra", intentos_garra, aciertos_jugador, errores_jugador)
		
		$PlacaPregunta.text = "RESPUESTA CORRECTA. EXTRACCIÓN INICIADA..."
		secuencia_victoria(nodo_esfera)
	else:
		errores_jugador.append(texto_seleccionado)
		fallos_consecutivos_garra += 1
		
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
