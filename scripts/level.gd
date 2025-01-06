extends Node2D

const DC = preload("res://scripts/damage_coordinator.gd")

@onready var level_0: TileMapLayer = $Level0
@onready var buildings: TileMapLayer = $buildings
@onready var environmental: TileMapLayer = $environmental
@onready var navigation_region_2d: NavigationRegion2D = $NavigationRegion2D
@onready var damage_controller: DC = $"/root/game".damage_controller
var CC = TF.new()

var update_navmesh = false
var current_tick_time_s = 0.0
var tick_time_s = 2.0

class BuildingInfo:
	var health: int
	var flammability: int  # 100 = always catches fire, 0 = never catches fire
	#
	var tiles: Array

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
	construct_building_infos()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if update_navmesh:
		navigation_region_2d.bake_navigation_polygon()
		update_navmesh = false

	CC.cyclical_call(
		"worldburn",
		1000,
		emit_world_burn
	)

	for pt_hashed in onFire:
		var pt = _decode_hash(pt_hashed)
		onFire[pt_hashed].timeRemaining -= delta
		if onFire[pt_hashed].timeRemaining <= 0.0:
			onFire.erase(pt_hashed)
			environmental.erase_cell(pt)


func emit_world_burn():
	var raw_locs = []
	for k in onFire.keys():
		raw_locs.append(_decode_hash(k))

	var locs = PackedVector2Array(raw_locs)
	var heats = []
	for loc in locs:
		heats.append(2)

	if len(locs) > 0:
		print("Emitting ", len(locs), " spots")
		damage_controller.WORLD_BURN.emit(heats, PackedVector2Array(heats))
		handle_world_burn(locs, heats)


# Beam deals the most damage to the tile it lands on, and 50% damage to 
# surrounding tiles.
func process_beam_landing(landing_point: Vector2):
	var landing_coords = buildings.local_to_map(buildings.to_local(landing_point))
	var already_damaged = {}

	if _has_building(landing_coords):
		var bldg = _building_at(landing_coords)
		_apply_damage(bldg, 500)
		already_damaged[bldg] = true

	for offset in IMMEDIATE_SURROUNDINGS:
		var point = offset + landing_coords
		if _has_building(point):
			var bldg = _building_at(point)
			if already_damaged.has(bldg):
				continue
			_apply_damage(bldg, 250)
			already_damaged[bldg] = true


func _has_building(point: Vector2i) -> bool:
	return buildingInfos.has(_hash_coord(point))


func _building_at(point: Vector2i) -> BuildingInfo:
	return buildingInfos[_hash_coord(point)]


# Decrement health from the given building, and remove it from the building 
# layer if it is destroyed.
func _apply_damage(building: BuildingInfo, damage: int) -> Dictionary:
	building.health -= damage
	if building.health <= 0:
		for buildingCoord in building.tiles:
			var bch = _hash_coord(buildingCoord)
			buildingInfos.erase(bch)
			buildings.erase_cell(buildingCoord)

		update_navmesh = true
	
		return {
			"valid": true, 
			"died": true
		}
	return {
		"valid": true,
		"died": false
	}


func process_meteor_landing(landing_point: Vector2, landing_base_damage: int):
	# This is how you destroy parts of the map!
	var local_landing_point = buildings.local_to_map(buildings.to_local(landing_point))
	var blast_area = generate_circle_points(local_landing_point, 4)
	var damage_per_building = {}
	for point in blast_area:
		var p_hashed = _hash_coord(point)
		if _has_building(point):
			var bldg = _building_at(point)
			var dmg = landing_base_damage / max((
				local_landing_point - point).length_squared(), 1)

			if not damage_per_building.has(bldg):
				damage_per_building[bldg] = dmg
			else:
				damage_per_building[bldg] = max(damage_per_building[bldg], dmg)

	for bldg in damage_per_building.keys():
		var dmg = damage_per_building[bldg]
		var result = _apply_damage(bldg, dmg)

		# If the building is still standing after this, see if it catches
		# fire.
		if not result["died"]:
			for building_coord in bldg.tiles:
				var hbc = _hash_coord(building_coord)
				if onFire.has(hbc):
					continue

				var dist_factor = (building_coord - local_landing_point).length() / 5
				var flam_factor = 0.01 * bldg.flammability
				var chance_to_catch_fire = flam_factor * exp(
					-(1 - flam_factor) * dist_factor)
				if randf() < chance_to_catch_fire:
					onFire[hbc] = BurnInfo.new()
					onFire[hbc].timeRemaining = 3.0
					environmental.set_cell(building_coord, 0, Vector2(0, 0))


func handle_burn(location: Vector2, heat: int) -> void:
	# Find those tiles within the heat radius of the event.
	var center_coords = buildings.local_to_map(buildings.to_local(location))
	var burn_mask = generate_circle_points(center_coords, heat)

	for point in burn_mask:
		var p_hashed = _hash_coord(point)
		if buildingInfos.has(p_hashed) and not onFire.has(p_hashed):
			# roll to see how likely it is this building to catch fire.
			var dist_factor = (point - center_coords).length() / heat
			var flam_factor = 0.01 * buildingInfos[p_hashed].flammability
			var chance_to_catch_fire = flam_factor * exp(
				-(1 - flam_factor) * dist_factor)
			if randf() < chance_to_catch_fire:
				onFire[p_hashed] = BurnInfo.new()
				onFire[p_hashed].timeRemaining = 3.0
				environmental.set_cell(point, 0, Vector2(0, 0))


func handle_world_burn(locations: PackedVector2Array, heats: PackedInt32Array) -> void:
	print("Handling ", len(locations), " burning spots")
	for i in range(len(locations)):
		var loc = locations[i]
		var heat = heats[i]

		handle_burn(loc, heat)


################################################################################
#                              UTILITY FUNCTIONS                               #
################################################################################
func _hash_coord(coord: Vector2i) -> String:
	return "%d_%d" % [coord[0], coord[1]]


func _decode_hash(hs: String) -> Vector2i:
	var ords = hs.split("_")
	return Vector2i(ords[0].to_int(), ords[1].to_int())


func generate_circle_points(center: Vector2i, radius: int) -> Array:
	var points = []
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if Vector2(x, y).length() <= radius:
				points.append(Vector2i(x, y) + center)
	return points


# Populates the buildingInfos dictionary. Performs the following functions:
# - Figure out where all the multi-tile buildings are and populate buildingInfo
#   properties accordingly
func construct_building_infos():
	for coords in buildings.get_used_cells():
		var coords_i = Vector2i(coords)
		var hc = _hash_coord(coords_i)
		if buildingInfos.has(hc):
			continue
		var tiledata = buildings.get_cell_tile_data(coords)
		var newInfo = BuildingInfo.new()
		newInfo.health = tiledata.get_custom_data("startingHealth")
		newInfo.flammability = 25
		newInfo.tiles = generate_footprint(coords_i)

		for pt in newInfo.tiles:
			buildingInfos[_hash_coord(pt)] = newInfo


func generate_footprint(point: Vector2i) -> Array:
	var explored = {}
	var queue = [point]
	var min_x = point[0]
	var max_x = point[0]
	var min_y = point[1]
	var max_y = point[1]

	var x = Vector2i(2, 0)
	var y = Vector2i(0, 2)

	while len(queue) > 0:
		var current: Vector2i = queue.pop_back()
		min_x = min(min_x, current[0])
		max_x = max(max_x, current[0])
		min_y = min(min_y, current[1])

		var explore_type = buildings.get_cell_tile_data(current).get_custom_data("neighbors")

		var cell_left: Vector2i = current
		var cell_right: Vector2i = current

		if explore_type == 0:
			continue

		elif explore_type == 1:
			cell_left = current + x

		elif explore_type == 2:
			cell_left = current + y

		elif explore_type == 3:
			cell_right = current + x

		elif explore_type == 4:
			cell_left = current - x
			cell_right = current + x

		elif explore_type == 5:
			cell_left = current + y
			cell_right = current + x

		elif explore_type == 6:
			cell_right = current - y

		elif explore_type == 7:
			cell_left = current - x
			cell_right = current - y

		elif explore_type == 8:
			cell_left = current + y
			cell_right = current - y

		explored[current] = true
		if not explored.has(cell_left):
			queue.append(cell_left)
		if not explored.has(cell_right):
			queue.append(cell_right)

	# At this point, we'll be able to figure out all points in
	# the rectangle.
	var rectpoints = []
	for xcoord in range(min_x, max_x + 1):
		for ycoord in range(min_y, max_y + 1):
			rectpoints.append(Vector2i(xcoord, ycoord))

	return rectpoints
