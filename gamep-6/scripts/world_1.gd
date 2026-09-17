extends Node2D
@onready var label: RichTextLabel=$RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fadeout() #replaced with pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_boundry_area_entered(area: Area2D)-> void:
	get_tree().reload_current_scene()
	
func fadeout()-> void:
	var tween: Tween = create_tween()
	#create time in second for tween transition
	tween.tween_interval(1)
	#modulate alpha value (rgba) from out variabhle "label" from 0 to 1
	tween.tween_callback(label.queue_free)
	
