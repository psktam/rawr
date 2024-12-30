extends Node2D

const DC = preload("res://scripts/damage_coordinator.gd")
var SP = preload("res://scripts/sprite_poser.gd").new()
const COM = preload("res://scripts/resources.gd")
const PM = preload("res://scripts/policeman.gd")
const SPEED = 10.0
var health = 100
@onready var navigator: NavigationAgent2D = $navigator
@onready var cmder: CharacterBody2D = $"../../cmder"
@onready var popos: Node2D = $"../police"
@onready var navlayer = NPCUtils.get_nav_layer(self)
# Map enemy node -> location Vector2
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var attacker: Node2D = null

enum State {
	IDLE,
	FLEEING,
	WALKING,
	STAREDOWN
}

# Stateful variables
@export var state: State = State.IDLE
var next_state: State = State.IDLE
# This variable will be set to true if it's the first cycle in a given state.
# Useful for processing transitory behavior. States should never set this 
# variable themselves, and you should pretty much never read entering_set
var prev_state: State = State.IDLE
var prev_physics_state: State = prev_state

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
	next_state = target_state


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
		var flee_target = NPCUtils.pick_random_target(
			navlayer,
			navigator,
			5, 
			self.position,
			self.position + flee_dir * 100,
			3	
		)
		navigator.set_target_position(flee_target)

	var next_pos = navigator.get_next_path_position()
	var new_vel = global_position.direction_to(next_pos) * SPEED * 1.1
	display_direction = SP.get_view_name(new_vel.angle() * 180.0 / PI)
	var movement_delta = SPEED * delta * 1.1
	global_position = global_position.move_toward(
		global_position + new_vel, movement_delta
	)


func _process_fleeing(delta: float) -> void:
	animated_sprite_2d.animation = "walk-%d" % display_direction
	animated_sprite_2d.play()

	if time_in_state_s >= flee_dur:
		transition_to_state(State.IDLE)


################################################################################
#						  State-dispatching functions						   #
################################################################################
func _ready() -> void:
	var damage_controller: DC = $"/root/game".damage_controller
	damage_controller.BEAM_LANDING.connect(_on_beam_landing)
	damage_controller.METEOR_LANDING.connect(_on_meteor_landing)


func _physics_process(delta: float) -> void:
	_track_me()
	if state == State.IDLE:
		_physics_process_idle(delta)
	elif state == State.FLEEING:
		_physics_process_fleeing(delta)

	prev_physics_state = state


func _process(delta: float) -> void:
	if health <= 0:
		print("I'm dying, I'm dying, what a world, what a world")
		self.queue_free()

	if state == State.IDLE:
		_process_idle(delta)
	elif state == State.FLEEING:
		_process_fleeing(delta)

	prev_state = state
	state = next_state


################################################################################
#						   Signal dispatching functions						   #
################################################################################
func _on_beam_landing(landing_point: Vector2) -> void:
	threat_tracker.add_ephemeral_threat(landing_point, 15)


func _on_meteor_landing(landing_point: Vector2, landing_base_damage: int) -> void:
	threat_tracker.add_ephemeral_threat(landing_point, landing_base_damage)
	

################################################################################
#					   Utility functions for this class only					#
################################################################################
func _track_me():
	var dist2 = NPCUtils.tilemap_dist2(
		navlayer, self.global_position, cmder.global_position)
	if dist2 <= 4:
		threat_tracker.add_new_threat(cmder, 5)
	else:
		threat_tracker.remove_threat(cmder)


func inflict_damage(attacker_: Node2D, damage: int) -> void:
	print("Ow, you hurt me for ", damage, " damage")
	health -= damage
	attacker = attacker_

	# Add the attacker as a threat
	threat_tracker.add_ephemeral_threat(
		attacker_.global_position,
		10
	)
