extends Control

func _on_button_pressed():
	# Llamamos al Singleton pasándole datos de prueba
	GestorTelemetria.enviar_reporte_prueba("jugador_001", "sala_completada")
