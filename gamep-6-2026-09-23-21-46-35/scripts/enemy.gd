extends CharacterBody2D

@export var move_speed: float = 160.0
@export var gravity: float = 980.0
@onready var animatedsprite =$AnimatedSprite2D

@onready var detection_area: Area2D =$detection
var target_player: Node2D = null

#func _ready() -> void:
	#detection_area.body_entered.connect(_on_detection_body_entered)
	#detection_area.body_exited.connect(_on_detection_body_exited)

func _physics_process(delta: float) -> void:
	# Apply gravity for platforming physics
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var direction = 0
	
	# Chase player along the X-axis if detected
	if target_player:
		direction = sign(target_player.global_position.x - global_position.x)
		velocity.x = direction * move_speed
	else:
		velocity.x = 0.0
		
	if direction != 0:
		animatedsprite.play("running")
		animatedsprite.flip_h = direction < 0	
	else:
		animatedsprite.play("idle")

	move_and_slide()

func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("playergroup"):
		target_player = body


func _on_detection_body_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
