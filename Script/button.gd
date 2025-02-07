extends Area3D

@export var window: Control  # La fenêtre à afficher
var label: Label  # Référence vers le label pour afficher les données reçues

var http_request : HTTPRequest

func _ready():
	# Récupérer dynamiquement le Label s'il est un enfant de window
	if window:
		label = window.get_node("Label")  # Assurez-vous que le nom du nœud est "Label"
	# Créer une instance de HTTPRequest
	http_request = HTTPRequest.new()
	# Ajouter HTTPRequest au Node (obligatoire pour fonctionner)
	add_child(http_request)
	
	# Connecter l'événement de clic (à la méthode _on_input_event)
	connect("input_event", Callable(self, "_on_input_event"))  # Utilisation de Callable
	
	# Connecter le signal request_completed à la méthode de gestion
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))

func _on_input_event(camera, event, position, normal, shape_idx):
	# Vérifie si le clic est effectué sur l'objet 3D
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Bouton 3D cliqué !")
		# Effectuer la requête HTTP
		perform_http_request()
		# Afficher/Masquer la fenêtre
		if window:
			window.visible = !window.visible

func perform_http_request():
	# URL de l'API ou de la ressource à récupérer
	var url = "http://192.168.1.173:8000/api/admin/stocks/all"  # Remplace par l'URL réelle
	# Effectuer la requête HTTP (GET par défaut)
	var error = http_request.request(url)
	if error != OK:
		print("Erreur de requête HTTP:", error)
		return

func _on_request_completed(result, response_code, headers, body):
	# Vérifie si la requête a réussi (code 200)
	if response_code == 200:
		# Créer une instance de JSON pour parser les données
		var json = JSON.new()
		var parse_error = json.parse(body.get_string_from_utf8())

		if parse_error == OK:
			var parsed_data = json.data  # Récupération des données JSON analysées
			label.text = str(parsed_data)  # Afficher les données reçues dans le label
		else:
			print("Erreur de parsing JSON:", json.get_error_message(), " Code: ", parse_error)
			
	else:
		print("Erreur de la requête HTTP: Code ", response_code)
