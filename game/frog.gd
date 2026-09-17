extends CharacterBody2D
@onready var animatedsprite = $AnimatedSprite2D
@onready var muzzle: Marker2D =$muzzle
const BULLET_SCENE = preload("res://bullet.tscn")

const SPEED = 200.0
const JUMP_VELOCITY = -400.0


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("death"):
		get_tree().reload_current_scene()
	if area.is_in_group("exit_to_world2"):
		get_tree().change_scene_to_file("res://world_2.tscn")


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	#handle shooting
	if Input.is_action_just_pressed("shoot"):
		print("shoot")
		shoot_bullet()

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		$jump.play()
	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		$running.play()
	   
	move_and_slide()
   
	# Update animation state
	if direction != 0:
		animatedsprite.play("run")
		animatedsprite.flip_h = direction < 0
	else:
		animatedsprite.play("idle")

func shoot_bullet() -> void:
	var bullet = BULLET_SCENE.instantiate()
	#determine facing direction (-1 for left and 1 for right)
	var facing_direction: float = -1.0 if animatedsprite.flip_h else 1.0
	#spawn and marker 2D muzzle
	var spawn_offset: Vector2 = muzzle.position
	spawn_offset.x *= facing_direction
	#assign position and direction
	bullet.global_position = global_position + spawn_offset
	bullet.direction = facing_direction
	#match bullet visual flip with plater sprite
	if bullet.has_node("Sprite2D"):
		bullet.get_node("Sprite2D").flip_h=animatedsprite.flip_h
		get_tree().current_scene.add_child(bullet)
