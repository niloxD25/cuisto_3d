extends Area3D

@export var window: Control
@export var container: VBoxContainer
@export var scroll_container: ScrollContainer
@export var oven_id: String = ""  # Ajoute l'export de l'oven_id avec une valeur par défaut

var http_request: HTTPRequest

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

func _on_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Bouton 3D cliqué !")
		perform_http_request()
		if window:
			window.visible = !window.visible

func perform_http_request():
	var url = "http://192.168.1.174:8000/api/admin/commandes/all"
	var error = http_request.request(url)
	if error != OK:
		print("Erreur de requête HTTP:", error)

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.new()
		var parse_error = json.parse(body.get_string_from_utf8())

		if parse_error == OK:
			var parsed_data = json.data
			update_ui(parsed_data)
		else:
			print("Erreur JSON:", json.get_error_message(), " Code: ", parse_error)
	else:
		print("Erreur HTTP: Code", response_code)

func update_ui(data):
	if not container:
		print("❌ Erreur : container est null.")
		return
	
	# Nettoyage du container
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

	# Ajout des commandes à l'UI
	for commande in data:
		if not commande.has("client") or not commande.has("dateCommande") or not commande.has("montantTotal") or not commande.has("status"):
			print("⚠️ Données de commande incomplètes :", commande)
			continue
		
		var client_email = commande["client"].get("email", "Inconnu")
		var date_commande = commande.get("dateCommande", "N/A")
		var montant_total = commande.get("montantTotal", 0)
		var status_commande = commande.get("status", "Inconnu")

		# Conteneur de la commande
		var commande_box = VBoxContainer.new()
		commande_box.add_theme_constant_override("separation", 10)
		
		# Titre de la commande
		var title_label = Label.new()
		title_label.text = "Commande de %s (%s) - %s Ar" % [client_email, date_commande, montant_total]
		title_label.add_theme_color_override("font_color", Color(0, 0.6, 1)) # Bleu plus sobre
		title_label.add_theme_font_size_override("font_size", 16)
		commande_box.add_child(title_label)

		# Vérifier si "details" existe et est une liste
		if not commande.has("details") or not commande["details"] is Array:
			print("⚠️ Aucune liste 'details' pour cette commande :", commande)
			continue

		# Détails des plats commandés
		for detail in commande["details"]:
			if not detail.has("plat") or not detail["plat"] is Dictionary:
				print("⚠️ Données du plat absentes ou invalides :", detail)
				continue
			
			var plat = detail["plat"]
			var nom_plat = plat.get("nomPlat", "Plat inconnu")
			var prix_unitaire = plat.get("prixUnitaire", "0.00")
			var temps_cuisson = plat.get("tempsCuisson", "N/A")
			var local_oven_id = plat.get("oven_id", oven_id)  # Utilise l'`oven_id` exporté si aucun n'est spécifié dans la commande

			# Conteneur horizontal pour le plat et le bouton
			var plat_row = HBoxContainer.new()
			plat_row.add_theme_constant_override("separation", 10)
			
			# Label pour le plat
			var plat_label = Label.new()
			plat_label.text = "🍽 %s - %s Ar (Cuisson : %s)" % [nom_plat, prix_unitaire, temps_cuisson]
			plat_label.add_theme_color_override("font_color", Color(1, 1, 1)) # Gris foncé
			plat_label.add_theme_font_size_override("font_size", 14)
			plat_row.add_child(plat_label)

			# Bouton "Choisir"
			var choisir_button = Button.new()
			choisir_button.text = "Choisir"
			choisir_button.add_theme_color_override("font_color", Color(1, 1, 1)) # Texte blanc
			choisir_button.add_theme_color_override("font_color_pressed", Color(0.9, 0.9, 0.9)) # Gris clair
			choisir_button.add_theme_stylebox_override("normal", create_button_style(Color(0.3, 0.3, 0.3))) # Gris neutre
			choisir_button.add_theme_stylebox_override("hover", create_button_style(Color(0.4, 0.4, 0.4))) # Gris clair
			choisir_button.add_theme_stylebox_override("pressed", create_button_style(Color(0.2, 0.2, 0.2))) # Gris foncé
			choisir_button.connect("pressed", Callable(self, "_on_choisir_pressed").bind(nom_plat, local_oven_id))
			plat_row.add_child(choisir_button)

			commande_box.add_child(plat_row)

		# Ajout de la commande au conteneur principal
		container.add_child(commande_box)

	# Mise à jour du scroll après ajout
	await get_tree().process_frame
	scroll_container.set_deferred("scroll_vertical", scroll_container.get_v_scroll_bar().max_value)

func create_button_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = Color(0.7, 0.7, 0.7) # Bordure légère gris clair
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	return style

func _on_choisir_pressed(nom_plat: String, oven_id: String):
	print("Plat choisi :", nom_plat, "Pour le four :", oven_id)
	var session = get_node("/root/Session")
	var success = session.add_dish_to_oven(oven_id, nom_plat)

	if success:
		print("Plat '%s' ajouté au four %s" % [nom_plat, oven_id])
	else:
		print("Échec de l'ajout du plat '%s' au four %s" % [nom_plat, oven_id])
