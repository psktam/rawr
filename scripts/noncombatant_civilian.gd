extends Node2D

var SP = preload("res://scripts/sprite_poser.gd").new()
const COM = preload("res://scripts/resources.gd")
const SPEED = 50.0
@onready var navigator: NavigationAgent2D = $navigator
@onready var body_area: Area2D = $bodyArea
@onready var vision_area: Area2D = $visionArea
@onready var cmder: CharacterBody2D = $"../cmder"
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

enum State {
	IDLE,
	FLEEING,
	WALKING,
	STAREDOWN
}

# Stateful variables
@export var state: State = State.IDLE
var entering: bool = false
var entering_set: bool = false
var sees_me: bool = false
var time_in_state_s: float = 0.0
var display_direction: int = 0


func transition_to_state(target_state: State) -> void:
	state = target_state
	entering = true
	entering_set = true


# ----------------------------- idle state -------------------------------------
func _physics_process_idle(delta: float) -> void:
	pass


func _process_idle(delta: float) -> void:
	animated_sprite_2d.animation = "idle-%d" % display_direction
	animated_sprite_2d.play()

	if sees_me:
		transition_to_state(State.FLEEING)


# ----------------------------- fleeing state ----------------------------------
func _path_length(path: PackedVector2Array) -> float:
	var length = 0.0
	if len(path) < 2:
		return length

	var start_pt = self.position
	for i in range(len(path)):
		length += (start_pt - path[i]).length()
		start_pt = path[i]

	return length


func _pick_new_fleeing_target(n_trials: int) -> PackedVector2Array:
	var nominal_target = (self.position - cmder.position).normalized() * 100
	# Jitter the target by a few points, and pick the one that leads to the 
	# shortest route.

	var shortest_path = NavigationServer2D.map_get_path(
		navigator.get_navigation_map(),
		self.position,
		nominal_target,
		true
	)
	var shortest_length = _path_length(shortest_path)
	
	for trial in range(n_trials):
		var new_path = NavigationServer2D.map_get_path(
			navigator.get_navigation_map(),
			self.position, 
			nominal_target + Vector2(randi() % 50, randi() % 50),
			true
		)
		var new_path_len = _path_length(new_path)

		if new_path_len < shortest_length:
			shortest_path = new_path
			shortest_length = new_path_len
	
	return shortest_path


func _physics_process_fleeing(delta: float) -> void:
	if not COM.map_initialized(navigator):
		return

	if entering:
		# Get a new place to run away to
		var flee_path = _pick_new_fleeing_target(5)
		navigator.set_target_position(
			(self.position - cmder.position).normalized() * 100 + 
			Vector2(randi() % 15, randi() % 15)
		)

	if not navigator.is_navigation_finished() and time_in_state_s < 5.0:
		var next_pos = navigator.get_next_path_position()
		var new_vel = global_position.direction_to(next_pos) * SPEED
		display_direction = SP.get_view_name(new_vel.angle() * 180.0 / PI)
		var movement_delta = SPEED * delta
		global_position = global_position.move_toward(
			global_position + new_vel, movement_delta
		)
	else:
		transition_to_state(State.FLEEING)


func _process_fleeing(delta: float) -> void:
	animated_sprite_2d.animation = "walk-%d" % display_direction
	animated_sprite_2d.play()
	
	if not sees_me:
		transition_to_state(State.IDLE)


################################################################################
# 							  Dispatching functions							   #
################################################################################
func _ready() -> void:
	pass # Replace with function body.


func _physics_process(delta: float) -> void:
	if state == State.IDLE:
		_physics_process_idle(delta)
	elif state == State.FLEEING:
		_physics_process_fleeing(delta)


func _process(delta: float) -> void:
	if state == State.IDLE:
		_process_idle(delta)
	elif state == State.FLEEING:
		_process_fleeing(delta)

	if entering:
		if not entering_set:
			entering = false
		else:
			entering_set = false
			time_in_state_s = 0.0
	else:
		time_in_state_s += delta




func _on_vision_area_area_entered(area: Area2D) -> void:
	if area.get_parent() == cmder:
		sees_me = true


func _on_vision_area_area_exited(area: Area2D) -> void:
	if area.get_parent() == cmder:
		sees_me = false
