extends CharacterBody2D

@export var push_force: float = 100
@onready var animatedsprite = $AnimatedSprite2D

const SPEED = 300.0
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
		# Update animation state
	if direction != 0:
		animatedsprite.play("run")
		animatedsprite.flip_h = direction < 0
	else:
		animatedsprite.play("idle")
#/////////////////////////////////////////////////////
	move_and_slide()
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("death"):
		get_tree().reload_current_scene()
	if area.is_in_group("exit_to_world2"):
		get_tree().change_scene_to_file("res://scenes/world2.tscn")

func _handle_rigidbody_push()-> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody2D:
			var push_direction := -collision.get_normal()
			collider.apply_centeral_impulse(push_direction * push_force)
