extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

const ESCENA_FINAL: String = "res://main.tscn"

var puede_saltar: bool = false

func _ready() -> void:
	video_player.finished.connect(_on_video_finished)
	video_player.play()
	get_tree().create_timer(0.6).timeout.connect(func(): puede_saltar = true)

func _input(event: InputEvent) -> void:
	if not puede_saltar:
		return
		
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		_finalizar()

func _on_video_finished() -> void:
	_finalizar()

func _finalizar() -> void:
	set_process_input(false)
	
	GestorEstadoNivelBryan.laser_resuelto = false
	GestorEstadoNivelBryan.cilindros_resuelto = false
	GestorEstadoNivelBryan.cilindros_valores_guardados.clear()
	GestorEstadoNivelBryan.laser_posiciones_hojas.clear()
	GestorEstadoNivelBryan.laser_texturas_hojas.clear()
	GestorEstadoNivelBryan.laser_incisos_guardados.clear()
	
	get_tree().change_scene_to_file(ESCENA_FINAL)
