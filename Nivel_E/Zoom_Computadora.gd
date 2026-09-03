extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Tuerca1.hide()
	$Tuerca2.hide()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $Tuerca1.visible:
		$Tuerca1.rotation += 1.0 * delta # Cambia el 3.0 para hacerlos girar más rápido o lento
	if $Tuerca2.visible:
		$Tuerca2.rotation -= 1.0 * delta # Cambia el 3.0 para hacerlos girar más rápido o lento

func _on_zona_tuercas_pressed():
	# Verifica si el jugador ya recolectó las 2 tuercas del escritorio
	if GestorEstadoNivelE.engranajes_recolectados >= 2:
		$ZonaTuercas.disabled = true
		$Tuerca1.show()
		$Tuerca2.show()
		print("Mecanismo ensamblado. Iniciando secuencia...")
		iniciar_secuencia_encendido()
	else:
		print("Faltan piezas para que el mecanismo funcione.")

func iniciar_secuencia_encendido():
	var tween = create_tween()
	tween.set_parallel(true) # Todo lo que sigue ocurre al mismo tiempo

	# 1. La cámara hace el "zoom in" dramático hacia el centro del monitor
	# IMPORTANTE: Ajusta el Vector2(600, 300) a las coordenadas del centro de tu monitor en el dibujo
	tween.tween_property($Camera2D, "zoom", Vector2(2.0, 2.0), 3).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Camera2D, "position", Vector2(800, 400), 3).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(ejecutar_fundido_global)

func ejecutar_fundido_global():
	# Invocamos el telón negro solo cuando la cámara ya está pegada al monitor
	TransicionGlobal.cambiar_escena("res://Nivel_E/Acertijo_Monitor.tscn")

func _on_boton_volver_pressed() -> void:
	TransicionGlobal.cambiar_escena("res://Nivel_E/Hub_Principal.tscn")
