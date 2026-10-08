extends CharacterBody2D

@export var max_health: int = 50
var current_health: int = max_health

@export var attack_damage: int = 20
@export var attack_cooldown: float = 1.0
@export var attack_range_distance: float = 40.0
var can_attack: bool = true
var is_attacking: bool = false
var player_in_attack_range: bool = false

@export var knockback_decay: float = 1200.0
var knockback_velocity: Vector2 = Vector2.ZERO

@export var move_speed: float = 160.0
@export var gravity: float = 980.0
@onready var animatedsprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var detection_area: Area2D = $detection
@onready var attack_area: Area2D = $attack_area

var target_player: Node2D = null

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	# Hard stop on movement while performing attack
	if is_attacking:
		velocity.x = 0.0
		move_and_slide()
		return

	if target_player:
		var dist_to_player = global_position.distance_to(target_player.global_position)
		var direction = sign(target_player.global_position.x - global_position.x)
		
		# Check range via Area2D collision signal OR raw distance fallback
		if player_in_attack_range or dist_to_player <= attack_range_distance:
			velocity.x = 0.0
			if can_attack:
				perform_attack()
			else:
				animatedsprite.play("idle")
		else:
			velocity.x = direction * move_speed
			animatedsprite.play("running")
			if direction != 0:
				animatedsprite.flip_h = direction < 0
	else:
		velocity.x = 0.0
		animatedsprite.play("idle")

	if knockback_velocity != Vector2.ZERO:
		velocity.y = knockback_velocity.y
		knockback_velocity = Vector2.ZERO

	move_and_slide()

func perform_attack() -> void:
	can_attack = false
	is_attacking = true
	velocity.x = 0.0

	# Face towards player
	if target_player:
		var attack_dir = sign(target_player.global_position.x - global_position.x)
		if attack_dir != 0:
			animatedsprite.flip_h = attack_dir < 0

	# Check and trigger attack animation
	if animatedsprite.sprite_frames and animatedsprite.sprite_frames.has_animation("attack"):
		animatedsprite.play("attack")
		
		# Calculate total length of attack animation (frames / FPS)
		var frames = animatedsprite.sprite_frames.get_frame_count("attack")
		var fps = animatedsprite.sprite_frames.get_animation_speed("attack")
		var anim_duration = float(frames) / (fps if fps > 0 else 10.0)
		
		# Wait for exact length of animation to finish
		await get_tree().create_timer(anim_duration).timeout
	else:
		print("Warning: 'attack' animation not found in AnimatedSprite2D!")
		await get_tree().create_timer(0.4).timeout

	# Apply damage to player
	if target_player:
		var dist = global_position.distance_to(target_player.global_position)
		if player_in_attack_range or dist <= attack_range_distance + 20.0:
			if target_player.has_method("take_damage"):
				target_player.take_damage(attack_damage)
			if target_player.has_method("take_damage_and_knockback"):
				target_player.take_damage_and_knockback(attack_area)

	is_attacking = false

	# Wait cooldown duration
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("playergroup") or body == target_player:
		player_in_attack_range = true

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body == target_player or body.is_in_group("playergroup"):
		player_in_attack_range = false

# --- Health & Damage Handler ---
func take_damage(amount: int) -> void:
	current_health -= amount
	print("Enemy hit! Remaining health: ", current_health)
	
	var tween = create_tween()
	tween.tween_property(animatedsprite, "modulate", Color.RED, 0.1)
	tween.tween_property(animatedsprite, "modulate", Color.WHITE, 0.1)

	if current_health <= 0:
		die()

func die() -> void:
	queue_free()

func take_knockback(_hit_source_position: Vector2, force: float = 250.0) -> void:
	knockback_velocity = Vector2(0.0, -force)

func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("playergroup"):
		target_player = body

func _on_detection_body_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
		player_in_attack_range = false
