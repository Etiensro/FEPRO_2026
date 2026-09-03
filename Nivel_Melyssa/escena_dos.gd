extends Node2D

func _ready():
	# Generar una pregunta NUEVA solo si se acabaron los intentos o si es la primera vez
	if GlobalEsferas.intentos_restantes <= 0 or GlobalEsferas.opciones_cargadas.size() == 0:
		var archivo = FileAccess.open("res://Nivel_Melyssa/nivel_prueba.json", FileAccess.READ)
		if archivo:
			var texto_json = archivo.get_as_text()
			var array_preguntas = JSON.parse_string(texto_json)
			
			# Elegir pregunta aleatoria
			var indice_azar = randi() % array_preguntas.size()
			var pregunta_elegida = array_preguntas[indice_azar]
			
			# Guardamos los datos en el Autoload
			GlobalEsferas.pregunta_actual = pregunta_elegida["pregunta"]
			GlobalEsferas.opciones_cargadas = Array(pregunta_elegida["opciones"])
			GlobalEsferas.indice_correcto = pregunta_elegida["indice_correcto"]
			
			# Reiniciar el puzzle
			GlobalEsferas.esferas_vistas = [false, false, false, false]
			GlobalEsferas.intentos_restantes = 3
			
			print("--- [ÉXITO ESCENA 2] JSON LEÍDO. Pregunta elegida: ", pregunta_elegida["pregunta"])
		else:
			print("--- [ERROR FATAL ESCENA 2] NO SE PUDO ABRIR EL JSON")
			
	# Siempre mostramos la pregunta que está guardada en el Autoload
	$Instrucciones/ScrollTexto1/Label.text = GlobalEsferas.pregunta_actual
			
func _on_boton_regresar_pressed() -> void:
	GlobalEsferas.pregunta_vista = true
	get_tree().change_scene_to_file("res://Nivel_Melyssa/escena_uno.tscn")
