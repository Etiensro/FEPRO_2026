extends Sprite2D

@export var velocidad_movimiento: float = 400.0
@export var escena_lanza: PackedScene
# Margen en píxeles para que el sprite no se corte en el borde de la pantalla
@export var margen: float = 80.0 

@onready var punto_disparo = $PuntoDisparo

func _process(delta: float) -> void:
	queue_redraw()
	
	if GlobalEsferas.esferas_vistas.has(false):
		return

	# Movimiento horizontal con teclado
	var direccion = 0.0
	if Input.is_action_pressed("ui_right"):
		direccion += 1.0
	if Input.is_action_pressed("ui_left"):
		direccion -= 1.0
		
	position.x += direccion * velocidad_movimiento * delta
	
	# Restringir la posición X a los límites de la pantalla
	var ancho_pantalla = get_viewport_rect().size.x
	position.x = clamp(position.x, margen, ancho_pantalla - margen)
	
	# Disparo con espacio
	if Input.is_action_just_pressed("ui_accept") and GlobalEsferas.intentos_restantes > 0:
		disparar()

func _draw() -> void:
	if GlobalEsferas.esferas_vistas.has(false) or GlobalEsferas.intentos_restantes <= 0:
		return
		
	if punto_disparo:
		var direccion = Vector2.UP.rotated(punto_disparo.rotation)
		# Multiplicador aumentado a 10000 para dar efecto de láser infinito
		draw_line(punto_disparo.position, punto_disparo.position + direccion * 10000, Color(1.0, 0.0, 0.0, 0.5), 4.0)
	else:
		draw_line(Vector2.ZERO, Vector2(0, -10000), Color(1.0, 0.0, 0.0, 0.5), 4.0)

func disparar() -> void:
	if escena_lanza:
		var nueva_lanza = escena_lanza.instantiate()
		
		if punto_disparo:
			nueva_lanza.global_position = punto_disparo.global_position
			nueva_lanza.global_rotation = punto_disparo.global_rotation
		else:
			nueva_lanza.global_position = global_position
			nueva_lanza.rotation = rotation
			
		get_tree().current_scene.add_child(nueva_lanza)
		
		GlobalEsferas.intentos_restantes -= 1
		GlobalEsferas.total_disparos += 1
		print("¡Fuego! Vidas restantes: ", GlobalEsferas.intentos_restantes, " | Total disparos nivel: ", GlobalEsferas.total_disparos)
		
		var contenedor_vidas = get_tree().current_scene.get_node_or_null("ContenedorVidas")
		if contenedor_vidas and GlobalEsferas.intentos_restantes >= 0 and GlobalEsferas.intentos_restantes < contenedor_vidas.get_child_count():
			contenedor_vidas.get_child(GlobalEsferas.intentos_restantes).hide()
		
		if GlobalEsferas.intentos_restantes <= 0:
			print("¡SE ACABARON LOS INTENTOS! Ve a la palanca.")
			var fondo = get_tree().current_scene.get_node_or_null("FondoPrincipal")
			if fondo and fondo.has_method("mostrar_mensaje_reinicio"):
				fondo.mostrar_mensaje_reinicio()
				
			GestorTelemetria.enviar_reporte_final(
				"jugador_melyssa", 
				"derrota", 
				GlobalEsferas.total_disparos, 
				GlobalEsferas.historial_aciertos, 
				GlobalEsferas.historial_errores
			)
	else:
		print("Falta asignar la Escena Lanza en el Cañón")
