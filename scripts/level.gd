extends Node2D

const DC = preload("res://scripts/damage_coordinator.gd")

@onready var level_0: TileMapLayer = $Level0
@onready var buildings: TileMapLayer = $buildings
@onready var flames: TileMapLayer = $flames
@onready var navigation_region_2d: NavigationRegion2D = $NavigationRegion2D

var update_navmesh = false

# Maps tileMap coordinate -> health of the building on that tile
var buildingHealths = {}
# Maps tileMap coordinates -> fireball present at that location
var fireBalls = {}

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
	var damage_controller: DC = $"/root/game".damage_controller
	damage_controller.BEAM_LANDING.connect(process_beam_landing)
	damage_controller.METEOR_LANDING.connect(process_meteor_landing)

	for coords in buildings.get_used_cells():
		var starting_health = buildings.get_cell_tile_data(coords).\
			get_custom_data("startingHealth")

		if starting_health != 0:
			buildingHealths[coords] = starting_health


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if update_navmesh:
		navigation_region_2d.bake_navigation_polygon()
		update_navmesh = false


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
		damage_results = _apply_damage(point, 250)

		if damage_results["valid"] and damage_results["died"]:
			destroyed[point] = damage_results["data"]

	for coords in destroyed:
		buildings.erase_cell(coords)
		update_navmesh = true


func _apply_damage(cell_coords: Vector2i, damage: int) -> Dictionary:
	if not buildingHealths.has(cell_coords):
		return {"valid": false, "died": false}
	
	print("Doing damage at ", cell_coords)
	buildingHealths[cell_coords] -= damage
	if buildingHealths[cell_coords] <= 0:
		buildingHealths.erase(cell_coords)
	
		return {
			"valid": true, 
			"died": true, 
			"data": buildings.get_cell_tile_data(cell_coords)
		}
	return {
		"valid": true,
		"died": false
	}


func process_meteor_landing(landing_point: Vector2):
	# This is how you destroy parts of the map!
	var local_landing_point = self.to_local(landing_point)
	var tile_coords = level_0.local_to_map(local_landing_point)
	var tile_source = level_0.get_cell_source_id(tile_coords)
	if tile_source != -1:
		level_0.set_cell(tile_coords, tile_source, Vector2(0, 0))
