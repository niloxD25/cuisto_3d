extends Area3D

@export var window: Control
@export var container: VBoxContainer
@export var scroll_container: ScrollContainer
@export var oven_id: String = ""  # Ajoute l'export de l'oven_id avec une valeur par défaut

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

	# Initialiser le label d'erreur
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
	var url = baseUrl + "/admin/commandes/all"
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
	if not container:
		show_error_message("❌ Erreur : container est null.")
		return

	# Nettoyage du container
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

	# Ajout d'un espace vide en haut
	var espace_vide = Control.new()
	espace_vide.custom_minimum_size = Vector2(10, 20)  # Crée un espace
	container.add_child(espace_vide)

	# Ajout des commandes à l'UI
	for commande in data:
		if not commande.has("client") or not commande.has("dateCommande") or not commande.has("montantTotal") or not commande.has("status"):
			show_error_message("⚠️ Données de commande incomplètes.")
			continue

		var client_email = commande["client"].get("email", "Inconnu")
		var date_commande = commande.get("dateCommande", "N/A")
		var montant_total = commande.get("montantTotal", 0)

		# Conteneur de la commande
		var commande_box = VBoxContainer.new()
		commande_box.add_theme_constant_override("separation", 10)

		# Titre de la commande
		var title_label = Label.new()
		title_label.text = "Commande de %s (%s) - %s Ar" % [client_email, date_commande, montant_total]
		title_label.add_theme_color_override("font_color", Color(0, 0.6, 1))  # Bleu sobre
		title_label.add_theme_font_size_override("font_size", 16)
		commande_box.add_child(title_label)

		# Vérifier si "details" existe et est une liste
		if not commande.has("details") or not commande["details"] is Array:
			show_error_message("⚠️ Aucune liste 'details' pour cette commande.")
			continue

		# Détails des plats commandés
		for detail in commande["details"]:
			if not detail.has("plat") or not detail["plat"] is Dictionary:
				show_error_message("⚠️ Données du plat absentes ou invalides.")
				continue

			var idDetail = detail["plat"].get("id", 0)
			var plat = detail["plat"]
			var nom_plat = plat.get("nomPlat", "Plat inconnu")
			var prix_unitaire = plat.get("prixUnitaire", "0.00")
			var temps_cuisson = plat.get("tempsCuisson", "N/A")
			var local_oven_id = plat.get("oven_id", oven_id)  # Utilise l'`oven_id` exporté si aucun n'est spécifié

			# Conteneur du plat
			var plat_box = HBoxContainer.new()  # Changé en HBoxContainer pour aligner l'image et le texte
			plat_box.add_theme_constant_override("separation", 10)

			# Ajouter l'image du plat
			var image = Image.load_from_file("res://images/plat.png")
			image.resize(100, 100, Image.INTERPOLATE_LANCZOS)  # Redimensionne l'image à 50x50 pixels
			var image_texture = ImageTexture.create_from_image(image)

			var texture = TextureRect.new()
			texture.texture = image_texture
			texture.custom_minimum_size = Vector2(100, 100)
			plat_box.add_child(texture)

			# Conteneur pour les informations du plat
			var plat_info_box = VBoxContainer.new()
			plat_info_box.add_theme_constant_override("separation", 5)

			# Label pour le plat
			var plat_label = Label.new()
			plat_label.text = "%s - %s Ar (Cuisson : %s)" % [nom_plat, prix_unitaire, temps_cuisson]
			plat_label.add_theme_color_override("font_color", Color(1, 1, 1))  # Blanc
			plat_label.add_theme_font_size_override("font_size", 14)
			plat_info_box.add_child(plat_label)

			# Vérifier si "ingredients" existe et est une liste
			var ingredients_list = plat.get("ingredients", [])
			if ingredients_list is Array and ingredients_list.size() > 0:
				var ingredients_title = Label.new()
				ingredients_title.text = "Ingrédients :"
				ingredients_title.add_theme_color_override("font_color", Color(1, 0.5, 0))  # Orange
				ingredients_title.add_theme_font_size_override("font_size", 13)
				plat_info_box.add_child(ingredients_title)

				for ingredient in ingredients_list:
					var nom_ingredient = ingredient.get("nomIngredient", "Ingrédient inconnu")
					var quantite = ingredient.get("quantite", "0")

					var ingredient_label = Label.new()
					ingredient_label.text = "- %s (x%s)" % [nom_ingredient, quantite]
					ingredient_label.add_theme_color_override("font_color", Color(1, 1, 1))  # Blanc
					ingredient_label.add_theme_font_size_override("font_size", 12)
					plat_info_box.add_child(ingredient_label)

			# Bouton "Choisir"
			var choisir_button = Button.new()
			choisir_button.text = "Choisir"
			choisir_button.add_theme_color_override("font_color", Color(1, 1, 1))
			choisir_button.add_theme_color_override("font_color_pressed", Color(0.9, 0.9, 0.9))
			choisir_button.add_theme_stylebox_override("normal", create_button_style(Color(0.3, 0.3, 0.3)))

			var plat_id = plat.get("id", 0)
			choisir_button.connect("pressed", Callable(self, "_on_choisir_pressed").bind(plat_id, ingredients_list, local_oven_id, idDetail))
			plat_info_box.add_child(choisir_button)

			# Ajouter les informations du plat à la boîte du plat
			plat_box.add_child(plat_info_box)

			# Ajouter l'ensemble à la commande
			commande_box.add_child(plat_box)

		# Ajout de la commande au conteneur principal
		container.add_child(commande_box)

	# Mise à jour du scroll après ajout
	await get_tree().process_frame
	#scroll_container.set_deferred("scroll_vertical", scroll_container.get_v_scroll_bar().max_value)

func create_button_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = Color(0.7, 0.7, 0.7)
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	return style

func _on_choisir_pressed(plat_id: int, ingredients: Array, oven_id: String, idDetail: int):
	print("Plat choisi : ID =", plat_id, "Pour le four :", oven_id, "Ingrédients :", ingredients)
	var session = get_node("/root/Session")
	var success = session.add_dish_to_oven(oven_id, plat_id, ingredients, idDetail)

	if success:
		print("✅ Plat ID '%s' ajouté au four %s" % [plat_id, oven_id])
	else:
		show_error_message("⚠️ Impossible d'ajouter le plat ID '%s' au four %s" % [plat_id, oven_id])

func show_error_message(message: String):
	if error_label and is_instance_valid(error_label):
		error_label.text = "❌ " + message
		error_label.visible = true
		await get_tree().create_timer(3.0).timeout
		
		if is_instance_valid(error_label):  # Vérification avant d'accéder à error_label
			error_label.visible = false
