extends Node

enum Direction {
	NONE,
	N,
	S,
	E,
	W,
	NW,
	NE,
	SW,
	SE
}


static func map_initialized(agent: NavigationAgent2D) -> bool:
	return NavigationServer2D.map_get_iteration_id(agent.get_navigation_map()) != 0
