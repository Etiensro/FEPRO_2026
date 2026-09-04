extends Node

var http_request: HTTPRequest
var project_id: String = "lore-fepro"

# --- DATOS DE SESIÓN DEL MENÚ PRINCIPAL ---
var alumno_id: String = ""
var codigo_sala: String = ""
var datos_sala_actual: Dictionary = {}

# --- ACUMULADORES GLOBALES DE TELEMETRÍA ---
var total_intentos: int = 0
var historial_aciertos: Array = []
var historial_errores: Array = []

signal preguntas_listas(preguntas_array)

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

# Reinicia la telemetría al iniciar una partida nueva desde el menú
func reiniciar_telemetria() -> void:
	total_intentos = 0
	historial_aciertos.clear()
	historial_errores.clear()

# Llamar desde cualquier nivel al registrar un intento (acierto o fallo)
func registrar_respuesta(_id_nivel: String, es_acierto: bool, detalle: String) -> void:
	total_intentos += 1
	if es_acierto:
		historial_aciertos.append(detalle)
	else:
		historial_errores.append(detalle)

# Descarga de preguntas de la sala activa en Firestore
func descargar_preguntas(etiqueta_nivel: String) -> void:
	if codigo_sala == "":
		print("Error crítico: El código de sala está vacío.")
		preguntas_listas.emit([])
		return
		
	print("Descargando preguntas de la sala ", codigo_sala, " para: ", etiqueta_nivel)
	var http_descarga = HTTPRequest.new()
	add_child(http_descarga)
	
	http_descarga.request_completed.connect(func(_res: int, code: int, _headers: PackedStringArray, body: PackedByteArray):
		if code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			var array_final = []
			
			if json != null and json.has("fields"):
				var campos = json["fields"]
				var datos_crudos = {}
				for k in campos.keys():
					datos_crudos[k] = unwrap_firestore(campos[k])
				
				if datos_crudos.has("preguntas"):
					var diccionario_preguntas = datos_crudos["preguntas"]
					if diccionario_preguntas.has(etiqueta_nivel):
						var dato_crudo = diccionario_preguntas[etiqueta_nivel]
						if typeof(dato_crudo) == TYPE_ARRAY:
							array_final = dato_crudo
						else:
							array_final = [dato_crudo]
			
			preguntas_listas.emit(array_final)
		else:
			print("Error al descargar preguntas: ", code)
			preguntas_listas.emit([])
			
		http_descarga.queue_free()
	)
	
	var url = "https://firestore.googleapis.com/v1/projects/" + project_id + "/databases/(default)/documents/salas_activas/" + codigo_sala.to_upper()
	http_descarga.request(url)

# SUBIDA FINAL: Guarda el documento como codigodesesion_idjugador usando PATCH
func enviar_reporte_acumulado(estado: String = "victoria") -> void:
	# 1. Asegurar código de sala e ID del alumno limpios
	var sala_limpia = codigo_sala.strip_edges().to_upper()
	if sala_limpia == "":
		sala_limpia = "SIN_SALA"

	var id_base = alumno_id.strip_edges()
	if id_base == "":
		id_base = "anonimo_" + str(Time.get_unix_time_from_system())

	# 2. Formato: codigodesesion_idjugador
	var nombre_compuesto = "%s_%s" % [sala_limpia, id_base]
	var id_doc_url = nombre_compuesto.replace(" ", "_").uri_encode()

	# 3. La URL usa el nombre compuesto como ID del documento en Firestore
	var url = "https://firestore.googleapis.com/v1/projects/" + project_id + "/databases/(default)/documents/telemetria_resultados/" + id_doc_url
	var headers = ["Content-Type: application/json"]
	
	var array_aciertos_fs = []
	for a in historial_aciertos:
		array_aciertos_fs.append({"stringValue": str(a)})
		
	var array_errores_fs = []
	for e in historial_errores:
		array_errores_fs.append({"stringValue": str(e)})
	
	# Estructura del documento
	var cuerpo = {
		"fields": {
			"alumno_id": { "stringValue": id_base },
			"codigo_sala": { "stringValue": sala_limpia },
			"estado_final": { "stringValue": estado },
			"historial_aciertos": { "arrayValue": { "values": array_aciertos_fs } },
			"historial_errores": { "arrayValue": { "values": array_errores_fs } },
			"total_intentos": { "stringValue": str(total_intentos) }
		}
	}
	
	var json_string = JSON.stringify(cuerpo)
	print("Subiendo telemetría consolidada a telemetria_resultados/" + id_doc_url + "...")
	
	# METHOD_PATCH crea o sobrescribe el documento con ese ID exacto
	var err = http_request.request(url, headers, HTTPClient.METHOD_PATCH, json_string)
	if err != OK:
		print("Error local HTTP al enviar reporte final: ", err)

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code in [200, 204]:
		print("¡Éxito! Documento guardado como [codigodesesion_idjugador] en telemetria_resultados.")
	else:
		print("Error en Firestore. Código: ", response_code, " | Respuesta: ", body.get_string_from_utf8())

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
