extends Area3D

@export var window: Control
@export var container: VBoxContainer
@export var scroll_container: ScrollContainer

var http_request: HTTPRequest
var error_label: Label  # Label pour afficher les erreurs

var baseUrl = "https://restaurantapi-524bf01f495e.herokuapp.com/api"

func _ready():
	if not window:
		window = get_parent().get_node_or_null("Control")
		
	if window:
		scroll_container = window.get_node("ScrollContainer")
		container = scroll_container.get_node("VBoxContainer")

	http_request = HTTPRequest.new()
	add_child(http_request)

	connect("input_event", Callable(self, "_on_input_event"))
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))

	# Création du label d'erreur en haut de la liste
	if not container.has_node("ErrorLabel"):
		error_label = Label.new()
		error_label.name = "ErrorLabel"
		error_label.visible = false  # Caché par défaut
		error_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Rouge
		error_label.add_theme_font_size_override("font_size", 14)
		container.add_child(error_label)  # Ajout au container
	else:
		error_label = container.get_node("ErrorLabel")

func _on_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Bouton 3D cliqué !")
		perform_http_request()
		if window:
			window.visible = !window.visible

func perform_http_request():
	var url = baseUrl + "/admin/stocks/all"
	var error = http_request.request(url)
	if error != OK:
		show_error_message("Erreur de requête HTTP: " + str(error))

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		var parse_error = json.parse(body.get_string_from_utf8())

		if parse_error == OK:
			var parsed_data = json.data
			update_ui(parsed_data)
		else:
			show_error_message("Erreur JSON: " + json.get_error_message())
	else:
		show_error_message("Erreur HTTP: Code " + str(response_code))

func update_ui(data):
	# Nettoyage du container
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

	# Ajout d'un espace vide en haut pour éviter que l'erreur ne cache les données
	var empty_space = Control.new()
	empty_space.custom_minimum_size = Vector2(10, 20)  # Espace vide
	container.add_child(empty_space)

	# Affichage des ingrédients
	for item in data:
		var ingredient = item["ingredient"]
		var quantite = item["quantite"]
		add_ingredient_to_ui(ingredient["id"], ingredient["nomIngredient"], ingredient["nomImage"], quantite)

	await get_tree().process_frame
	#scroll_container.set_deferred("scroll_vertical", scroll_container.get_v_scroll_bar().max_value)

func add_ingredient_to_ui(ingredient_id, nom, image_path, quantite):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var image = Image.load_from_file("res://images/" + image_path)
	image.resize(35, 35, Image.INTERPOLATE_LANCZOS)  # Redimensionne l'image à 50x50 pixels
	var image_texture = ImageTexture.create_from_image(image)

	var texture = TextureRect.new()
	texture.texture = image_texture
	texture.custom_minimum_size = Vector2(30, 30)

	var name_label = Label.new()
	name_label.text = nom
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))

	var qty_label = Label.new()
	qty_label.text = "x" + str(quantite)
	qty_label.add_theme_color_override("font_color", Color(1, 0.5, 0))

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var input = LineEdit.new()
	input.text = "1"
	input.custom_minimum_size = Vector2(50, 30)
	input.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_CENTER)

	var plus_button = Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(30, 30)
	plus_button.connect("pressed", Callable(self, "_on_plus_pressed").bind(input, qty_label, quantite))

	var minus_button = Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(30, 30)
	minus_button.connect("pressed", Callable(self, "_on_minus_pressed").bind(input))

	var take_button = Button.new()
	take_button.text = "Prendre"
	take_button.custom_minimum_size = Vector2(80, 30)
	take_button.connect("pressed", Callable(self, "_on_take_pressed").bind(ingredient_id, input, qty_label, quantite))

	hbox.add_child(texture)
	hbox.add_child(name_label)
	hbox.add_child(qty_label)
	hbox.add_child(spacer)
	hbox.add_child(minus_button)
	hbox.add_child(input)
	hbox.add_child(plus_button)
	hbox.add_child(take_button)

	container.add_child(hbox)

# Gestion des boutons
func _on_plus_pressed(input, qty_label, max_qty):
	var current_qty = int(input.text)
	if current_qty < max_qty:
		input.text = str(current_qty + 1)

func _on_minus_pressed(input):
	var current_qty = int(input.text)
	if current_qty > 1:
		input.text = str(current_qty - 1)

# 📌 Gestion des retraits et MAJ de la session
func _on_take_pressed(ingredient_id, input, qty_label, max_qty):
	var quantite = int(input.text)
	var stock_disponible = int(qty_label.text.replace("x", ""))

	if quantite > stock_disponible:
		show_error_message("⚠️ Quantité demandée supérieure au stock disponible !")
		return

	if quantite > 0:
		Session.add_withdrawal(ingredient_id, quantite)  # Enregistrement en session
		qty_label.text = "x" + str(stock_disponible - quantite)
		print("✅ Retrait enregistré. Session actuelle :", Session.get_withdrawals())
	else:
		show_error_message("⚠️ Aucune quantité disponible pour " + str(ingredient_id))

# 📌 Fonction pour afficher les erreurs
func show_error_message(message: String):
	if error_label and is_instance_valid(error_label):
		error_label.text = "❌ " + message
		error_label.visible = true
		await get_tree().create_timer(3.0).timeout  # Disparition après 3 sec
		
		if is_instance_valid(error_label):  # Vérification avant d'accéder à error_label
			error_label.visible = false
