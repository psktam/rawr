extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -400.0
const MOVING = "moving"
const STILL = "still"

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var state: String = STILL
@export var destination: Vector2 = self.position
var display_direction: int = 0


func _ready() -> void:
	destination = self.position


func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton) and (event.button_index == MOUSE_BUTTON_RIGHT) and event.is_released():
		destination = get_global_mouse_position()

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
	
	
func _physics_process(delta: float) -> void:
	var raw_delta = destination - self.position
	var direction = raw_delta.normalized()
	
	if raw_delta.length() > 5:
		self.velocity = direction * SPEED
		state = MOVING
		display_direction = get_view_name(self.velocity.angle() * 180.0 / PI)
	else:
		self.velocity = Vector2.ZERO
		state = STILL
		
	move_and_slide()


func _process(delta: float) -> void:
	if state == MOVING:
		var animation_name = "walk-%d" % display_direction
		animated_sprite_2d.animation = animation_name
		animated_sprite_2d.play()
	elif state == STILL:
		var animation_name = "idle-%d" % display_direction
		animated_sprite_2d.animation = animation_name
		animated_sprite_2d.play()
