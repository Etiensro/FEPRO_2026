extends Node

var http_request: HTTPRequest
var project_id = "lore-fepro"

func _ready():
	# Creamos el nodo que hace las peticiones a internet
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

# Función para enviar un reporte a la colección telemetria_resultados
func enviar_reporte_prueba(alumno: String, estado: String):
	var url = "https://firestore.googleapis.com/v1/projects/" + project_id + "/databases/(default)/documents/telemetria_resultados"
	var headers = ["Content-Type: application/json"]
	
	# Estructuramos el JSON tal como Firestore lo pide
	var cuerpo = {
		"fields": {
			"alumno_id": { "stringValue": alumno },
			"estado_final": { "stringValue": estado }
		}
	}
	
	var json_string = JSON.stringify(cuerpo)
	
	print("Enviando datos a Firebase...")
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)

func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		print("¡Éxito! El documento se creó en Firestore. Revisa tu navegador.")
	else:
		print("Error en la conexión. Código: ", response_code)
		print("Detalle: ", body.get_string_from_utf8())

# Desempaquetador mágico para entender la estructura loca de Firestore
func unwrap_firestore(val: Dictionary):
	if val.has("stringValue"): return val["stringValue"]
	if val.has("integerValue"): return int(val["integerValue"])
	if val.has("doubleValue"): return float(val["doubleValue"])
	if val.has("booleanValue"): return val["booleanValue"]
	if val.has("arrayValue"):
		var arr = []
		if val["arrayValue"].has("values"):
			for v in val["arrayValue"]["values"]:
				arr.append(unwrap_firestore(v))
		return arr
	if val.has("mapValue"):
		var map = {}
		if val["mapValue"].has("fields"):
			for k in val["mapValue"]["fields"].keys():
				map[k] = unwrap_firestore(val["mapValue"]["fields"][k])
		return map
	return null
