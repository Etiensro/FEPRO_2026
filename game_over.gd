extends Control

@onready var reproductor: VideoStreamPlayer = $VideoStreamPlayer

func _ready() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	if reproductor:
		reproductor.size = get_viewport_rect().size
		reproductor.finished.connect(_on_video_terminado)
		reproductor.play()
		
		# Temporizador de respaldo por si el video no emite señal de finished
		var duracion = reproductor.get_stream_length()
		var margen = (duracion + 1.5) if duracion > 0.0 else 12.0
		get_tree().create_timer(margen).timeout.connect(_on_video_terminado)
	else:
		_on_video_terminado()

func _on_video_terminado() -> void:
	# Transición suave al menú principal
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	await tween.finished
	get_tree().change_scene_to_file("res://Menu_lvl/Menu.tscn")
