extends Node2D

const WORLD = preload("res://scenes/game.gd")

var speed = 500.0
var target_point: Vector2 = Vector2.ZERO
var lifetime_s: float = 4.0
var time_alive_s: float = 0.0
var world_ref: WORLD

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.position.x = target_point.x 
	self.position.y = target_point.y - lifetime_s * speed

func _physics_process(delta: float) -> void:
	self.position.y += speed * delta

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_alive_s += delta
	if time_alive_s >= lifetime_s:
		world_ref.SIG_METEOR_LANDED.emit(target_point)
		queue_free()
