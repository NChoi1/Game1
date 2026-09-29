extends CharacterBody2D
#spit(make the neck get longer and make a cooldown for the spit)
#kick(make his little legs kick)

@export var push_force: float = 100
@onready var animatedsprite = $AnimatedSprite2D

const SPEED = 350.0
const JUMP_VELOCITY = -400.0


func _physics_process(delta: float) -> void:
	_handle_rigidbody_push()                         
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
#/////////////////////////////////////////////////////
	#only if the spit is not playing yet
	# This ensures the animation finishes completely before it can be triggered again.
	if Input.is_action_just_pressed("fire") and not (animatedsprite.animation == "spit" and animatedsprite.is_playing()):
		animatedsprite.play("spit")

	#switch it back
	if animatedsprite.animation != "spit" or not animatedsprite.is_playing():
		if direction != 0:
			animatedsprite.play("run")
			animatedsprite.flip_h = direction < 0
		else:
			animatedsprite.play("idle")
	else:
		# Keep flipping character direction while spitting
		if direction != 0:
			animatedsprite.flip_h = direction < 0
#/////////////////////////////////////////////////////
	move_and_slide()
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("death"):
		get_tree().call_deferred("reload_current_scene")

	if area.is_in_group("exit_to_world2"):
		get_tree().call_deferred("change_scene_to_file", "res://scenes/world2.tscn") 

	#if area.is_in_group("cakegroup"):
		#the cake will disapear when the player clicks e
	#if area.is_in_group("hit"):
		#the player will get hit by the enemy, deleting some of its HP
		
func _handle_rigidbody_push()-> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody2D:
			var push_direction := -collision.get_normal()
			collider.apply_central_impulse(push_direction * push_force)
			
