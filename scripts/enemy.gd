extends CharacterBody2D

@export var max_health: int = 50
var current_health: int = max_health

@export var attack_damage: int = 20
@export var attack_cooldown: float = 1.0 # Time between attacks in seconds
var can_attack: bool = true
var is_attacking: bool = false
var player_in_attack_range: bool = false

@export var knockback_decay: float = 1200.0
var knockback_velocity: Vector2 = Vector2.ZERO

@export var move_speed: float = 160.0
@export var gravity: float = 980.0
@onready var animatedsprite = $AnimatedSprite2D

@onready var detection_area: Area2D = $detection
@onready var attack_area: Area2D = $attack_area # Ensure this Area2D exists in scene!

var target_player: Node2D = null

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var direction = 0
	
	# Chase player along the X-axis if detected and not playing an attack animation
	if target_player and not is_attacking:
		direction = sign(target_player.global_position.x - global_position.x)
		velocity.x = direction * move_speed
		
		# Try attacking if player is within range and cooldown is ready
		if player_in_attack_range and can_attack:
			perform_attack()
	else:
		velocity.x = 0.0
		
	# Animation Handling
	if not is_attacking:
		if direction != 0:
			animatedsprite.play("running")
			animatedsprite.flip_h = direction < 0	
		else:
			animatedsprite.play("idle")
		
	# Apply knockback force if present and clear it instantly
	if knockback_velocity != Vector2.ZERO:
		velocity.y = knockback_velocity.y
		knockback_velocity = Vector2.ZERO

	move_and_slide()

# --- Attack System ---
func perform_attack() -> void:
	can_attack = false
	is_attacking = true
	
	# Play attack animation if you have one, or fallback to default
	if animatedsprite.sprite_frames.has_animation("attack"):
		animatedsprite.play("attack")
	
	# Deal damage to player if they have a take_damage function
	if target_player and target_player.has_method("take_damage"):
		target_player.take_damage(attack_damage)
		
		# Also trigger knockback on player if function exists
		if target_player.has_method("take_damage_and_knockback"):
			target_player.take_damage_and_knockback(attack_area)

	# Cooldown timer before the enemy can attack again
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	is_attacking = false

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("playergroup") or body is CharacterBody2D:
		player_in_attack_range = true

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == target_player:
		player_in_attack_range = false

# --- Health & Damage Handler ---
func take_damage(amount: int) -> void:
	current_health -= amount
	print("Enemy hit! Remaining health: ", current_health)
	
	# Visual red flash effect on hit
	var tween = create_tween()
	tween.tween_property(animatedsprite, "modulate", Color.RED, 0.1)
	tween.tween_property(animatedsprite, "modulate", Color.WHITE, 0.1)

	if current_health <= 0:
		die()

func die() -> void:
	queue_free()

# --- Vertical Hit Hop ---
func take_knockback(hit_source_position: Vector2, force: float = 250.0) -> void:
	knockback_velocity = Vector2(0.0, -force)

func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("playergroup"):
		target_player = body

func _on_detection_body_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
		player_in_attack_range = false
