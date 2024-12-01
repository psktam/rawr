extends Node2D

@onready var level_0: TileMapLayer = $Level0


func level_layers() -> Dictionary:
	var layer_map = {}
	for child in get_children():
		if child is TileMapLayer:
			layer_map[child.name] = child
	return layer_map


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func process_meteor_landing(landing_point: Vector2):
	# This is how you destroy parts of the map!
	var local_landing_point = self.to_local(landing_point)
	var tile_coords = level_0.local_to_map(local_landing_point)
	var tile_source = level_0.get_cell_source_id(tile_coords)
	var tile_atlas_coords = level_0.get_cell_atlas_coords(tile_coords)
	print("Meteor landed here")
	print("source: ", tile_source)
	print("atlas coords: ", tile_atlas_coords)
	if tile_source != -1:
		level_0.set_cell(tile_coords, tile_source, Vector2(0, 0))
