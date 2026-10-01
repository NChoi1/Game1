extends CharacterBody2D

@export var max_health: int = 100
var current_health: int = max_health

@export var knockback_decay: float = 1200.0
var knockback_velocity: Vector2 = Vector2.ZERO

@export var push_force: float = 100.0

@onready var animatedsprite = $AnimatedSprite2D
@onready var health_bar = $HealthBar # Ensure HealthBar node exists in your scene!

const SPEED = 350.0
const JUMP_VELOCITY = -400.0

# Tracks the current interactive object in range (e.g., Cake)
var current_interactable: Node2D = null

func _ready() -> void:
	# Ensure game time is running at normal speed
	Engine.time_scale = 1.0
	
	# Initialize health bar values
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _unhandled_input(event: InputEvent) -> void:
	# Checks for 'interact' action (e.g., 'E' key)
	if event.is_action_pressed("interact") and current_interactable:
		if current_interactable.has_method("interact"):
			current_interactable.interact(self)

func _physics_process(delta: float) -> void:
	_handle_rigidbody_push()
	
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Apply knockback once and immediately clear it
	if knockback_velocity != Vector2.ZERO:
		velocity.y = knockback_velocity.y
		knockback_velocity = Vector2.ZERO

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Spit animation logic
	if Input.is_action_just_pressed("fire") and not (animatedsprite.animation == "spit" and animatedsprite.is_playing()):
		animatedsprite.play("spit")

	if animatedsprite.animation != "spit" or not animatedsprite.is_playing():
		if direction != 0:
			animatedsprite.play("run")
			animatedsprite.flip_h = direction < 0
		else:
			animatedsprite.play("idle")
	else:
		if direction != 0:
			animatedsprite.flip_h = direction < 0

	move_and_slide()

# --- Health, Damage & Healing ---
func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	if health_bar:
		health_bar.value = current_health

func take_damage(amount: int) -> void:
	current_health = max(current_health - amount, 0)
	if health_bar:
		health_bar.value = current_health

	if current_health <= 0:
		die()

func die() -> void:
	Engine.time_scale = 1.0 
	get_tree().call_deferred("reload_current_scene")

# --- Signal Connections ---
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("death"):
		Engine.time_scale = 1.0
		get_tree().call_deferred("reload_current_scene")

	if area.is_in_group("exit_to_world2"):
		Engine.time_scale = 1.0
		get_tree().call_deferred("change_scene_to_file", "res://scenes/world2.tscn") 

	if area.is_in_group("enemy_hitbox"):
		take_damage(20)
		take_damage_and_knockback(area)

	# Store current interactable object when stepping into its Area2D
	if area.is_in_group("interactable"):
		current_interactable = area.get_parent()

func _on_area_2d_area_exited(area: Area2D) -> void:
	# Clear reference when stepping away
	if area.is_in_group("interactable"):
		if current_interactable == area.get_parent():
			current_interactable = null

func _on_hurtbox_area_entered(area: Area2D) -> void:
	_on_area_2d_area_entered(area)

# --- Knockback handling (Hit-stop removed) ---
func take_damage_and_knockback(hit_source: Area2D) -> void:
	knockback_velocity = Vector2(0.0, -250.0)

func _handle_rigidbody_push() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody2D:
			var push_direction := -collision.get_normal()
			collider.apply_central_impulse(push_direction * push_force)
