extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

const ESCENA_SIGUIENTE: String = "res://sala_1.tscn"

var puede_saltar: bool = false

func _ready() -> void:
	# Conectar señal de fin de reproducción
	video_player.finished.connect(_on_video_finished)
	video_player.play()
	
	# Retardo de 0.5s para evitar saltos accidentales al abrir
	get_tree().create_timer(0.5).timeout.connect(func(): puede_saltar = true)

# Saltar la intro con cualquier tecla o clic del ratón
func _input(event: InputEvent) -> void:
	if not puede_saltar:
		return
		
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		_cambiar_a_sala()

func _on_video_finished() -> void:
	_cambiar_a_sala()

func _cambiar_a_sala() -> void:
	set_process_input(false)
	get_tree().change_scene_to_file(ESCENA_SIGUIENTE)
	
	
