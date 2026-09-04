extends Node2D

@onready var video_intro = $VideoIntro
@onready var video_transicion = $VideoTransicion
@onready var pantalla_acertijo = $Escenario1/Acertijo
@onready var sprite_carrito = $Escenario1
@onready var boton_verdadero = $Escenario1/BotonVerdadero
@onready var boton_falso = $Escenario1/BotonFalso

var textura_apagado = preload("res://Nivel_Sofia/Vistas/Carrito_apagado.jpg")
var textura_encendido = preload("res://Nivel_Sofia/Vistas/Carrito_encendido.jpg")

var lista_preguntas = []
var pregunta_actual = {}

func _ready():
	if sprite_carrito: sprite_carrito.texture = textura_apagado
	if pantalla_acertijo: pantalla_acertijo.visible = false
	if boton_verdadero: boton_verdadero.visible = false
	if boton_falso: boton_falso.visible = false
	if video_transicion: video_transicion.visible = false
	
	if video_intro:
		video_intro.size = get_viewport_rect().size
		video_intro.visible = true
		video_intro.finished.connect(_on_video_intro_terminado)
		video_intro.play()
	else:
		iniciar_nivel_carrito()

func _on_video_intro_terminado():
	if video_intro: video_intro.visible = false
	iniciar_nivel_carrito()

func iniciar_nivel_carrito():
	if pantalla_acertijo: pantalla_acertijo.visible = true
	if boton_verdadero: boton_verdadero.visible = true
	if boton_falso: boton_falso.visible = true
	cargar_json_carrito()

func cargar_json_carrito():
	if pantalla_acertijo: pantalla_acertijo.text = "Cargando desde la base de datos..."
	GestorTelemetria.preguntas_listas.connect(_on_preguntas_listas, CONNECT_ONE_SHOT)
	# 1. Pedir el bloque maestro del Nivel 2
	GestorTelemetria.descargar_preguntas("nivel_2")

func _on_preguntas_listas(array_nivel: Array) -> void:
	if array_nivel.size() > 0:
		var datos_nivel = array_nivel[0]
		# 2. Desempaquetar la fase del carrito
		if datos_nivel.has("carrito_fase"):
			lista_preguntas = datos_nivel["carrito_fase"]
			lista_preguntas.shuffle() 
			pregunta_actual = lista_preguntas[0]
			mostrar_pregunta()
		else:
			if pantalla_acertijo: pantalla_acertijo.text = "Error: Formato incorrecto."
	else:
		if pantalla_acertijo: pantalla_acertijo.text = "Error al descargar preguntas"

func mostrar_pregunta():
	if pantalla_acertijo and pregunta_actual.has("texto"):
		pantalla_acertijo.text = pregunta_actual["texto"]

func evaluar_respuesta(opcion_usuario: bool):
	var respuesta_correcta = pregunta_actual["respuesta"]
	var fue_acierto = (opcion_usuario == respuesta_correcta)
	
	# 3. Extraer los primeros 20 caracteres de la pregunta para la estadística V/F
	var concepto_vf = "V/F: " + str(pregunta_actual["texto"]).left(20) + "..."
	
	if fue_acierto:
		print("Resultado: ¡CORRECTO!")
		if sprite_carrito: sprite_carrito.texture = textura_encendido
		Global.suma_niveles += 1 
		# 4. Enviar 3 parámetros
		GestorTelemetria.enviar_reporte_final(1, [concepto_vf], [])
	else:
		print("Resultado: ¡INCORRECTO!")
		GestorTelemetria.enviar_reporte_final(1, [], [concepto_vf])
		
	if boton_verdadero: boton_verdadero.disabled = true
	if boton_falso: boton_falso.disabled = true
	
	await get_tree().create_timer(1.0).timeout
	reproducir_video_transicion()

func reproducir_video_transicion():
	if pantalla_acertijo: pantalla_acertijo.visible = false
	if sprite_carrito: sprite_carrito.visible = false
	if boton_verdadero: boton_verdadero.visible = false
	if boton_falso: boton_falso.visible = false
	
	if video_transicion:
		video_transicion.size = get_viewport_rect().size
		video_transicion.visible = true
		video_transicion.finished.connect(_on_video_transicion_terminado)
		video_transicion.play()
	else:
		_on_video_transicion_terminado()

func _on_video_transicion_terminado():
	get_tree().change_scene_to_file("res://Nivel_Sofia/sala_tuneles.tscn")

func _on_boton_verdadero_pressed():
	evaluar_respuesta(true)

func _on_boton_falso_pressed():
	evaluar_respuesta(false)
