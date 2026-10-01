extends Area2D
@export var speed: float = 600.0
var direction: float = 1.0

# Called when the node enters the scene tree for the first time.
func _physics_process(delta: float) -> void:
	#move horizontaly i the assigned facing direction
	position.x += speed * direction * delta
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _on_body_entered(delta: Node2D) -> void:
	#queue_free()
	
func _on_visible_on_screen_notifier_2d_screen_exited()->void:
	queue_free()
