extends VideoStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process_input(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_finished() -> void:
	print("Video terminado. Regresando al menú principal...")
	# Cambia esta ruta a tu pantalla de inicio o créditos
	TransicionGlobal.cambiar_escena("res://Pantalla_Inicio.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		TransicionGlobal.cambiar_escena("res://Pantalla_Inicio.tscn")
