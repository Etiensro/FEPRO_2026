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
var fallos_consecutivos: int = 0
var bloqueado: bool = false

func _ready():
	var vidas_inicio = 3
	if get_tree().root.has_node("GestorVidas"):
		vidas_inicio = get_tree().root.get_node("GestorVidas").vidas
	print("\n========================================")
	print(" [NIVEL SOFÍA: CARRITO INICIADO]")
	print(" Vidas disponibles del jugador: %d / 3" % vidas_inicio)
	print("========================================\n")

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
	if get_tree().root.has_node("GestorTelemetria"):
		GestorTelemetria.preguntas_listas.connect(_on_preguntas_listas, CONNECT_ONE_SHOT)
		GestorTelemetria.descargar_preguntas("nivel_2")
	else:
		_cargar_pregunta_respaldo()

func _on_preguntas_listas(array_nivel: Array) -> void:
	if array_nivel.size() > 0:
		var datos_nivel = array_nivel[0]
		if datos_nivel.has("carrito_fase"):
			lista_preguntas = datos_nivel["carrito_fase"]
			_seleccionar_nueva_pregunta()
			return
		else:
			print("Aviso: Formato desconocido en carrito_fase. Usando respaldo...")
	else:
		print("Aviso: No se recibieron preguntas para el carrito. Usando respaldo...")
		
	_cargar_pregunta_respaldo()

func _seleccionar_nueva_pregunta():
	if lista_preguntas.size() > 0:
		var texto_actual = pregunta_actual.get("texto", "")
		var candidatas = []
		for p in lista_preguntas:
			if p.get("texto", "") != texto_actual:
				candidatas.append(p)
				
		if candidatas.size() > 0:
			candidatas.shuffle()
			pregunta_actual = candidatas[0]
		else:
			lista_preguntas.shuffle()
			pregunta_actual = lista_preguntas[0]
			
		mostrar_pregunta()
	else:
		_cargar_pregunta_respaldo()

func _cargar_pregunta_respaldo():
	pregunta_actual = {
		"texto": "Un circuito en serie comparte la misma corriente en todos sus componentes.",
		"respuesta": true
	}
	mostrar_pregunta()

func mostrar_pregunta():
	if pantalla_acertijo and pregunta_actual.has("texto"):
		pantalla_acertijo.text = pregunta_actual["texto"]
		pantalla_acertijo.remove_theme_color_override("font_color")

func evaluar_respuesta(opcion_usuario: bool):
	if bloqueado:
		return
	bloqueado = true
	
	if boton_verdadero: boton_verdadero.disabled = true
	if boton_falso: boton_falso.disabled = true
	
	var respuesta_correcta = pregunta_actual.get("respuesta", true)
	var fue_acierto = (opcion_usuario == respuesta_correcta)
	var respuesta_texto = "Verdadero" if opcion_usuario else "Falso"
	
	# REGISTRO GLOBAL DE TELEMETRÍA
	if get_tree().root.has_node("GestorTelemetria"):
		GestorTelemetria.registrar_respuesta("Nivel_Sofia", fue_acierto, respuesta_texto)
	
	if fue_acierto:
		fallos_consecutivos = 0
		print("Resultado: ¡CORRECTO!")
		if sprite_carrito: sprite_carrito.texture = textura_encendido
		if typeof(Global) != TYPE_NIL and "suma_niveles" in Global:
			Global.suma_niveles += 1
		
		# GESTIÓN GLOBAL DE VIDAS: Restablece vidas a 3 al superar el carrito
		if get_tree().root.has_node("GestorVidas"):
			get_tree().root.get_node("GestorVidas").restablecer_a_tres()
			print("\n[¡ÉXITO CARRITO!] Carrito encendido. Vidas restauradas a 3.\n")
		
		await get_tree().create_timer(1.2).timeout
		reproducir_video_transicion()
	else:
		fallos_consecutivos += 1
		print("Resultado: ¡INCORRECTO!")
		
		# GESTIÓN GLOBAL DE VIDAS: Resta una vida
		var vidas_restantes = 0
		if get_tree().root.has_node("GestorVidas"):
			var gestor = get_tree().root.get_node("GestorVidas")
			gestor.restar_vida()
			vidas_restantes = gestor.vidas
			
		print("--------------------------------------------------")
		print(" [FALLO CARRITO] Ingresó: %s | Vidas restantes: %d / 3" % [respuesta_texto, vidas_restantes])
		print("--------------------------------------------------")
		
		# Efecto visual de fallo en el texto
		if pantalla_acertijo:
			pantalla_acertijo.text = "¡RESPUESTA INCORRECTA!"
			pantalla_acertijo.add_theme_color_override("font_color", Color.RED)
		
		# Si se agotaron las vidas, permanece bloqueado para que GestorVidas redirija al menú
		if vidas_restantes <= 0:
			return
			
		await get_tree().create_timer(1.5).timeout
		
		# Rota a una nueva pregunta tras 2 fallos consecutivos
		if fallos_consecutivos >= 2:
			fallos_consecutivos = 0
			_seleccionar_nueva_pregunta()
		else:
			mostrar_pregunta()
			
		if boton_verdadero: boton_verdadero.disabled = false
		if boton_falso: boton_falso.disabled = false
		bloqueado = false

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
