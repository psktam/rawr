extends Node2D

const DC = preload("res://scripts/damage_coordinator.gd")

@onready var level_0: TileMapLayer = $Level0
@onready var buildings: TileMapLayer = $buildings
@onready var environmental: TileMapLayer = $environmental
@onready var navigation_region_2d: NavigationRegion2D = $NavigationRegion2D

var update_navmesh = false
var current_tick_time_s = 0.0
var tick_time_s = 2.0

class BuildingInfo:
	var health: int
	var flammability: int  # 100 = always catches fire, 0 = never catches fire

# Maps tileMap coordinate -> health of the building on that tile
var buildingInfos = {}

class BurnInfo:
	var timeRemaining: float

# Keep track of areas that are already on fire.
var onFire = {}

const IMMEDIATE_SURROUNDINGS = [
	Vector2i(-1, -1), 
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, -1),
	Vector2i(0, 1),
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(1, 1)
]


func level_layers() -> Dictionary:
	var layer_map = {}
	for child in get_children():
		if child is TileMapLayer:
			layer_map[child.name] = child
	return layer_map


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Hook up all damage signals
	var damage_controller: DC = $"/root/game".damage_controller
	damage_controller.BEAM_LANDING.connect(process_beam_landing)
	damage_controller.METEOR_LANDING.connect(process_meteor_landing)
	damage_controller.BURN.connect(handle_burn)

	# Assign starting health for all buildings
	for coords in buildings.get_used_cells():
		var starting_health = buildings.get_cell_tile_data(coords).\
			get_custom_data("startingHealth")

		if starting_health != 0:
			var newInfo = BuildingInfo.new()
			newInfo.health = starting_health
			newInfo.flammability = 25
			buildingInfos[coords] = newInfo


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if update_navmesh:
		navigation_region_2d.bake_navigation_polygon()
		update_navmesh = false

	for pt in onFire:
		onFire[pt].timeRemaining -= delta
		if onFire[pt].timeRemaining <= 0.0:
			onFire.erase(pt)
			environmental.erase_cell(pt)


# Beam deals the most damage to the tile it lands on, and 50% damage to 
# surrounding tiles.
func process_beam_landing(landing_point: Vector2):
	var landing_coords = buildings.local_to_map(buildings.to_local(landing_point))
	var destroyed = {}

	var damage_results = _apply_damage(landing_coords, 500)
	if damage_results["valid"] and damage_results["died"]:
		destroyed[landing_coords] = damage_results["data"]

	for offset in IMMEDIATE_SURROUNDINGS:
		var point = offset + landing_coords
		_apply_damage(point, 250)


# Decrement health from the given building, and remove it from the building 
# layer if it is destroyed.
func _apply_damage(cell_coords: Vector2i, damage: int) -> Dictionary:
	if not buildingInfos.has(cell_coords):
		return {"valid": false, "died": false}
	
	buildingInfos[cell_coords].health -= damage
	if buildingInfos[cell_coords].health <= 0:
		buildingInfos.erase(cell_coords)
		buildings.erase_cell(cell_coords)
		update_navmesh = true
	
		return {
			"valid": true, 
			"died": true, 
			"data": buildings.get_cell_tile_data(cell_coords)
		}
	return {
		"valid": true,
		"died": false
	}


func process_meteor_landing(landing_point: Vector2, landing_base_damage: int):
	# This is how you destroy parts of the map!
	var local_landing_point = buildings.local_to_map(buildings.to_local(landing_point))
	var blast_area = generate_circle_points(local_landing_point, 4)
	for point in blast_area:
		if buildingInfos.has(point):
			var dmg = landing_base_damage / max((
				local_landing_point - point).length_squared(), 1)
			var result = _apply_damage(point, dmg)

			# If the building is still standing after this, see if it catches
			# fire. 
			if not result["died"] and not onFire.has(point):
				var dist_factor = (point - local_landing_point).length() / 5
				var flam_factor = 0.01 * buildingInfos[point].flammability
				var chance_to_catch_fire = flam_factor * exp(
					-(1 - flam_factor) * dist_factor)
				if randf() < chance_to_catch_fire:
					onFire[point] = BurnInfo.new()
					onFire[point].timeRemaining = 3.0
					environmental.set_cell(point, 0, Vector2(0, 0))


func handle_burn(location: Vector2, heat: int) -> void:
	# Find those tiles within the heat radius of the event.
	var center_coords = buildings.local_to_map(buildings.to_local(location))
	var burn_mask = generate_circle_points(center_coords, heat)

	for point in burn_mask:
		if buildingInfos.has(point) and not onFire.has(point):
			# roll to see how likely it is this building to catch fire.
			var dist_factor = (point - center_coords).length() / heat
			var flam_factor = 0.01 * buildingInfos[point].flammability
			var chance_to_catch_fire = flam_factor * exp(
				-(1 - flam_factor) * dist_factor)
			if randf() < chance_to_catch_fire:
				onFire[point] = BurnInfo.new()
				onFire[point].timeRemaining = 2.0
				environmental.set_cell(point, 0, Vector2(0, 0))


func handle_world_burn(locations: PackedVector2Array, heats: PackedInt32Array) -> void:
	pass


################################################################################
#                              UTILITY FUNCTIONS                               #
################################################################################
func generate_circle_points(center: Vector2i, radius: int) -> Array:
	var points = []
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if Vector2(x, y).length() <= radius:
				points.append(Vector2i(x, y) + center)
	return points
