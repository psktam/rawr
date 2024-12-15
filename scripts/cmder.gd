extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -400.0

# States
const WALKING = "walking"
const IDLE = "idle"
const BASIC_ATTACK = "basic_attack"
var SP = preload("res://scripts/sprite_poser.gd").new()

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export_category("Custom properties")
@export var state: String = IDLE
@export var entering: bool = true
@export var hud_reference: CanvasLayer
var display_direction: int = 0
var navregion: NavigationRegion2D
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

################################################################################
#   					 Code to manage character body motion				   #
################################################################################
func _stop_moving() -> void:
	navigation_agent_2d.set_target_position(self.position)

################################################################################
#   					       Everything else								   #
################################################################################

# Okay, let's make an actual state machine here. In each state, physics_process
# and process and input will all be doing different things.
func _transition_to_state(target_state: String) -> void:
	state = target_state
	entering = true


func _check_mouse_click(click: InputEventMouseButton) -> bool:
	"""
	Indicates whether or not the mouse click was in the playing field or on the
	menu.
	"""
	return click.position.x < get_viewport_rect().size.x - 250


# ------- idle state
func _input_idle(event: InputEvent) -> void:
	"""
	This function should really just focus on setting outputs and transition
	to states, rather than directly handling behaviors. Those attitudes will
	be dealt with in the relevant _xxx_process functions.
	"""
	if event is InputEventMouseButton and _check_mouse_click(event):
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_released():
			navigation_agent_2d.set_target_position(get_global_mouse_position())
			_transition_to_state(WALKING)

		elif (
			event.button_index == MOUSE_BUTTON_LEFT and 
			event.is_released() and 
			hud_reference.attack_controller.ready_for_attack()
		):
			if hud_reference.attack_controller.fire(get_global_mouse_position()):
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
	if event is InputEventMouseButton and _check_mouse_click(event):
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_released():
			navigation_agent_2d.set_target_position(get_global_mouse_position())
		elif (
			event.button_index == MOUSE_BUTTON_LEFT and 
			event.is_released() and 
			hud_reference.attack_controller.ready_for_attack()
		):
			if hud_reference.attack_controller.fire(get_global_mouse_position()):
				_transition_to_state(BASIC_ATTACK)
	elif event is InputEventKey:
		if event.keycode == KEY_S:
			_transition_to_state(IDLE)

func _physics_process_walking(delta: float) -> void:
	entering = false
	
	# Do not query when the map has never synchronized and is empty.
	if NavigationServer2D.map_get_iteration_id(navigation_agent_2d.get_navigation_map()) == 0:
		return
	
	if not navigation_agent_2d.is_navigation_finished():
		var next_path_position = navigation_agent_2d.get_next_path_position()
		var new_velocity = global_position.direction_to(next_path_position) * SPEED
		velocity = new_velocity
		move_and_slide()
	else: 
		self.velocity = Vector2.ZERO
		_transition_to_state(IDLE)

func _process_walking(delta: float) -> void:
	display_direction = SP.get_view_name(velocity.angle() * 180.0 / PI)
	animated_sprite_2d.animation = "walk-%d" % display_direction
	animated_sprite_2d.play()


# ------- basic attack state
func _input_basic_attack(event: InputEvent) -> void:
	if event is InputEventMouseButton and _check_mouse_click(event):
		if event.button_index == MOUSE_BUTTON_RIGHT:
			navigation_agent_2d.set_target_position(get_global_mouse_position())


func _physics_process_basic_attack(delta: float) -> void:
	self.velocity = Vector2.ZERO

func _process_basic_attack(delta: float) -> void:
	if entering:
		var ac = hud_reference.attack_controller
		var target_location = ac.targets[ac.selected_attack]
		display_direction = SP.get_view_name((target_location - self.position).angle() * 180.0 / PI)
		# Make the character face the direction of the click
		animated_sprite_2d.animation = "idle-%d" % display_direction
		animated_sprite_2d.play()

	if hud_reference.attack_controller.can_walk():
		if navigation_agent_2d.is_navigation_finished():
			_transition_to_state(IDLE)
		else:
			_transition_to_state(WALKING)


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
	if entering:
		entering = false

func _ready() -> void:
	entering = true
	_stop_moving()
