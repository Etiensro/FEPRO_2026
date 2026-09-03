extends TextureRect

var opciones: Array = []
var indice_actual: int = 0
var raton_encima: bool = false
var animando: bool = false

@onready var label_valor: Label = $LabelValor if has_node("LabelValor") else ($Label if has_node("Label") else null)
@onready var label_auxiliar: Label = $LabelAuxiliar if has_node("LabelAuxiliar") else null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true # Evita que el texto flotante se salga del marco del rodillo
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(50, 210)
	
	_asegurar_labels()
	
	mouse_entered.connect(func(): raton_encima = true)
	mouse_exited.connect(func(): raton_encima = false)
	
	_mostrar_inmediato()

func _asegurar_labels() -> void:
	if label_valor == null:
		var labels = find_children("*", "Label", true, false)
		if labels.size() > 0:
			label_valor = labels[0]
			if labels.size() > 1:
				label_auxiliar = labels[1]
	
	if label_valor != null and label_auxiliar == null:
		label_auxiliar = label_valor.duplicate()
		label_auxiliar.name = "LabelAuxiliar"
		add_child(label_auxiliar)
	
	# Asegurar que el auxiliar SIEMPRE esté completamente oculto al inicio
	if label_auxiliar != null:
		label_auxiliar.visible = false
		label_auxiliar.modulate.a = 0.0
		label_auxiliar.text = ""

func configurar(conjunto_opciones: Array, valor_inicial: String = "") -> void:
	opciones = conjunto_opciones
	if valor_inicial in opciones:
		indice_actual = opciones.find(valor_inicial)
	else:
		indice_actual = 0
	
	_asegurar_labels()
	_mostrar_inmediato()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not animando:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_girar_cilindro(-1) # Hacia arriba
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_girar_cilindro(1)  # Hacia abajo

func _unhandled_key_input(event: InputEvent) -> void:
	if not raton_encima or not event.is_pressed() or event.is_echo() or animando:
		return
	
	if event.keycode == KEY_W or event.keycode == KEY_UP:
		_girar_cilindro(-1)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_S or event.keycode == KEY_DOWN:
		_girar_cilindro(1)
		get_viewport().set_input_as_handled()

func _mostrar_inmediato() -> void:
	_asegurar_labels()
	if not opciones.is_empty() and label_valor:
		label_valor.text = str(opciones[indice_actual])
		label_valor.position = Vector2.ZERO
		label_valor.modulate.a = 1.0
		label_valor.visible = true
		
	if label_auxiliar:
		label_auxiliar.text = ""
		label_auxiliar.visible = false
		label_auxiliar.modulate.a = 0.0

func _girar_cilindro(direccion: int) -> void:
	if opciones.is_empty() or animando:
		return
	
	_asegurar_labels()
	if label_valor == null:
		return

	animando = true
	var indice_siguiente = (indice_actual + direccion + opciones.size()) % opciones.size()
	
	if label_auxiliar != null:
		# 1. Preparar el auxiliar solo para la transición
		label_auxiliar.text = str(opciones[indice_siguiente])
		label_auxiliar.visible = true
		label_auxiliar.modulate.a = 1.0
		
		var alto_desplazamiento: float = size.y * 0.45
		var inicio_y_aux: float = alto_desplazamiento if direccion == -1 else -alto_desplazamiento
		var fin_y_actual: float = -alto_desplazamiento if direccion == -1 else alto_desplazamiento
		
		label_auxiliar.position = Vector2(0, inicio_y_aux)
		label_valor.position = Vector2.ZERO
		label_valor.modulate.a = 1.0
		
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
		# 2. Desplazar saliente
		tween.tween_property(label_valor, "position:y", fin_y_actual, 0.06)
		tween.tween_property(label_valor, "modulate:a", 0.0, 0.06)
		
		# 3. Introducir entrante al centro
		tween.tween_property(label_auxiliar, "position:y", 0.0, 0.06)
		tween.tween_property(label_auxiliar, "modulate:a", 1.0, 0.06)
		
		# Micro-efecto de compresión
		tween.tween_property(self, "scale", Vector2(1.04, 0.96), 0.03)
		tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.03)
		
		# 4. Al finalizar: fijar valor en label_valor y ocultar auxiliar por completo
		tween.chain().tween_callback(func():
			indice_actual = indice_siguiente
			label_valor.text = str(opciones[indice_actual])
			label_valor.position = Vector2.ZERO
			label_valor.modulate.a = 1.0
			
			label_auxiliar.text = ""
			label_auxiliar.visible = false
			label_auxiliar.modulate.a = 0.0
			
			animando = false
		)
	else:
		indice_actual = indice_siguiente
		label_valor.text = str(opciones[indice_actual])
		animando = false

func obtener_valor() -> String:
	return str(opciones[indice_actual]) if not opciones.is_empty() else ""
