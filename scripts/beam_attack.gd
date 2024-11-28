extends Node2D

@export_category("Beam Attack")
@export var state:String = "state"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func apply_attack(from_point: Vector2, to_point: Vector2) -> void:
	var attack_dir = to_point - from_point


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
