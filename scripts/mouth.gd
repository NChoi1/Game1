extends Node2D

const MOUTH = preload("res://scenes/spit.tscn")
@onready var timer: Timer = $Timer

var can_fire: bool = false

func _ready() -> void:
	# Small delay on load to prevent initial window focus click
	await get_tree().process_frame 
	can_fire = true

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1

	if can_fire and Input.is_action_just_pressed("fire") and timer.is_stopped():
		var mouth_instance = MOUTH.instantiate()
		get_tree().root.add_child(mouth_instance)
		mouth_instance.global_position = global_position
		mouth_instance.rotation = rotation
		
		timer.start() # Start the cooldown timer
