extends Node

var withdrawn_items = {}  # Stockage global des ingrédients retirés
var oven_dishes = {}  # Stockage des plats dans chaque four (StaticBody3D)
var ingredients = {}
var plat_id: int
var error_label: Label  # Label pour afficher les erreurs

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
func add_dish_to_oven(oven_id: String, plat_id: int, required_ingredients: Array) -> bool:
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
