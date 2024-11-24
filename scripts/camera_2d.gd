extends Camera2D

@onready var move_n_region: Area2D = $moveNRegion
@onready var move_s_region: Area2D = $moveSRegion
@onready var move_w_region: Area2D = $moveWRegion
@onready var move_e_region: Area2D = $moveERegion
@onready var move_nw_region: Area2D = $moveNWRegion
@onready var move_sw_region: Area2D = $moveSWRegion
@onready var move_se_region: Area2D = $moveSERegion
@onready var move_ne_region: Area2D = $moveNERegion

@onready var Direction = get_node("/root/Resources").Direction
@onready var _panDirection = Direction.NONE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print(get_viewport().get_mouse_position())
	
	
func printDirection(d):
	if d == Direction.N:
		print("Moving north")
	elif d == Direction.S:
		print("Moving south")
	elif d == Direction.E:
		print("Moving east")
	elif d == Direction.W:
		print("Moving west")
	elif d == Direction.NE:
		print("Moving northeast")
	elif d == Direction.NW:
		print("Moving northwest")
	elif d == Direction.SE:
		print("Moving southeast")
	elif d == Direction.SW:
		print("Moving southwest")


func stopMoving():
	_panDirection = Direction.NONE
	print("Stopping")

func _on_move_n_region_mouse_entered() -> void:
	_panDirection = Direction.N


func _on_move_n_region_mouse_exited() -> void:
	stopMoving()


func _on_move_s_region_mouse_entered() -> void:
	_panDirection = Direction.S


func _on_move_s_region_mouse_exited() -> void:
	stopMoving()
	

func _on_move_w_region_mouse_entered() -> void:
	_panDirection = Direction.W


func _on_move_w_region_mouse_exited() -> void:
	stopMoving()


func _on_move_e_region_mouse_entered() -> void:
	_panDirection = Direction.E


func _on_move_e_region_mouse_exited() -> void:
	stopMoving()


func _on_move_nw_region_mouse_entered() -> void:
	_panDirection = Direction.NW


func _on_move_nw_region_mouse_exited() -> void:
	stopMoving()


func _on_move_sw_region_mouse_entered() -> void:
	_panDirection = Direction.SW


func _on_move_sw_region_mouse_exited() -> void:
	stopMoving()


func _on_move_se_region_mouse_entered() -> void:
	_panDirection = Direction.SE


func _on_move_se_region_mouse_exited() -> void:
	stopMoving()


func _on_move_ne_region_mouse_entered() -> void:
	_panDirection = Direction.NE


func _on_move_ne_region_mouse_exited() -> void:
	stopMoving()
