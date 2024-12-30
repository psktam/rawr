extends Resource
class_name Targets

var current_target: Node2D = null
var owner: Node2D
var triggering_range2: int
var leaving_range2: int
var navlayer: TileMapLayer
var weighting_function: Callable


func _init(
	owner_: Node2D,
	triggering_range_: int,
	leaving_range_: int,
	navlayer_: TileMapLayer,
	weighting_function_: Callable
) -> void:
	owner = owner_
	triggering_range2 = triggering_range_ * triggering_range_
	leaving_range2 = leaving_range_ * leaving_range_
	navlayer = navlayer_
	weighting_function = weighting_function_


func outside_leaving_range(pos: Vector2) -> bool:
	return NPCUtils.tilemap_dist2(
		navlayer, owner.global_position, pos) >= leaving_range2


func inside_triggering_range(pos: Vector2) -> bool:
	return NPCUtils.tilemap_dist2(
		navlayer, owner.global_position, pos) <= triggering_range2


func refresh_targets(target_nodes: Array) -> void:
	"""
	Enforce the following criteria:
	1. If we currently have a target, stay focused on that target until
	   a. They get too far out of range
	   b. They die
	2. If we don't have a target, find the closest/most juicy one, and
	   determine if they're worth going after.
	"""

	# First, check to see if our current target is A: not too far away
	# and B: not dead. If so, no recalculation needed at the moment.
	var ct = get_current_target()
	if ct != null and not outside_leaving_range(ct.global_position):
		return

	# Okay, so at this point, we need to find ourselves a new target.
	# Scan the target collections for targets that are in range of us,
	# and pick the one that has the best combination of distance and
	# priority.
	var best_score = -1
	for target_collection: Node2D in target_nodes:
		for potential_target in target_collection.get_children():
			if (
				inside_triggering_range(potential_target.global_position) and
				is_instance_valid(potential_target)
			):
				var tmap_dist2 = NPCUtils.tilemap_dist2(
					navlayer,
					owner.global_position,
					potential_target.global_position
				)
				var score = weighting_function.call(potential_target) / \
					max(tmap_dist2, 0.2)
				if score > best_score:
					best_score = score
					current_target = potential_target


func has_target() -> bool:
	return get_current_target() != null


func get_current_target():
	"""
	Checks if a target has been assigned and, if so, make sure
	that the target isn't dead. If the target is dead, it will
	set the current_target variable back to null.

	Returns the Node2D if the target is still valid. Otherwise,
	returns null if the target is either null or died.
	"""
	if current_target == null:
		return null
	elif is_instance_valid(current_target):
		return current_target
	current_target = null
	return null
