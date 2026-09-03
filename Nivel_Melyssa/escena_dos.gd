extends Node2D

func _ready():
	# Generar una pregunta NUEVA solo si se acabaron los intentos o si es la primera vez
	if GlobalEsferas.intentos_restantes <= 0 or GlobalEsferas.opciones_cargadas.size() == 0:
		$Instrucciones/ScrollTexto1/Label.text = "Cargando preguntas de la IA en la nube..."
		# Conectarnos a la señal antes de pedir la descarga (solo una vez)
		GestorTelemetria.preguntas_listas.connect(_on_preguntas_listas, CONNECT_ONE_SHOT)
		# Llamar a la Obra Maestra
		GestorTelemetria.descargar_preguntas("escena_garra")
	else:
		# Siempre mostramos la pregunta que está guardada en el Autoload
		$Instrucciones/ScrollTexto1/Label.text = GlobalEsferas.pregunta_actual

func _on_preguntas_listas(array_preguntas: Array) -> void:
	if array_preguntas.size() > 0:
		# Elegir pregunta aleatoria
		var indice_azar = randi() % array_preguntas.size()
		var pregunta_elegida = array_preguntas[indice_azar]
		
		# Encontrar cuál es el índice correcto 
		var correcta = pregunta_elegida["respuesta_correcta"]
		var opciones_db = pregunta_elegida["opciones"]
		var idx_correcto = opciones_db.find(correcta)
		
		# Guardamos los datos en el Autoload
		GlobalEsferas.pregunta_actual = pregunta_elegida["pregunta_texto"]
		GlobalEsferas.opciones_cargadas = opciones_db
		GlobalEsferas.indice_correcto = idx_correcto
		
		# Reiniciar el puzzle
		GlobalEsferas.esferas_vistas = [false, false, false, false]
		GlobalEsferas.intentos_restantes = 3
		
		print("--- [ÉXITO ESCENA 2] IA DESCARGADA. Pregunta: ", GlobalEsferas.pregunta_actual)
		$Instrucciones/ScrollTexto1/Label.text = GlobalEsferas.pregunta_actual
	else:
		print("--- [ERROR FATAL ESCENA 2] BD VACÍA O SIN ESCENA_GARRA")
		$Instrucciones/ScrollTexto1/Label.text = "Error al conectar con la base de datos."
			
func _on_boton_regresar_pressed() -> void:
	GlobalEsferas.pregunta_vista = true
	get_tree().change_scene_to_file("res://Nivel_Melyssa/escena_uno.tscn")
