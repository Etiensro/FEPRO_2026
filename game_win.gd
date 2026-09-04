extends Control

const RUTA_VIDEO: String = "res://Menu_lvl/Assets/gamewinvideo.ogv"
@onready var reproductor: VideoStreamPlayer = $VideoStreamPlayer

var ya_termino: bool = false

func _ready() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	if not reproductor:
		_ir_al_menu()
		return
		
	if ResourceLoader.exists(RUTA_VIDEO):
		reproductor.stream = load(RUTA_VIDEO)
	
	reproductor.expand = true
	reproductor.set_anchors_preset(Control.PRESET_FULL_RECT)
	reproductor.finished.connect(_on_video_terminado)
	reproductor.play()
	
	# Margen de seguridad dinámico
	await get_tree().process_frame
	var duracion = reproductor.get_stream_length()
	var margen = (duracion + 2.0) if duracion > 1.0 else 15.0
	get_tree().create_timer(margen).timeout.connect(func():
		if not ya_termino:
			_on_video_terminado()
	)

func _on_video_terminado() -> void:
	if ya_termino: return
	ya_termino = true
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	_ir_al_menu()

func _ir_al_menu() -> void:
	get_tree().change_scene_to_file("res://Menu_lvl/Menu.tscn")
