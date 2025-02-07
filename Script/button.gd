extends Node3D

@export var window: Control  # La fenêtre à afficher

func _ready():
	connect("input_event", _on_input_event)

func _on_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if window:
			window.visible = !window.visible  # Afficher/Masquer la fenêtre
