extends Node

var http_request: HTTPRequest
var project_id = "lore-fepro"

func _ready():
	# Creamos el nodo que hace las peticiones a internet
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

# ==========================================
# OBRA MAESTRA: CONEXIÓN DE DESCARGA GLOBAL
# ==========================================
signal preguntas_listas(preguntas_array)

func descargar_preguntas(etiqueta_nivel: String):
	print("Descargando preguntas globales para: ", etiqueta_nivel)
	var http_descarga = HTTPRequest.new()
	add_child(http_descarga)
	
	# Usamos una función anónima (Lambda) para procesar el resultado de forma independiente
	http_descarga.request_completed.connect(func(_res, code, _headers, body):
		if code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			var array_final = []
			
			if json.has("documents"):
				for doc in json["documents"]:
					var fields = doc["fields"]
					var nivel_datos = {}
					for k in fields.keys():
						nivel_datos[k] = unwrap_firestore(fields[k])
					
					if nivel_datos.has(etiqueta_nivel):
						array_final = nivel_datos[etiqueta_nivel]
						break
			
			preguntas_listas.emit(array_final)
		else:
			print("Error al descargar preguntas: ", code)
			preguntas_listas.emit([]) # Enviar array vacío si hay error
			
		http_descarga.queue_free() # Borrar el nodo temporal
	)
	
	var url = "https://firestore.googleapis.com/v1/projects/" + project_id + "/databases/(default)/documents/salas_activas"
	http_descarga.request(url)

# Función para enviar los resultados pedagógicos a Firebase
func enviar_reporte_final(alumno: String, estado: String, disparos: int, aciertos: Array, errores: Array):
	var url = "https://firestore.googleapis.com/v1/projects/" + project_id + "/databases/(default)/documents/telemetria_resultados"
	var headers = ["Content-Type: application/json"]
	
	# Firestore requiere que los arrays se estructuren de esta forma
	var array_errores = []
	for e in errores:
		array_errores.append({"stringValue": e})
		
	var array_aciertos = []
	for a in aciertos:
		array_aciertos.append({"stringValue": a})
	
	var cuerpo = {
		"fields": {
			"alumno_id": { "stringValue": alumno },
			"estado_final": { "stringValue": estado },
			"total_disparos": { "integerValue": str(disparos) },
			"historial_aciertos": { "arrayValue": { "values": array_aciertos } },
			"historial_errores": { "arrayValue": { "values": array_errores } }
		}
	}
	
	var json_string = JSON.stringify(cuerpo)
	
	print("Enviando resultados de Melyssa a Firebase Dashboard...")
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
