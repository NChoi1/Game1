extends CharacterBody2D

@export var max_health: int = 100
var current_health: int = max_health

@export var knockback_decay: float = 1200.0
var knockback_velocity: Vector2 = Vector2.ZERO

@export var push_force: float = 100.0

@export var kick_offset_x: float = 30.0

@onready var animatedsprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar = $HealthBar 

@onready var kick_hitbox: Area2D = find_child("KickHitbox", true, false) as Area2D
@onready var kick_collision: CollisionShape2D = find_child("CollisionShape2D", true, false) as CollisionShape2D if kick_hitbox else null

const SPEED = 350.0
const JUMP_VELOCITY = -400.0

var current_interactable: Node2D = null
var is_kicking: bool = false
var is_spitting: bool = false
var has_damaged_this_kick: bool = false

func _ready() -> void:
	Engine.time_scale = 1.0
	
	if not is_in_group("playergroup"):
		add_to_group("playergroup")
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

	if animatedsprite and not animatedsprite.animation_finished.is_connected(_on_animation_finished):
		animatedsprite.animation_finished.connect(_on_animation_finished)
	
	if kick_hitbox and not kick_hitbox.is_in_group("player_kick"):
		kick_hitbox.add_to_group("player_kick")
	
	if kick_collision:
		kick_collision.disabled = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_interactable:
		if current_interactable.has_method("interact"):
			current_interactable.interact(self)

func _physics_process(delta: float) -> void:
	_handle_rigidbody_push()
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if knockback_velocity != Vector2.ZERO:
		velocity.y = knockback_velocity.y
		knockback_velocity = Vector2.ZERO

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# attacking
	if Input.is_action_just_pressed("kick") and not is_kicking and not is_spitting:
		_perform_kick()

	if Input.is_action_just_pressed("fire") and not is_kicking and not is_spitting:
		_perform_spit()

	# Flip sprite and adjust kick offset
	if direction != 0:
		animatedsprite.flip_h = direction < 0
		if kick_hitbox:
			kick_hitbox.position.x = -abs(kick_offset_x) if direction < 0 else abs(kick_offset_x)

	# regular movement
	if not is_kicking and not is_spitting:
		if direction != 0:
			animatedsprite.play("run")
		else:
			animatedsprite.play("idle")

	# Continuous area check while kicking
	if is_kicking and not has_damaged_this_kick and kick_hitbox:
		var overlapping_areas = kick_hitbox.get_overlapping_areas()
		for area in overlapping_areas:
			_check_and_damage_enemy(area)

	move_and_slide()

# kicking
func _perform_kick() -> void:
	is_kicking = true
	has_damaged_this_kick = false
	animatedsprite.play("kick")
	
	if kick_collision:
		kick_collision.disabled = false

# spitting
func _perform_spit() -> void:
	is_spitting = true
	animatedsprite.play("spit")

func _on_animation_finished() -> void:
	var anim_name = animatedsprite.animation
	
	if anim_name == "kick":
		is_kicking = false
		has_damaged_this_kick = false
		if kick_collision:
			kick_collision.disabled = true
	elif anim_name == "spit":
		is_spitting = false

func _on_kick_hitbox_area_entered(area: Area2D) -> void:
	if is_kicking and not has_damaged_this_kick:
		_check_and_damage_enemy(area)

func _check_and_damage_enemy(node: Node) -> void:
	if node == self or node == find_child("hurtbox", true, false):
		return

	# ignore, detect, and sensing
	if node.name.to_lower().contains("detection") or node.is_in_group("detection"):
		return

	var current_node: Node = node
	var enemy: Node = null

	while current_node != null and current_node != get_tree().root:
		if current_node.has_method("take_damage") and current_node != self:
			enemy = current_node
			break
		current_node = current_node.get_parent()

	if enemy and not has_damaged_this_kick:
		enemy.take_damage(25)
		has_damaged_this_kick = true
		if enemy.has_method("take_knockback"):
			enemy.take_knockback(global_position)

#health, dmg and healing
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

# signals
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

	if area.is_in_group("interactable"):
		current_interactable = area.get_parent()

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group("interactable"):
		if current_interactable == area.get_parent():
			current_interactable = null

func _on_hurtbox_area_entered(area: Area2D) -> void:
	_on_area_2d_area_entered(area)

func take_damage_and_knockback(_hit_source: Area2D) -> void:
	knockback_velocity = Vector2(0.0, -250.0)

func _handle_rigidbody_push() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody2D:
			var push_direction := -collision.get_normal()
			collider.apply_central_impulse(push_direction * push_force)
