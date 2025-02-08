extends Area3D

@export var window: Control
@export var container: VBoxContainer
@export var scroll_container: ScrollContainer

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
	var url = "http://192.168.1.174:8000/api/admin/stocks/all"
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
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

	for item in data:
		var ingredient = item["ingredient"]
		var quantite = item["quantite"]
		add_ingredient_to_ui(ingredient["id"], ingredient["nomIngredient"], ingredient["nomImage"], quantite)

	await get_tree().process_frame
	scroll_container.set_deferred("scroll_vertical", scroll_container.get_v_scroll_bar().max_value)

func add_ingredient_to_ui(ingredient_id, nom, image_path, quantite):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var texture = TextureRect.new()
	texture.texture = load("res://images/" + image_path)
	texture.custom_minimum_size = Vector2(50, 50)

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
		print("⚠️ Erreur: Quantité demandée supérieure au stock disponible !")
		return

	if quantite > 0:
		Session.add_withdrawal(ingredient_id, quantite)  # Enregistrement en session
		qty_label.text = "x" + str(stock_disponible - quantite)
		print("✅ Retrait enregistré. Session actuelle :", Session.get_withdrawals())
	else:
		print("⚠️ Aucune quantité disponible pour", ingredient_id)
