extends Node2D

const DC = preload("res://scripts/damage_coordinator.gd")

@onready var damage_controller: DC = $"/root/game".damage_controller
var speed = 500.0
var target_point: Vector2 = Vector2.ZERO
var lifetime_s: float = 4.0
var time_alive_s: float = 0.0

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
		damage_controller.METEOR_LANDING.emit(target_point, 2000)
		queue_free()
