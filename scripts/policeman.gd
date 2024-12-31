extends Node2D

const DC = preload("res://scripts/damage_coordinator.gd")
var SP = preload("res://scripts/sprite_poser.gd").new()
const COM = preload("res://scripts/resources.gd")
const NC = preload("res://scripts/noncombatant_civilian.gd")
const SPEED = 10.0
@onready var navigator: NavigationAgent2D = $navigator
@onready var body_area: Area2D = $bodyArea
@onready var vision_area: Area2D = $visionArea
@onready var cmder: CharacterBody2D = $"/root/game/world/cmder"
@onready var civvies: Node2D = $"/root/game/world/civilians"
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var navlayer = NPCUtils.get_nav_layer(self)
var health = 100
var attacker: Node2D = null

enum State {
	IDLE,
	FLEEING,
	WALKING,
	STAREDOWN,
	PURSUING,
	ATTACKING
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
@onready var target_tracker = Targets.new(
	self,
	2,
	3,
	navlayer,
	func (_tt): return 10
)
var CC = preload("res://scripts/cyclical_functions.gd").new()


func is_new_state() -> bool:
	return state != prev_state


func is_new_physics_state() -> bool:
	return state != prev_physics_state


func transition_to_state(target_state: State) -> void:
	next_state = target_state


# ----------------------------- idle state -------------------------------------
func _physics_process_idle(delta: float) -> void:
	CC.cyclical_call(
		"target_recalc",
		2000,
		func (): target_tracker.refresh_targets([civvies])
	)


func _process_idle(delta: float) -> void:
	animated_sprite_2d.animation = "idle-%d" % display_direction
	animated_sprite_2d.play()

	if threat_tracker.has_threats():
		transition_to_state(State.FLEEING)
	elif target_tracker.has_target():
		transition_to_state(State.STAREDOWN)


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


# ---------------------------- staredown state ---------------------------------
func _physics_process_staredown(delta: float) -> void:
	# First make sure that the target is still valid. The non-physics process
	# function will handle the state transition
	if target_tracker.get_current_target() == null:
		return

	CC.cyclical_call(
		"target_recalc",
		2000,
		func (): target_tracker.refresh_targets([civvies])
	)

	# Always just make sure we're facing the target
	display_direction = SP.get_view_name(
		(
			target_tracker.get_current_target().global_position -
			global_position
		).angle() * 180 / PI
	)


func _process_staredown(delta: float) -> void:
	# First, just make sure that the target is still valid
	if target_tracker.get_current_target() == null:
		transition_to_state(State.IDLE)
		return

	elif NPCUtils.tilemap_dist2(
		NPCUtils.get_nav_layer(self),
		global_position,
		target_tracker.get_current_target().global_position
	) < 4:
		transition_to_state(State.PURSUING)

	animated_sprite_2d.animation = "idle-%d" % display_direction
	animated_sprite_2d.play()


# ---------------------------- attacking state ---------------------------------
var attack_timer = 0.0
func _physics_process_pursuing(delta: float) -> void:
	if not target_tracker.has_target():
		return

	# Start chasing the target
	if not COM.map_initialized(navigator):
		return

	var next_pos: Vector2
	var movement_delta = SPEED * delta

	CC.cyclical_call(
		"target_recalc",
		2000,
		func (): target_tracker.refresh_targets([civvies])
	)
	CC.cyclical_call(
		"nav_update",
		5000,
		func (): navigator.set_target_position(
				target_tracker.get_current_target().global_position
		)
	)
	next_pos = navigator.get_next_path_position()

	var new_vel = global_position.direction_to(next_pos) * SPEED
	display_direction = SP.get_view_name(new_vel.angle() * 180.0 / PI)
	global_position = global_position.move_toward(
		global_position + new_vel, movement_delta
	)


func _process_pursuing(delta: float) -> void:
	animated_sprite_2d.animation = "walk-%d" % display_direction
	animated_sprite_2d.play()

	var dist2_target = NPCUtils.tilemap_dist2(
		navlayer,
		global_position,
		target_tracker.get_current_target().global_position
	)
	var inrange = CC.t_on(
		"in-attacking-range",
		dist2_target <= 1,
		1000,
		is_new_state()
	)

	if not target_tracker.has_target():
		transition_to_state(State.IDLE)
		return

	if inrange:
		transition_to_state(State.ATTACKING)


# ---------------------------- attacking state ---------------------------------
func _physics_process_attacking(delta: float) -> void:
	if not target_tracker.has_target():
		return

	display_direction = SP.get_view_name(
		(
			target_tracker.get_current_target().global_position -
			global_position
		).angle() * 180 / PI
	)


func _process_attacking(delta: float) -> void:
	# In the future, we'll play the attacking animation here instead. If we need
	# to reorient in the middle of the animation, we'll need to keep track of
	# which frame we were on and make the switch.
	animated_sprite_2d.animation = "idle-%d" % display_direction
	animated_sprite_2d.play()

	if not target_tracker.has_target():
		transition_to_state(State.IDLE)
		return
	elif NPCUtils.tilemap_dist2(
			NPCUtils.get_nav_layer(self),
			self.global_position,
			target_tracker.get_current_target().global_position
	) >= 1:
		transition_to_state(State.PURSUING)
		return

	# Otherwise, we actually attack our target
	CC.cyclical_call(
		"attack",
		1000,
		func (): 
			if target_tracker.get_current_target() is NC:
				target_tracker.get_current_target().inflict_damage(
					self, 34)
	)



################################################################################
#						  State-dispatching functions						   #
################################################################################
func _ready() -> void:
	var damage_controller: DC = $"/root/game".damage_controller
	damage_controller.BEAM_LANDING.connect(_on_beam_landing)
	damage_controller.METEOR_LANDING.connect(_on_meteor_landing)


func _physics_process(delta: float) -> void:
	if state == State.IDLE:
		_physics_process_idle(delta)
	elif state == State.FLEEING:
		_physics_process_fleeing(delta)
	elif state == State.STAREDOWN:
		_physics_process_staredown(delta)
	elif state == State.PURSUING:
		_physics_process_pursuing(delta)
	elif state == State.ATTACKING:
		_physics_process_attacking(delta)

	prev_physics_state = state


func _process(delta: float) -> void:
	if health <= 0:
		self.queue_free()
		return

	if state == State.IDLE:
		_process_idle(delta)
	elif state == State.FLEEING:
		_process_fleeing(delta)
	elif state == State.STAREDOWN:
		_process_staredown(delta)
	elif state == State.PURSUING:
		_process_pursuing(delta)
	elif state == State.ATTACKING:
		_process_attacking(delta)

	prev_state = state
	state = next_state


################################################################################
#						   Signal dispatching functions						   #
################################################################################
func _on_beam_landing(landing_point: Vector2) -> void:
	# Only respond to the threat if it's in range
	var landing_dist2 = NPCUtils.tilemap_dist2(
		navlayer, global_position, landing_point
	)

	if landing_dist2 > 9:
		return

	threat_tracker.add_ephemeral_threat(landing_point, 15)
	inflict_damage(cmder, 100 / max(1, landing_dist2))


func _on_meteor_landing(landing_point: Vector2, landing_base_damage: int) -> void:
	var landing_dist2 = NPCUtils.tilemap_dist2(
		navlayer, global_position, landing_point
	)

	if landing_dist2 > 25:
		return

	threat_tracker.add_ephemeral_threat(landing_point, landing_base_damage)
	inflict_damage(cmder, landing_base_damage / max(1, landing_dist2))

################################################################################
#						   Internal utility functions                          #
################################################################################
func inflict_damage(attacker_: Node2D, damage: int) -> void:
	health -= damage
	attacker = attacker_

	# Add the attacker as a threat
	threat_tracker.add_ephemeral_threat(
		attacker_.global_position,
		10
	)
