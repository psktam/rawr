extends Node2D

const DC = preload("res://scripts/damage_coordinator.gd")
var SP = preload("res://scripts/sprite_poser.gd").new()
const COM = preload("res://scripts/resources.gd")
const NC = preload("res://scripts/noncombatant_civilian.gd")
const SPEED = 10.0
@onready var navigator: NavigationAgent2D = $navigator
@onready var body_area: Area2D = $bodyArea
@onready var vision_area: Area2D = $visionArea
@onready var cmder: CharacterBody2D = $"../cmder"
# Map enemy node -> location Vector2
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

enum State {
	IDLE,
	FLEEING,
	WALKING,
	STAREDOWN
}

# Stateful variables
@export var state: State = State.IDLE
# This variable is set to True anytime this node processes a signal. We may need
# to sometimes force transitions into other states based on the signal.
var signal_override = false
# This variable will be set to true if it's the first cycle in a given state.
# Useful for processing transitory behavior. States should never set this 
# variable themselves, and you should pretty much never read entering_set
var prev_state: State = State.IDLE
var prev_physics_state: State = prev_state

var ticker = 0
# Time spent in the current state so far
var time_in_state_s: float = 0.0

# How long to flee for before recalculating a new target
var flee_dur: float = 5.0

var current_threat: Threats.ThreatInfo = null

var display_direction: int = 0
var threat_tracker = Threats.new()


func is_new_state() -> bool:
	return state != prev_state


func is_new_physics_state() -> bool:
	return state != prev_physics_state


func transition_to_state(target_state: State) -> void:
	state = target_state


# ----------------------------- idle state -------------------------------------
func _physics_process_idle(delta: float) -> void:
	pass


func _process_idle(delta: float) -> void:
	animated_sprite_2d.animation = "idle-%d" % display_direction
	animated_sprite_2d.play()

	if threat_tracker.has_threats():
		transition_to_state(State.FLEEING)


# ----------------------------- fleeing state ----------------------------------
func _physics_process_fleeing(delta: float) -> void:
	if not COM.map_initialized(navigator):
		return

	if is_new_physics_state() or threat_tracker.has_new_threat:
		var flee_dir = threat_tracker.get_flee_direction(global_position)
		# Get a new place to run away to
		var flee_target = NPCUtils.pick_random_nav_dest(
			NPCUtils.get_nav_layer(self),
			navigator,
			5, 
			self.position,
			self.position + flee_dir * 100,
			3	
		)
		navigator.set_target_position(flee_target)

	var next_pos = navigator.get_next_path_position()
	var new_vel = global_position.direction_to(next_pos) * SPEED
	display_direction = SP.get_view_name(new_vel.angle() * 180.0 / PI)
	var movement_delta = SPEED * delta
	global_position = global_position.move_toward(
		global_position + new_vel, movement_delta
	)


func _process_fleeing(delta: float) -> void:
	animated_sprite_2d.animation = "walk-%d" % display_direction
	animated_sprite_2d.play()

	if time_in_state_s >= flee_dur or navigator.is_navigation_finished():
		transition_to_state(State.IDLE)


################################################################################
#						  State-dispatching functions						   #
################################################################################
func _ready() -> void:
	var damage_controller: DC = $"/root/game".damage_controller
	damage_controller.BEAM_LANDING.connect(_on_beam_landing)
	damage_controller.METEOR_LANDING.connect(_on_meteor_landing)


func _physics_process(delta: float) -> void:
	ticker += 1
	if state == State.IDLE:
		_physics_process_idle(delta)
	elif state == State.FLEEING:
		_physics_process_fleeing(delta)

	prev_physics_state = state


func _process(delta: float) -> void:
	if state == State.IDLE:
		_process_idle(delta)
	elif state == State.FLEEING:
		_process_fleeing(delta)

	prev_state = state


################################################################################
#						   Signal dispatching functions						   #
################################################################################
func _on_vision_area_area_entered(area: Area2D) -> void:
	if area.get_parent() == cmder:
		threat_tracker.add_new_threat(cmder, 10)


func _on_vision_area_area_exited(area: Area2D) -> void:
	if area.get_parent() == cmder:
		threat_tracker.remove_threat(cmder)


func _on_beam_landing(landing_point: Vector2) -> void:
	threat_tracker.add_ephemeral_threat(landing_point, 15)


func _on_meteor_landing(landing_point: Vector2, landing_base_damage: int) -> void:
	threat_tracker.add_ephemeral_threat(landing_point, landing_base_damage)
	

################################################################################
#					   Utility functions for this class only					#
################################################################################
# Assess this threat against the current threat, and set it if it's moar 
# threatening
