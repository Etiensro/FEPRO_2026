extends Control

var project_id = "lore-fepro"

func _on_button_pressed():
	GestorTelemetria.enviar_reporte_prueba("jugador_001", "sala_completada")

func _ready():
	# Conectamos la señal del nodo HTTPRequest para saber cuando termine de descargar
	$PeticionDescarga.request_completed.connect(_on_descarga_completada)


func _on_boton_descargar_pressed():
	print("Conectando a Firebase para buscar acertijos...")
	var url = "https://firestore.googleapis.com/v1/projects/" + project_id + "/databases/(default)/documents/salas_activas"
	$PeticionDescarga.request(url)

# Se activa cuando Firebase nos entrega el documento
func _on_descarga_completada(result, response_code, headers, body):
	if response_code == 200:
		print("¡Descarga exitosa! Procesando JSON...")
		
		# Convertimos el texto que llega de internet a un formato que Godot entienda
		var json = JSON.new()
		var error = json.parse(body.get_string_from_utf8())
		
		if error == OK:
			var datos = json.data
			
			print("====================================")
			print(datos)
			print("====================================")
		else:
			print("Hubo un error al traducir el JSON.")
	else:
		print("Error en la descarga. Código HTTP: ", response_code)
