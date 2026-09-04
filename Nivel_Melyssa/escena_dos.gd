extends Node2D

func _ready():
	if GlobalEsferas.intentos_restantes <= 0 or GlobalEsferas.opciones_cargadas.size() == 0:
		$Instrucciones/ScrollTexto1/Label.text = "Cargando preguntas de la IA en la nube..."
		GestorTelemetria.preguntas_listas.connect(_on_preguntas_listas, CONNECT_ONE_SHOT)
		
		# 1. SOLUCIÓN: Pedir el bloque exacto del Nivel 4
		GestorTelemetria.descargar_preguntas("nivel_4")
	else:
		$Instrucciones/ScrollTexto1/Label.text = GlobalEsferas.pregunta_actual
		
	var timer_pista = Timer.new()
	timer_pista.wait_time = 7.0
	timer_pista.one_shot = true
	timer_pista.autostart = true
	timer_pista.timeout.connect(func():
		TransicionGlobal.mostrar_subtitulo("Usa el instructivo con sabiduría...", 4.0)
	)
	add_child(timer_pista)

func _on_preguntas_listas(array_nivel: Array) -> void:
	if array_nivel.size() > 0:
		# 2. SOLUCIÓN: Desempaquetar el diccionario {"preguntas": [...]} que genera Groq
		var datos_nivel = array_nivel[0]
		
		if datos_nivel.has("preguntas"):
			var array_preguntas = datos_nivel["preguntas"]
			
			# Elegir pregunta aleatoria
			var indice_azar = randi() % array_preguntas.size()
			var pregunta_elegida = array_preguntas[indice_azar]
			
			GlobalEsferas.pregunta_actual = pregunta_elegida["pregunta"]
			GlobalEsferas.opciones_cargadas = pregunta_elegida["opciones"]
			GlobalEsferas.indice_correcto = int(pregunta_elegida["indice_correcto"])
			
			GlobalEsferas.esferas_vistas = [false, false, false, false]
			GlobalEsferas.intentos_restantes = 3
			
			print("--- [ÉXITO ESCENA 2] IA DESCARGADA. Pregunta: ", GlobalEsferas.pregunta_actual)
			$Instrucciones/ScrollTexto1/Label.text = GlobalEsferas.pregunta_actual
		else:
			$Instrucciones/ScrollTexto1/Label.text = "Error: Formato de IA incorrecto para este nivel."
	else:
		print("--- [ERROR FATAL ESCENA 2] BD VACÍA")
		$Instrucciones/ScrollTexto1/Label.text = "Error al conectar con la base de datos."

func _on_boton_regresar_pressed() -> void:
	GlobalEsferas.pregunta_vista = true
	get_tree().change_scene_to_file("res://Nivel_Melyssa/escena_uno.tscn")
