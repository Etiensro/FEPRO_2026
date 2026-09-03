extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func cambiar_escena(ruta_nueva_escena: String):
	# 1. Obtenemos el nodo de forma estricta
	var fundido = get_node("FundidoNegro")
	
	if fundido == null:
		push_error("Error crítico: El Autoload no encuentra el nodo FundidoNegro.")
		get_tree().change_scene_to_file(ruta_nueva_escena)
		return
		
	var tween = create_tween()	
	tween.tween_property(fundido, "color:a", 1.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(ruta_nueva_escena))
	tween.tween_property(fundido, "color:a", 0.0, 0.5).set_delay(0.2)
