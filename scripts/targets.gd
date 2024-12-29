extends Resource
class_name Targets

# Map `Node2D` to weight of target
var targets: Dictionary = {}
var current_target: Node2D = null


func has_target() -> bool:
	return current_target != null


func add_target(new_target: Node2D, weight: int) -> void:
	targets[new_target] = weight


# Weigh where all potential targets are, compared to the current
# target. If current target is much further away compared to other
# potential targets, pick the one that's the best combination of
# close + priority.
func set_target(current_location: Vector2) -> Node2D:
	if len(targets) == 0:
		return null

	var best_target = current_target
	var best_priority = -1

	# The current target gets a boost of 10% for being the current
	# target
	if best_target != null:
		best_priority = 1.1 * targets[best_target] / (
			current_location - best_target.global_position).length()

	for potential_target in targets.keys():
		var new_priority = targets[potential_target] / (
			current_location - potential_target.global_position
		).length()

		if new_priority > best_priority:
			best_priority = new_priority
			best_target = potential_target

	current_target = best_target
	return best_target


func remove_target(
	target: Node2D,
	current_location: Vector2
) -> void:
	if targets.has(target):
		targets.erase(target)

	if current_target == target:
		current_target = set_target(current_location)
