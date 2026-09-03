extends Control

@onready var video_player = $VideoStreamPlayer
@onready var color_rect = $ColorRect

func _ready() -> void:
	# Nos aseguramos que el fondo negro empiece transparente
	color_rect.modulate.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Reproducimos la intro
	video_player.play()
	
	# Cuando el video termina, llamamos a la función de fundido
	video_player.finished.connect(_on_video_finished)

func _on_video_finished() -> void:
	# Creamos la animación del fundido a negro (fade out)
	var tween = create_tween()
	
	# Hacemos que el ColorRect se vuelva totalmente negro en 1 segundo
	tween.tween_property(color_rect, "modulate:a", 1.0, 1.5)
	
	# Cuando termina el fundido, cambiamos a la escena 1
	tween.finished.connect(_iniciar_juego)

func _iniciar_juego() -> void:
	get_tree().change_scene_to_file("res://Nivel_Melyssa/escena_uno.tscn")
