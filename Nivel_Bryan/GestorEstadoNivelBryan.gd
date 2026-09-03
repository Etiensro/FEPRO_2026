extends Node

# --- PUZZLE 1: CILINDROS (RODILLOS) ---
var cilindros_resuelto: bool = false
var cilindros_id_actual: String = ""
var cilindros_pregunta_guardada: String = ""
var cilindros_valores_guardados: Array = []
var cilindros_tipo_guardado: String = "numeros"

# --- PUZZLE 2: LÁSER (OPTICA) ---
var laser_resuelto: bool = false
var laser_lente_ganador: String = ""
var laser_pregunta_guardada: String = ""
var laser_posiciones_hojas: Array = []
var laser_texturas_hojas: Array = []
var laser_incisos_guardados: Array = []
var laser_idx_ganador: int = -1
var laser_datos_activos: Dictionary = {}
