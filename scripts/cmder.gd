extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -400.0

# States
const WALKING = "walking"
const IDLE = "idle"
const BASIC_ATTACK = "basic_attack"

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var state: String = IDLE
@export var entering: bool = true
@export var destination: Vector2 = self.position
@export var target_location: Vector2 = self.position
var display_direction: int = 0

################################################################################
#   					 Code to manage character body motion				   #
################################################################################
func _inrange(n, d, u) -> bool:
	return (d < n) and (n <= u)


func get_view_name(direction_angle: float) -> int:
	if _inrange(direction_angle, -112.5, -67.5):
		return 0
	elif _inrange(direction_angle, -67.5, -22.5):
		return 45
	elif _inrange(direction_angle, -22.5, 22.5):
		return 90
	elif _inrange(direction_angle, 22.5, 67.5):
		return 135
	elif _inrange(direction_angle, 67.5, 112.5):
		return 180
	elif _inrange(direction_angle, 112.5, 157.5):
		return 225
	elif _inrange(direction_angle, -157.5, -112.5):
		return 315
	else:
		return 270


func _stop_moving() -> void:
	destination = self.position

################################################################################
#   					       Everything else								   #
################################################################################

# Okay, let's make an actual state machine here. In each state, physics_process
# and process and input will all be doing different things.
func _transition_to_state(target_state: String) -> void:
	state = target_state
	entering = true


# ------- idle state
func _input_idle(event: InputEvent) -> void:
	"""
	This function should really just focus on setting outputs and transition
	to states, rather than directly handling behaviors. Those attitudes will
	be dealt with in the relevant _xxx_process functions.
	"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_released():
			destination = get_global_mouse_position()
			_transition_to_state(WALKING)

		elif event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			target_location = get_global_mouse_position()

			_transition_to_state(BASIC_ATTACK)

func _physics_process_idle(delta: float) -> void:
	entering = false
	self.velocity = Vector2.ZERO

func _process_idle(delta: float) -> void:
	_stop_moving()
	entering = false

	# Just make sure that we're not actually doing anything
	animated_sprite_2d.animation = "idle-%d" % display_direction
	animated_sprite_2d.play()


# ------- walking state
func _input_walking(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_released():
			destination = get_global_mouse_position()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			target_location = get_global_mouse_position()
			_transition_to_state(BASIC_ATTACK)
	elif event is InputEventKey:
		if event.keycode == KEY_S:
			_transition_to_state(IDLE)

func _physics_process_walking(delta: float) -> void:
	entering = false

	var raw_delta = destination - self.position
	var direction = raw_delta.normalized()

	if raw_delta.length() > 5:
		self.velocity = direction * SPEED
	else: 
		self.velocity = Vector2.ZERO
		_transition_to_state(IDLE)

	move_and_slide()

func _process_walking(delta: float) -> void:
	display_direction = get_view_name(self.velocity.angle() * 180.0 / PI)
	animated_sprite_2d.animation = "walk-%d" % display_direction
	animated_sprite_2d.play()


# ------- basic attack state
func _input_basic_attack(event: InputEvent) -> void:
	pass

func _physics_process_basic_attack(delta: float) -> void:
	self.velocity = Vector2.ZERO

var time_basic_attack_entered: int
func _process_basic_attack(delta: float) -> void:
	if entering:
		time_basic_attack_entered = Time.get_ticks_msec()
		entering = false

	if (Time.get_ticks_msec() - time_basic_attack_entered) > 1000:
		_transition_to_state(IDLE)
		return

	display_direction = get_view_name((target_location - self.position).angle() * 180.0 / PI)
	# Make the character face the direction of the click
	animated_sprite_2d.animation = "idle-%d" % display_direction
	animated_sprite_2d.play()


################################################################################
# 							  Dispatching functions							   #
################################################################################
func _input(event: InputEvent) -> void:
	if state == IDLE:
		_input_idle(event)
	elif state == WALKING:
		_input_walking(event)
	elif state == BASIC_ATTACK:
		_input_basic_attack(event)
	else:
		print("Unrecognized input state %s" % state)


func _physics_process(delta: float) -> void:
	if state == IDLE:
		_physics_process_idle(delta)
	elif state == WALKING:
		_physics_process_walking(delta)
	elif state == BASIC_ATTACK:
		_physics_process_basic_attack(delta)
	else:
		print("Unrecognized physics state %s" % state)


func _process(delta: float) -> void:
	if state == IDLE:
		_process_idle(delta)
	elif state == WALKING:
		_process_walking(delta)
	elif state == BASIC_ATTACK:
		_process_basic_attack(delta)
	else:
		print("Unrecognized processing state: %s" % state)

func _ready() -> void:
	entering = true
	_stop_moving()




	
