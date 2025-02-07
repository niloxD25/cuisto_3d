extends Area3D

@export var window: Control  # Fenêtre principale
@export var container: VBoxContainer  # Conteneur pour afficher les ingrédients
@export var scroll_container: ScrollContainer  # Conteneur avec scroll

var http_request: HTTPRequest

func _ready():
	if window:
		scroll_container = window.get_node("ScrollContainer")  # Récupération dynamique
		container = scroll_container.get_node("VBoxContainer")  # Récupération du VBoxContainer
	# Créer une instance de HTTPRequest
	http_request = HTTPRequest.new()
	add_child(http_request)

	# Connecter le signal de clic
	connect("input_event", Callable(self, "_on_input_event"))
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))

func _on_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Bouton 3D cliqué !")
		perform_http_request()
		if window:
			window.visible = !window.visible

func perform_http_request():
	var url = "http://192.168.1.173:8000/api/admin/stocks/all"
	var error = http_request.request(url)
	if error != OK:
		print("Erreur de requête HTTP:", error)
		return

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		var parse_error = json.parse(body.get_string_from_utf8())

		if parse_error == OK:
			var parsed_data = json.data
			update_ui(parsed_data)
		else:
			print("Erreur de parsing JSON:", json.get_error_message(), " Code: ", parse_error)
	else:
		print("Erreur de la requête HTTP: Code ", response_code)

func update_ui(data):
	# Nettoyer les anciens éléments
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()  # Détruire les anciens éléments

	# Ajouter les nouveaux éléments
	for item in data:
		var ingredient = item["ingredient"]
		var quantite = item["quantite"]
		add_ingredient_to_ui(ingredient["nomIngredient"], ingredient["nomImage"], quantite)

	# **Forcer le scroll en bas après mise à jour**
	await get_tree().process_frame  # Attendre un frame pour l'affichage
	scroll_container.set_deferred("scroll_vertical", scroll_container.get_v_scroll_bar().max_value)

func add_ingredient_to_ui(nom, image_path, quantite):
	# Créer un HBoxContainer
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Charger l'image
	var texture = TextureRect.new()
	texture.texture = load("res://images/" + image_path)  # Assurez-vous que les images sont bien dans ce dossier
	texture.custom_minimum_size = Vector2(50, 50)

	# Créer les labels
	var name_label = Label.new()
	name_label.text = nom
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))  # Blanc

	var qty_label = Label.new()
	qty_label.text = "x" + str(quantite)
	qty_label.add_theme_color_override("font_color", Color(1, 0.5, 0))  # Orange

	# Bouton +
	var plus_button = Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(30, 30)
	plus_button.connect("pressed", Callable(self, "_on_plus_pressed").bind(qty_label))

	# Bouton -
	var minus_button = Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(30, 30)
	minus_button.connect("pressed", Callable(self, "_on_minus_pressed").bind(qty_label))

	# Bouton "Prendre"
	var take_button = Button.new()
	take_button.text = "Prendre"
	take_button.custom_minimum_size = Vector2(80, 30)
	take_button.connect("pressed", Callable(self, "_on_take_pressed").bind(nom, qty_label))

	# Ajouter les éléments au HBox
	hbox.add_child(texture)
	hbox.add_child(name_label)
	hbox.add_child(qty_label)
	hbox.add_child(minus_button)
	hbox.add_child(plus_button)
	hbox.add_child(take_button)

	# Ajouter le HBox au conteneur
	container.add_child(hbox)

# Gestion des boutons
func _on_plus_pressed(qty_label):
	var current_qty = int(qty_label.text.replace("x", ""))
	qty_label.text = "x" + str(current_qty + 1)

func _on_minus_pressed(qty_label):
	var current_qty = int(qty_label.text.replace("x", ""))
	if current_qty > 0:
		qty_label.text = "x" + str(current_qty - 1)

func _on_take_pressed(nom, qty_label):
	var quantite = int(qty_label.text.replace("x", ""))
	if quantite > 0:
		print("Vous avez pris", quantite, "de", nom)
	else:
		print("Aucune quantité disponible pour", nom)
