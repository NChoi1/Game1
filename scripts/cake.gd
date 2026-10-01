extends StaticBody2D

@export var heal_amount: int = 25
@onready var interaction_area: Area2D = $eat

var player_in_range: bool = false
var player_ref: CharacterBody2D = null

func _ready() -> void:
	# Connect detection signals automatically
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		give_reward()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D: # Ensure it's the player
		player_in_range = true
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = false
		player_ref = null

func give_reward() -> void:
	# Heal player
	if player_ref and player_ref.has_method("heal"):
		player_ref.heal(heal_amount)
	# Remove cake from scene
	queue_free()
