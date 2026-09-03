extends Node

var pregunta_vista = false
var pregunta_actual = ""
var opciones_cargadas = []
var indice_correcto = -1

# Lógica del cañón
var esferas_vistas = [false, false, false, false]
var intentos_restantes = 3

# --- DATOS PARA EL DASHBOARD ---
# Aquí guardaremos el histórico de toda la sesión (solo métricas pedagógicas)
var total_disparos = 0
var historial_errores = [] # Textos de las respuestas malas elegidas
var historial_aciertos = [] # Textos de las respuestas correctas elegidas
