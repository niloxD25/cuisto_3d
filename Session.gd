extends Node

var withdrawn_items = {}  # Stockage global des ingrédients retirés

# Ajoute un retrait
func add_withdrawal(ingredient_id, quantite):
	if ingredient_id in withdrawn_items:
		withdrawn_items[ingredient_id] += quantite
	else:
		withdrawn_items[ingredient_id] = quantite

# Récupère la session
func get_withdrawals():
	return withdrawn_items
