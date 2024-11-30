extends Node2D

const BEAM = preload("res://scenes/beam_attack.tscn")

var beams = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var beam = BEAM.instantiate()
	beam.to_point = Vector2(10, 10)
	add_child(beam)
	beams.append(beam)

	var beam2 = BEAM.instantiate()
	beam2.to_point = Vector2(-10, 10)
	add_child(beam2)
	beams.append(beam2)
	beam2.position.x += 10


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
