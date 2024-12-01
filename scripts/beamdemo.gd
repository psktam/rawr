extends Node2D

const METEOR = preload("res://scenes/meteor_attack.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var m = METEOR.instantiate()
	m.target_point = Vector2(1, 5)
	add_child(m)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
