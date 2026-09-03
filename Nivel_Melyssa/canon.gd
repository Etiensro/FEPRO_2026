extends Sprite2D

@export var velocidad_movimiento: float = 400.0
@export var escena_lanza: PackedScene

# Necesitamos un Marker2D como hijo del cañón, colocado en la punta del barril
@onready var punto_disparo = $PuntoDisparo

func _process(delta: float) -> void:
	# Siempre pedir que redibuje por si el láser se debe mostrar o apagar
	queue_redraw()
	
	# REGLA 1: No hacer nada si no ha visto las 4 esferas
	if GlobalEsferas.esferas_vistas.has(false):
		return
		
	# REGLA 2: No hacer nada si ya se quedó sin vidas
	if GlobalEsferas.intentos_restantes <= 0:
		return

	# Movimiento horizontal con teclado
	var direccion = 0.0
	if Input.is_action_pressed("ui_right"):
		direccion += 1.0
	if Input.is_action_pressed("ui_left"):
		direccion -= 1.0
		
	position.x += direccion * velocidad_movimiento * delta
	
	# Disparo con espacio
	if Input.is_action_just_pressed("ui_accept"):
		disparar()

# Esto dibuja un "láser" rojo semitransparente para ayudar a apuntar
func _draw() -> void:
	# Solo dibujar láser si ya puede disparar
	if GlobalEsferas.esferas_vistas.has(false) or GlobalEsferas.intentos_restantes <= 0:
		return
		
	if punto_disparo:
		# Calculamos hacia dónde apunta el PuntoDisparo
		var direccion = Vector2.UP.rotated(punto_disparo.rotation)
		# Dibujamos la línea desde el PuntoDisparo
		draw_line(punto_disparo.position, punto_disparo.position + direccion * 2000, Color(1.0, 0.0, 0.0, 0.5), 4.0)
	else:
		draw_line(Vector2(0, 0), Vector2(0, -2000), Color(1.0, 0.0, 0.0, 0.5), 4.0)

func disparar() -> void:
	if escena_lanza:
		var nueva_lanza = escena_lanza.instantiate()
		
		# Usamos la posición Y ROTACIÓN exacta del PuntoDisparo
		if punto_disparo:
			nueva_lanza.global_position = punto_disparo.global_position
			nueva_lanza.global_rotation = punto_disparo.global_rotation
		else:
			nueva_lanza.global_position = global_position
			nueva_lanza.rotation = rotation
			
		# Añadimos la lanza al árbol principal de la escena
		get_tree().current_scene.add_child(nueva_lanza)
		
		# Gastamos una vida y sumamos a las estadísticas
		GlobalEsferas.intentos_restantes -= 1
		GlobalEsferas.total_disparos += 1
		print("¡Fuego! Vidas restantes: ", GlobalEsferas.intentos_restantes, " | Total disparos nivel: ", GlobalEsferas.total_disparos)
		
		# Apagar un icono de vida en la UI
		var contenedor_vidas = get_tree().current_scene.get_node_or_null("ContenedorVidas")
		if contenedor_vidas and GlobalEsferas.intentos_restantes >= 0 and GlobalEsferas.intentos_restantes < contenedor_vidas.get_child_count():
			contenedor_vidas.get_child(GlobalEsferas.intentos_restantes).hide()
		
		if GlobalEsferas.intentos_restantes <= 0:
			print("¡SE ACABARON LOS INTENTOS! Ve a la palanca.")
			var fondo = get_tree().current_scene.get_node_or_null("FondoPrincipal")
			if fondo and fondo.has_method("mostrar_mensaje_reinicio"):
				fondo.mostrar_mensaje_reinicio()
	else:
		print("Falta asignar la Escena Lanza en el Cañón")
