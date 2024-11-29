extends Node2D

@onready var cmder = $cmder
@onready var target_cursor: AnimatedSprite2D = $targetCursor
@onready var basic_attack_cursor: AnimatedSprite2D = $basicAttackCursor
@onready var meteor_attack_cursor: AnimatedSprite2D = $meteorAttackCursor
@onready var player_camera: Camera2D = $cmder/playerCamera
@onready var hud: CanvasLayer = $HUD

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
		target_cursor.global_position = cmder.destination
	
	for attack_name in hud.attack_controller.cooldowns:
		if hud.attack_controller.cooldowns[attack_name] > 0:
			cursor_map[attack_name].position = hud.attack_controller.targets[attack_name]
			cursor_map[attack_name].visible = true
		else:
			cursor_map[attack_name].visible = false
