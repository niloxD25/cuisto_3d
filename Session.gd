extends Node

var withdrawn_items = {}  # Stockage global des ingrédients retirés
var oven_dishes = {}  # Stockage des plats dans chaque four (StaticBody3D)

# Ajoute un retrait d'ingrédient
func add_withdrawal(ingredient_id, quantite):
	if ingredient_id in withdrawn_items:
		withdrawn_items[ingredient_id] += quantite
	else:
		withdrawn_items[ingredient_id] = quantite

# Récupère les ingrédients retirés
func get_withdrawals():
	return withdrawn_items

# Ajoute un plat dans un four donné (StaticBody3D)
func add_dish_to_oven(oven_id: String, dish_name: String) -> bool:
	if oven_id in oven_dishes:
		print("❌ Erreur : Le four %s contient déjà un plat !" % oven_id)
		return false  # Impossible d'ajouter un plat s'il y en a déjà un
	else:
		oven_dishes[oven_id] = dish_name
		print("✅ Plat '%s' ajouté au four %s" % [dish_name, oven_id])
		return true

# Retire un plat d'un four donné
func remove_dish_from_oven(oven_id: String) -> bool:
	if oven_id in oven_dishes:
		print("🍽 Plat '%s' retiré du four %s" % [oven_dishes[oven_id], oven_id])
		oven_dishes.erase(oven_id)
		return true
	else:
		print("⚠️ Aucun plat trouvé dans le four %s" % oven_id)
		return false

# Récupère les plats actuellement dans les fours
func get_oven_dishes():
	return oven_dishes
