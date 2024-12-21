extends Node2D

const BEAM_ATTACK = preload("res://scenes/beam_attack.tscn")
const METEOR_ATTACK = preload("res://scenes/meteor_attack.tscn")

@onready var attacks_go_here: Node2D = $attacksGoHere
@onready var cmder = $cmder
@onready var target_cursor: AnimatedSprite2D = $targetCursor
@onready var basic_attack_cursor: AnimatedSprite2D = $basicAttackCursor
@onready var meteor_attack_cursor: AnimatedSprite2D = $meteorAttackCursor
@onready var player_camera: Camera2D = $cmder/playerCamera
@onready var hud: CanvasLayer = $HUD
@onready var level: Node2D = $level
var damage_controller = preload("res://scripts/damage_coordinator.gd").new()

var cursor_map = {}

const ZOOM_LEVELS = [
	0.25,
	0.25,
	0.5,
	0.5,
	1.0,
	1.0,
	1.5,
	1.5,
	2.0,
	2.0
]
var zoom_idx = 4

var base_cursor = load("res://sprites/cursors/basic.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_custom_mouse_cursor(base_cursor)
	cursor_map[hud.AC.BASIC] = basic_attack_cursor
	cursor_map[hud.AC.METEOR] = meteor_attack_cursor

	# Wire things up to the damage controller
	hud.attack_controller.SIG_BEAM_FIRED.connect(func(target):
		var beam = BEAM_ATTACK.instantiate()
		beam.from_point = cmder.position
		beam.to_point = target
		attacks_go_here.add_child(beam)
	)

	hud.attack_controller.SIG_METEOR_FIRED.connect(func(target):
		var meteor = METEOR_ATTACK.instantiate()
		meteor.target_point = target
		attacks_go_here.add_child(meteor)
	)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_idx = min(len(ZOOM_LEVELS) - 1, zoom_idx + 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_idx = max(0, zoom_idx - 1)
		
		player_camera.zoom.x = ZOOM_LEVELS[zoom_idx]
		player_camera.zoom.y = ZOOM_LEVELS[zoom_idx]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	player_camera.position.x = int(hud.menu_width / 2)
	
	if cmder.state == cmder.IDLE:
		target_cursor.visible = false
	else:
		target_cursor.visible = true
		target_cursor.global_position = cmder.navigation_agent_2d.target_position
	
	for attack_name in hud.attack_controller.cooldowns:
		if attack_name == hud.AC.FLAME:
			continue
		elif hud.attack_controller.cooldowns[attack_name] > 0:
			cursor_map[attack_name].position = hud.attack_controller.targets[attack_name]
			cursor_map[attack_name].visible = true
		else:
			cursor_map[attack_name].visible = false
