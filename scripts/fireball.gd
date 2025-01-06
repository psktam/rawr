extends Node2D

const DC = preload("res://scripts/damage_coordinator.gd")

var max_burn_time_s = 1.5
var lifetime_s = 0.0
var tick_dur_s = 1.0
var ticks_so_far = 0
var travel_dir: Vector2 = Vector2.ZERO
var travel_speed = 2
var growth_rate = 2.0
var tick_ms_on_creation: int = 0
@onready var damage_controller: DC = $"/root/game".damage_controller


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	lifetime_s += delta
	global_position = global_position + travel_dir * travel_speed
	var scale_val = (
		Time.get_ticks_msec() - tick_ms_on_creation
	) * 0.001 * growth_rate + 1.0
	scale = Vector2(scale_val, scale_val)

	var remaining_life_pct = 1.0 - min(lifetime_s / max_burn_time_s, 1.0)
	modulate.a = remaining_life_pct

	if lifetime_s > (ticks_so_far * tick_dur_s):
		ticks_so_far += 1
		damage_controller.BURN.emit(
			global_position, 5 / max(lifetime_s * 3, 1)
		)

	if lifetime_s > max_burn_time_s:
		queue_free()
