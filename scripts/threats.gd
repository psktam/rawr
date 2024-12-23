extends Resource
class_name Threats


enum Threat {
    ME, 
    BEAM,
    METEOR,
    FIRE
}

class ThreatInfo:
    var Type: Threat
    var Active: bool
    var Loc: Vector2

    func _init(t, l) -> void:
        Type = t
        Active = true
        Loc = l


# Internal class stuff
var weights = {}
var ephemeral_weights = []
var has_new_threat = false


func add_ephemeral_threat(position: Vector2, weight: int) -> void:
    ephemeral_weights.append({
        "pos": position, 
        "weight": weight
    })
    has_new_threat = true


func add_new_threat(node: Node2D, weight: int) -> void:
    weights[node] = weight
    has_new_threat = true


func has_threats() -> bool:
    return (len(ephemeral_weights) + len(weights)) > 0


func remove_threat(node: Node) -> void:
    if weights.has(node):
        weights.erase(node)


# Return a normalized vector indicating safest direction to run
func get_flee_direction(current_pos: Vector2) -> Vector2:
    var flee_dir = Vector2.ZERO

    for node in weights.keys():
        var delta = node.global_position - current_pos
        var dist_factor = 1.0 / max(delta.length(), 1.0)
        flee_dir += -weights[node] * dist_factor * delta.normalized()

    for ephemeral_threat in ephemeral_weights:
        var delta = (ephemeral_threat["pos"] - current_pos)
        var dist_factor = 1.0 / max(delta.length(), 1.0)
        flee_dir += -ephemeral_threat["weight"] * dist_factor * delta.normalized()
    
    ephemeral_weights = []
    has_new_threat = false

    return flee_dir.normalized()