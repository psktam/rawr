extends Node2D

const MAX_SPEED = 1000.0
const ACCEL = 1000.0

var from_point: Vector2 = Vector2.ZERO
var to_point: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.ZERO
var lifetime_s: float = 10.0
var time_alive: float = 0.0

@onready var beam_blob: Sprite2D = $"Beam-blob"
@onready var beam_blob_0: Sprite2D = $"Beam-blob-0"
@onready var beam_blob_1: Sprite2D = $"Beam-blob-1"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.position = from_point
	beam_blob.position = Vector2.ZERO
	beam_blob_0.position = Vector2.ZERO
	beam_blob_1.position = Vector2.ZERO


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	direction = (to_point - from_point).normalized()

	self.position += velocity * delta
	velocity += direction * ACCEL * delta

	# Trail out the smaller blobs behind the big blob
	var anti_dir = -direction
	beam_blob_1.position += anti_dir * 1
	beam_blob.position += anti_dir * 2

func _process(delta: float) -> void:
	time_alive += delta
	if time_alive >= lifetime_s:
		queue_free()
