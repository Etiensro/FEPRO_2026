extends Area2D

@export var id_direccion: int = 1

var arrastrando: bool = false
var pos_inicial: Vector2
var radio_clic: float = 60.0

func _ready() -> void:
	pos_inicial = global_position

func _process(_delta: float) -> void:
	if arrastrando:
		global_position = get_global_mouse_position()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if global_position.distance_to(get_global_mouse_position()) < radio_clic:
				arrastrando = true
				z_index = 25
				Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		else:
			if arrastrando:
				arrastrando = false
				z_index = 1
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)
				_soltar_pieza()

func _soltar_pieza() -> void:
	var escena = get_tree().current_scene
	var encajado: bool = false
	
	if escena != null and escena.has_method("intentar_encajar_lente"):
		encajado = escena.intentar_encajar_lente(self, id_direccion)
	
	if not encajado:
		resetear_posicion()

func resetear_posicion() -> void:
	var tween = create_tween()
	tween.tween_property(self, "global_position", pos_inicial, 0.2)
