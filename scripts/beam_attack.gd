extends Node2D

const DC = preload("res://scripts/damage_coordinator.gd")
const MAX_SPEED = 2500.0
const ACCEL = 5000.0
const MED_MAX_DISPLACEMENT = 40.0
const SMALL_MAX_DISPLACEMENT = 80.0

var from_point: Vector2 = Vector2.ZERO
var to_point: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO
var last_position: Vector2
var max_range: float = 500.0
var dist_to_travel: float
var distance_traveled: float = 0.0
var time_alive: float = 0.0

@onready var beam_blob_small: Sprite2D = $"Beam-blob"
@onready var beam_blob_med: Sprite2D = $"Beam-blob-1"
@onready var beam_blob_big: Sprite2D = $"Beam-blob-0"
@onready var damage_controller: DC = $"/root/game".damage_controller

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.position = from_point
	self.last_position = from_point
	beam_blob_small.position = Vector2.ZERO
	beam_blob_med.position = Vector2.ZERO
	beam_blob_big.position = Vector2.ZERO
	dist_to_travel = min(max_range, (from_point - to_point).length())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	direction = (to_point - from_point).normalized()
	distance_traveled += (self.position - last_position).length()
	last_position = self.position

	self.position += velocity * delta
	velocity += direction * ACCEL * delta

	# Trail out the smaller blobs behind the big blob
	var anti_dir = -direction
	beam_blob_med.position = MED_MAX_DISPLACEMENT * (
		1 - pow(10, -time_alive)
	) * anti_dir
	beam_blob_small.position = SMALL_MAX_DISPLACEMENT * (
		1 - pow(10, -time_alive)
	) * anti_dir

	time_alive += delta
	if distance_traveled >= dist_to_travel:
		damage_controller.BEAM_LANDING.emit(self.global_position)
		queue_free()


func _process(delta: float) -> void:
	pass
