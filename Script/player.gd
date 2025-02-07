extends CharacterBody3D

@onready var anim_player = $AnimationPlayer  # Animation du personnage

@export var speed = 20.0
@export var jump_force = 4.5
var gravity = 9.8  # Réduction de la gravité

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta  # Appliquer la gravité

	var direction = Vector3.ZERO

	if Input.is_action_pressed("ui_right"):
		direction.x -= 2  # Droite
	if Input.is_action_pressed("ui_left"):
		direction.x += 2  # Gauche
	if Input.is_action_pressed("ui_up"):
		direction.z += 2  # Avant
	if Input.is_action_pressed("ui_down"):
		direction.z -= 2  # Arrière

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		# 🔹 Jouer l'animation de marche
		if not anim_player.is_playing() or anim_player.current_animation != "Walking_A":
			print("Jouer l'animation de marche")
			anim_player.play("Walking_A")

		# 🔄 Retourner le personnage selon la direction (rotation Y)
		if direction.z > 0:
			$Rig.rotation_degrees.y = 180  # Face avant (vers l'axe Z)
		elif direction.z < 0:
			$Rig.rotation_degrees.y = 0  # Face arrière
		elif direction.x > 0:
			$Rig.rotation_degrees.y = -90  # Face droite (vers l'axe X)
		elif direction.x < 0:
			$Rig.rotation_degrees.y = 90  # Face gauche

	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

		# 🔹 Si pas de mouvement, jouer l’animation idle
		if not anim_player.is_playing() or anim_player.current_animation != "Idle":
			anim_player.play("Idle")

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()
