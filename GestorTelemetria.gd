extends Node

var http_request: HTTPRequest
var project_id = "lore-fepro"

# --- DATOS DE SESIÓN DEL MENÚ PRINCIPAL ---
var alumno_id: String = ""
var codigo_sala: String = ""
var datos_sala_actual: Dictionary = {}

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
	if codigo_sala == "":
		print("Error crítico: El código de sala está vacío.")
		preguntas_listas.emit([])
		return
		
	print("Descargando preguntas de la sala ", codigo_sala, " para: ", etiqueta_nivel)
	var http_descarga = HTTPRequest.new()
	add_child(http_descarga)
	
	http_descarga.request_completed.connect(func(_res, code, _headers, body):
		if code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			var array_final = []
			
			if json.has("fields"):
				var campos = json["fields"]
				var datos_crudos = {}
				for k in campos.keys():
					datos_crudos[k] = unwrap_firestore(campos[k])
				
				# Navegamos dentro del diccionario "preguntas" que generó app.py
				if datos_crudos.has("preguntas"):
					var diccionario_preguntas = datos_crudos["preguntas"]
					if diccionario_preguntas.has(etiqueta_nivel):
						var dato_crudo = diccionario_preguntas[etiqueta_nivel]
						if typeof(dato_crudo) == TYPE_ARRAY:
							array_final = dato_crudo
						else:
							array_final = [dato_crudo] # Forzamos a que sea un Array
			
			preguntas_listas.emit(array_final)
		else:
			print("Error al descargar preguntas: ", code)
			preguntas_listas.emit([])
			
		http_descarga.queue_free()
	)
	
	# Ahora la URL apunta DIRECTAMENTE al documento de la sala que ingresó el jugador
	var url = "https://firestore.googleapis.com/v1/projects/" + project_id + "/databases/(default)/documents/salas_activas/" + codigo_sala.to_upper()
	http_descarga.request(url)

# Función adaptada para la telemetría unificada (Fricción vs Dominio)
func enviar_reporte_final(intentos_totales: int, aciertos: Array, errores: Array):
	var url = "https://firestore.googleapis.com/v1/projects/" + project_id + "/databases/(default)/documents/telemetria_resultados"
	var headers = ["Content-Type: application/json"]
	
	var array_errores = []
	for e in errores:
		array_errores.append({"stringValue": str(e)})
		
	var array_aciertos = []
	for a in aciertos:
		array_aciertos.append({"stringValue": str(a)})
	
	var cuerpo = {
		"fields": {
			"alumno_id": { "stringValue": alumno_id },
			# Mantenemos "victoria" fijo para que no se rompan las gráficas visuales del dashboard web
			"estado_final": { "stringValue": "victoria" },
			# El dashboard espera la llave "total_disparos", aquí inyectamos los "intentos_totales"
			"total_disparos": { "integerValue": str(intentos_totales) },
			"historial_aciertos": { "arrayValue": { "values": array_aciertos } },
			"historial_errores": { "arrayValue": { "values": array_errores } }
		}
	}
	
	var json_string = JSON.stringify(cuerpo)
	print("Enviando resultados de ", alumno_id, " a Firebase Dashboard...")
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)

func _on_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		print("¡Éxito! Telemetría enviada a Firestore.")
	else:
		print("Error en la conexión. Código: ", response_code)

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
