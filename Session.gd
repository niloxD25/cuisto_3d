extends Node

var withdrawn_items = {}  # Stockage global des ingrédients retirés
var oven_dishes = {}  # Stockage des plats dans chaque four (StaticBody3D)
var ingredients = {}
var plat_id: int
var error_label: Label  # Label pour afficher les erreurs
var http_request: HTTPRequest  # Pour effectuer des requêtes HTTP
var baseUrl = "https://restaurantapi-524bf01f495e.herokuapp.com/api"

func _ready():
	# Vérifie si un label d'erreur global existe dans la scène
	var root = get_tree().get_root()
	if root.has_node("ErrorLabel"):
		error_label = root.get_node("ErrorLabel")
	else:
		error_label = Label.new()
		error_label.name = "ErrorLabel"
		error_label.visible = false
		error_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Rouge	
		error_label.add_theme_font_size_override("font_size", 14)

		# Utilisation de call_deferred pour éviter le problème d'ajout trop tôt
		root.call_deferred("add_child", error_label)

	# Initialisation de la requête HTTP
	http_request = HTTPRequest.new()
	add_child(http_request)

# Fonction pour effectuer une requête PUT
func update_detail_plat(idDetailMenu: int, status: String, dateHeureFini: String):
	var url = baseUrl + "/plat/update"  # L'URL de l'API à modifier
	var json_data = {
		"idDetailMenu": idDetailMenu,
		"status": status,
		"dateHeureFini": dateHeureFini
	}

	# Convertir les données en JSON
	var json_string = JSON.stringify(json_data)

	# Effectuer la requête PUT avec le corps en JSON
	var headers = ["Content-Type: application/json"]
	var error = http_request.request(url, headers, HTTPClient.METHOD_PUT, json_string)
	if error != OK:
		show_error_message("Erreur lors de l'envoi de la requête PUT: " + str(error))


# Update stock
func update_stock_ingredient(idIngredient: int, status: String, quantite: int, dateHeure: String):
	var url = baseUrl + "/plat/update"  # L'URL de l'API à modifier
	var json_data = {
		"idIngredient": idIngredient,
		"status": status,
		"quantite": quantite,
		"dateHeure": dateHeure
	}

	# Convertir les données en JSON
	var json_string = JSON.stringify(json_data)

	# Effectuer la requête POST avec le corps en JSON
	var headers = ["Content-Type: application/json"]
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)
	if error != OK:
		show_error_message("Erreur lors de l'envoi de la requête POST: " + str(error))

# Fonction pour gérer la réponse de la requête POST
func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		print("✅ Requête POST réussie.")
	else:
		show_error_message("Erreur lors de l'actualisation. Code réponse: " + str(response_code))

# Ajoute un retrait d'ingrédient
func add_withdrawal(ingredient_id, quantite):
	if ingredient_id in withdrawn_items:
		withdrawn_items[ingredient_id] += quantite
	else:
		withdrawn_items[ingredient_id] = quantite

# Récupère les ingrédients retirés
func get_withdrawals():
	return withdrawn_items

# Vérifie si les ingrédients retirés sont suffisants
func has_sufficient_ingredients(required_ingredients: Array) -> bool:
	for ingredient in required_ingredients:
		var ingredient_id = ingredient.get("id", null)
		var required_quantity = ingredient.get("quantite", 0)

		if ingredient_id == null:
			show_error_message("⚠️ Erreur : Un ingrédient ne contient pas d'ID valide !")
			return false

		# Vérifie si l'ingrédient retiré est suffisant
		var withdrawn_quantity = withdrawn_items.get(ingredient_id, 0)
		if withdrawn_quantity < required_quantity:
			show_error_message("❌ Ingrédient %s insuffisant ! Requis: %s, Retiré: %s" % 
				[ingredient_id, required_quantity, withdrawn_quantity])
			return false
	
	return true  # Tous les ingrédients sont disponibles en quantité suffisante

# Ajoute un plat dans un four donné après vérification des ingrédients
# Ajoute un plat dans un four donné après vérification des ingrédients
func add_dish_to_oven(oven_id: String, plat_id: int, required_ingredients: Array, idDetail: int) -> bool:
	if oven_id in oven_dishes:
		show_error_message("❌ Le four %s contient déjà un plat !" % oven_id)
		return false  # Impossible d'ajouter un plat s'il y en a déjà un

	# Vérifie si les ingrédients retirés sont suffisants
	if not has_sufficient_ingredients(required_ingredients):
		show_error_message("❌ Impossible d'ajouter le plat '%s' au four %s - Ingrédients insuffisants." % [plat_id, oven_id])
		return false

	# Ajout du plat après validation des ingrédients
	oven_dishes[oven_id] = plat_id
	self.plat_id = plat_id  # Stocke le plat actuellement ajouté
	self.ingredients = required_ingredients
	
	# Met à jour le statut du plat
	update_detail_plat(idDetail, "en cuisson", "")

	# Mise à jour du stock pour chaque ingrédient utilisé
	for ingredient in required_ingredients:
		var ingredient_id = ingredient.get("id", null)
		var quantity_used = ingredient.get("quantite", 0)

		if ingredient_id != null:
			update_stock_ingredient(ingredient_id, "utilisé", quantity_used, "")

	print("✅ Plat '%s' ajouté au four %s avec les ingrédients requis." % [plat_id, oven_id])
	return true

# Retire un plat d'un four donné
func remove_dish_from_oven(oven_id: String) -> bool:
	if oven_id in oven_dishes:
		print("🍽 Plat '%s' retiré du four %s" % [oven_dishes[oven_id], oven_id])
		oven_dishes.erase(oven_id)
		return true
	else:
		show_error_message("⚠️ Aucun plat trouvé dans le four %s" % oven_id)
		return false

# Récupère les plats actuellement dans les fours
func get_oven_dishes():
	return oven_dishes

# Affiche un message d'erreur en rouge et le fait disparaître après 3 secondes
func show_error_message(message: String):
	if error_label:
		error_label.text = "❌ " + message
		error_label.visible = true
		await get_tree().create_timer(3.0).timeout
		error_label.visible = false
