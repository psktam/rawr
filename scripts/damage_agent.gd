# Should be an identifier that uniquely identifies this object. Pretty much a 
# UUID, but doesn't need to be formatted as such
var id: String
var agentPosition: Vector2


func apply_damage(amount: int, type: String) -> void:
    """Applies damage to this agent"""


func get_position() -> Vector2:
    return Vector2.ZERO