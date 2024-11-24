extends CharacterBody3D


const MAX_SPEED = 5.0
const JUMP_VELOCITY = 4.5
const LERP_VAL = 0.5

@onready var animation_tree: AnimationTree = $AnimationTree


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = lerp(velocity.x, direction.x * MAX_SPEED, LERP_VAL)
		velocity.z = lerp(velocity.z, direction.z * MAX_SPEED, LERP_VAL)
	else:
		velocity.x = lerp(velocity.x, 0.0, LERP_VAL)
		velocity.z = lerp(velocity.z, 0.0, LERP_VAL)

	animation_tree.set("parameters/BlendSpace1D/blend_position", velocity.length() / MAX_SPEED)

	move_and_slide()
