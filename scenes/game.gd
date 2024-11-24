extends Node2D

@onready var cmder = $cmder
@onready var target_cursor: AnimatedSprite2D = $targetCursor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if cmder.state == "still":
		target_cursor.visible = false
	elif cmder.state == "moving":
		target_cursor.visible = true
		target_cursor.global_position = cmder.destination
		
