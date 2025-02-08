extends StaticBody3D

@export var StoveMulti: MeshInstance3D
@export var StoveMultiDecorated: MeshInstance3D
@export var oven_id: String  # Identifiant unique pour chaque four
var session
var timer: Timer

func _ready():
	session = get_node("/root/Session")  # Récupère le gestionnaire de session
	if not StoveMulti or not StoveMultiDecorated:
		push_warning("Les MeshInstance3D ne sont pas assignés !")
	
	# Créer et configurer un Timer
	timer = Timer.new()
	timer.wait_time = 1.0  # Intervalle de 1 seconde (modifiable)
	timer.autostart = true  # Démarre automatiquement
	timer.one_shot = false  # Le timer se répète
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	add_child(timer)  # Ajoute le Timer à la scène
	
	update_mesh()  # Appel initial pour mettre à jour immédiatement

# Fonction appelée périodiquement par le Timer
func _on_timer_timeout():
	update_mesh()

# Met à jour l'affichage en fonction de la présence d'un plat
func update_mesh():
	var dishes = session.get_oven_dishes()
	var has_dish = oven_id in dishes  # Vérifie si un plat est présent dans ce four

	StoveMulti.visible = not has_dish
	StoveMultiDecorated.visible = has_dish
