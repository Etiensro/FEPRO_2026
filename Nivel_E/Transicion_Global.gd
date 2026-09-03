extends CanvasLayer

@onready var panel_subtitulos = get_node_or_null("PanelSubtitulos")
@onready var label_subtitulos = get_node_or_null("PanelSubtitulos/LabelSubtitulos")
var timer_subtitulos: Timer

func _ready() -> void:
	# Ocultamos el panel al iniciar para que no estorbe
	if panel_subtitulos:
		panel_subtitulos.hide()
	timer_subtitulos = Timer.new()
	timer_subtitulos.one_shot = true
	timer_subtitulos.timeout.connect(ocultar_subtitulo)
	add_child(timer_subtitulos)

func cambiar_escena(ruta_nueva_escena: String):
	var fundido = get_node("FundidoNegro")
	
	if fundido == null:
		push_error("Error crítico: El Autoload no encuentra el nodo FundidoNegro.")
		get_tree().change_scene_to_file(ruta_nueva_escena)
		return
		
	var tween = create_tween()	
	tween.tween_property(fundido, "color:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(ruta_nueva_escena))
	tween.tween_property(fundido, "color:a", 0.0, 0.5).set_delay(0.2)

# --- CONTROL DE SUBTÍTULOS ---

# Añadimos un parámetro 'duracion' (por defecto 3 segundos)
func mostrar_subtitulo(texto: String, duracion: float = 3.0):
	if panel_subtitulos and label_subtitulos:
		label_subtitulos.text = texto
		panel_subtitulos.show()
		timer_subtitulos.start(duracion) # Inicia o reinicia el tiempo

func ocultar_subtitulo():
	if panel_subtitulos:
		panel_subtitulos.hide()
