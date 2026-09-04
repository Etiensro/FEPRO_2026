extends Node2D

func _ready() -> void:
	# Muestra el mensaje apenas entra a la sala (durante 4 segundos)
	TransicionGlobal.mostrar_subtitulo("Hmm esos rodillos que brillan podrian serme utiles.....", 4.0)
	
	# Conexiones de los rodillos
	$AreaRodillos.mouse_entered.connect(_on_area_rodillos_mouse_entered)
	$AreaRodillos.mouse_exited.connect(_on_area_rodillos_mouse_exited)
	$AreaRodillos.input_event.connect(_on_area_rodillos_input_event)

func _on_area_rodillos_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Si el mensaje sigue en pantalla cuando el jugador entra al zoom, lo oculta
			if TransicionGlobal.has_method("ocultar_subtitulo"):
				TransicionGlobal.ocultar_subtitulo()
			
			# Restaura el cursor a flecha normal antes de salir
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			
			# Carga la escena del puzzle
			if TransicionGlobal.has_method("cambiar_escena"):
				TransicionGlobal.cambiar_escena("res://Nivel_Bryan/MecanismoZoom.tscn")
			else:
				get_tree().change_scene_to_file("res://Nivel_Bryan/MecanismoZoom.tscn")

func _on_area_rodillos_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_area_rodillos_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
