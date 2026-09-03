extends Control

# Pon el ID de tu proyecto aquí
var project_id = "lore-fepro" 
var respuesta_correcta = ""

func _ready():
	# Conectamos el nodo HTTP para saber cuándo termina la descarga
	$PeticionFirebase.request_completed.connect(_on_descarga_completada)
	$Label.text = "Descargando acertijo desde la IA..."
	
	# Iniciamos la descarga automáticamente al abrir la sala
	var url = "https://firestore.googleapis.com/v1/projects/" + project_id + "/databases/(default)/documents/salas_activas"
	$PeticionFirebase.request(url)

func _on_descarga_completada(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var datos = json.data
		
		# 1. Navegamos por la estructura de Firebase para sacar el primer documento
		var documento = datos["documents"][0]
		
		# 2. Extraemos el Acertijo 01 navegando por los Arrays y Maps de Firebase
		var acertijo_01 = documento["fields"]["acertijos"]["arrayValue"]["values"][0]["mapValue"]["fields"]
		
		var pregunta_texto = acertijo_01["pregunta_texto"]["stringValue"]
		respuesta_correcta = acertijo_01["respuesta_esperada"]["stringValue"]
		
		# 3. ¡Ponemos la pregunta en la pantalla del juego!
		$Label.text = pregunta_texto
	else:
		$Label.text = "Error al conectar con la base de datos."

# Esta función se activa cuando el jugador da clic en "Comprobar Respuesta"
func _on_button_pressed():
	# Tomamos lo que escribió el jugador y lo pasamos a minúsculas para evitar errores
	var texto_jugador = $LineEdit.text.strip_edges().to_lower()
	var respuesta_esperada = respuesta_correcta.to_lower()
	
	if texto_jugador == respuesta_esperada:
		$Label.text = "¡CORRECTO! Has resuelto el acertijo."
		$ColorRect.color = Color(0.2, 0.8, 0.2) # El pizarrón se pone verde
		
		# AQUÍ: En un futuro, llamaremos a GestorTelemetria para enviar la victoria
	else:
		$Label.text = "Respuesta incorrecta. Intenta de nuevo.\n" + respuesta_correcta # Muestra la respuesta para depuración
		$ColorRect.color = Color(0.8, 0.2, 0.2) # El pizarrón se pone rojo
