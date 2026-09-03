extends Node2D

@onready var area_rodillos: Area2D = $AreaRodillos
@onready var area_laser: Area2D = $AreaLaser

func _ready() -> void:
	# Configurar colisión de los rodillos (vuelve al mecanismo bloqueado/resuelto)
	if area_rodillos:
		area_rodillos.input_event.connect(_on_area_rodillos_input_event)
		area_rodillos.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
		area_rodillos.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))
	
	# Configurar colisión del compartimento con luz (lleva a la escena del láser)
	if area_laser:
		area_laser.input_event.connect(_on_area_laser_input_event)
		area_laser.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
		area_laser.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))

func _on_area_rodillos_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		get_tree().change_scene_to_file("res://Nivel_Bryan/MecanismoZoom.tscn")

func _on_area_laser_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		# Redirige a la escena del láser dentro de Nivel_Bryan
		get_tree().change_scene_to_file("res://Nivel_Bryan/laser_mecanismo.tscn")
