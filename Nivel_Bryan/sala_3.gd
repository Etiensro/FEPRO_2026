extends Node2D

@onready var area_laser: Area2D = $AreaLaser
@onready var area_rodillos: Area2D = $AreaRodillos
@onready var area_salida: Area2D = $Salida

const ESCENA_OUTRO: String = "res://outro_video.tscn"

func _ready() -> void:
	_conectar_area(area_laser, _on_area_laser_input)
	_conectar_area(area_rodillos, _on_area_rodillos_input)
	_conectar_area(area_salida, _on_salida_input)

func _conectar_area(area: Area2D, callback: Callable) -> void:
	if area != null:
		area.input_event.connect(callback)
		area.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
		area.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))

# Regresar al láser
func _on_area_laser_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		get_tree().change_scene_to_file("res://laser_mecanismo.tscn")

# Regresar a los cilindros
func _on_area_rodillos_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		get_tree().change_scene_to_file("res://MecanismoZoom.tscn")

# Clic en la puerta de salida para activar la cinemática
func _on_salida_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if GameManager.laser_resuelto and GameManager.cilindros_resuelto:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			get_tree().change_scene_to_file(ESCENA_OUTRO)
