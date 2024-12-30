class_name NPCUtils


static func get_nav_layer(n: Node2D) -> TileMapLayer:
	return n.get_node("/root/game/world/level").level_0


"""
Get the distance between the two nodes in tilemap units, 
not pixel units.
"""
static func tilemap_dist2(
	nav_layer: TileMapLayer, p0: Vector2, p1:Vector2
) -> float:
	return (
		nav_layer.local_to_map(nav_layer.to_local(p0)) -
		nav_layer.local_to_map(nav_layer.to_local(p1))
	).length_squared()


"""
Returns the length of the path represented by `path` by summing together the 
lengths of all of the segments, in global coordinate space. Note that we need
to divide th y-coordinate by 2 to account for the isometric perspective
"""
static func _path_length(start_pt: Vector2, path: PackedVector2Array) -> float:
	var length = 0.0
	if len(path) < 2:
		return length

	start_pt = start_pt / Vector2(1, 2)
	for next_point in path:
		next_point = next_point / Vector2(1, 2)
		length += (start_pt - next_point).length()
		start_pt = next_point

	return length


"""
Given a nominal target, pick `n_trials` random tiles up to `jitter_size` away 
and return the tile that has the shortest path calculated by the navigation
server.

Args:
	nav_layer: the TileMapLayer used for calculating the navmesh
	agent: the navigationAgent2D to use
	n_trials: how many paths to sample
	current_position: current position of your agent, in global coordinates
	nominal_target: first guess at where to go, expressed in global coordinates
	jitter_size: how far off the nominal target, in tiles, we can deviate when
		sampling
	
Returns:
	Vector2 of target point (in global coordinates) that represents the 
		closest place to go
"""
static func pick_random_target(
	nav_layer: TileMapLayer,
	agent: NavigationAgent2D, 
	n_trials: int, 
	current_position: Vector2,
	nominal_target: Vector2, 
	jitter_size: int
) -> Vector2i:
	var shortest_path = NavigationServer2D.map_get_path(
		agent.get_navigation_map(),
		current_position,
		nominal_target, 
		true
	)
	var shortest_length = _path_length(current_position, shortest_path)
	var nominal_target_tm = nav_layer.local_to_map(nav_layer.to_local(nominal_target))

	for trial in range(n_trials):
		# Jitter the nominal target in tilemap coordinate space, then convert
		# those tilemap coordinates to global coordinates
		var jittered_target_tm = nominal_target_tm + Vector2i(
			randi() % jitter_size, 
			randi() % jitter_size
		)
		var jittered_target = nav_layer.to_global(nav_layer.map_to_local(jittered_target_tm))
		var new_path = NavigationServer2D.map_get_path(
			agent.get_navigation_map(),
			current_position,
			jittered_target,
			true
		)
		var new_path_len = _path_length(current_position, new_path)
		if new_path_len < shortest_length:
			shortest_path = new_path
			shortest_length = new_path_len

	return shortest_path[-1]

################################################################################ 
#							Class-related methods							 #
################################################################################ 
var persistent_threats = []
var spontaneous_threats = []
var cmder: Node2D

func _init(_cmder: Node2D) -> void:
	cmder = _cmder

# This function is called when a spontaneous/ephemeral threat occurs, such 
# as a building exploding, or a meteor/beam landing. This function indicates 
# whether or not the agent calling this function needs to react to it
func assess_threats(
	threat_map: Dictionary
) -> Threats.ThreatInfo:
	var all_threats = persistent_threats + spontaneous_threats
	spontaneous_threats = []

	if len(all_threats) == 0:
		return null

	var biggest_threat = all_threats[0]
	for ix in range(1, len(all_threats)):
		var threat = all_threats[ix]
		if threat_map[threat.Type] > threat_map[biggest_threat.Type]:
			biggest_threat = threat
	
	if biggest_threat.Type == Threats.Threat.ME:
		biggest_threat.Loc = cmder.global_position

	return biggest_threat
