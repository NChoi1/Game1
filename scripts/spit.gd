extends Node2D

const SPEED: float = 1000.0

@export var damage: int = 10
@export var knockback_force: float = 600.0

func _process(delta: float) -> void:
	position += transform.x * SPEED * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

# Handles both Area2D signal node names (_on_area_2d_body_entered and _on_damage_body_entered)
func _on_area_2d_body_entered(body: Node2D) -> void:
	_handle_collision(body)

func _on_damage_body_entered(body: Node2D) -> void:
	_handle_collision(body)

func _handle_collision(body: Node2D) -> void:
	# Ignore colliding with the player node if the spit spawns inside the player
	if body.is_in_group("playergroup"):
		return

	# Deal damage if the body has a take_damage method
	if body.has_method("take_damage"):
		body.take_damage(damage)

	# Apply knockback using global_position as the hit source
	if body.has_method("take_knockback"):
		body.take_knockback(global_position, knockback_force)

	queue_free()
