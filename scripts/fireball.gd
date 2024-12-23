extends Node2D

const DC = preload("res://scripts/damage_coordinator.gd")

var max_burn_time_s = 5.0
var lifetime_s = 0.0
var tick_dur_s = 1.0
var ticks_so_far = 0
var target_loc: Vector2
@onready var damage_controller: DC = $"/root/game".damage_controller


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	lifetime_s += delta
	position = (position + target_loc) * 0.5
	if lifetime_s > (ticks_so_far * tick_dur_s):
		ticks_so_far += 1
		damage_controller.BURN.emit(global_position, 2)

	if lifetime_s > max_burn_time_s:
		queue_free()
