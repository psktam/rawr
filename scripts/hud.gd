extends CanvasLayer

@onready var menu_tray: ColorRect = $MenuTray
@onready var beam_button: Button = $BeamButton
@onready var meteor_button: Button = $MeteorButton
@onready var selection_highlight: ColorRect = $selectionHighlight

@export var menu_width: int = 250


# Track cooldowns
const BASIC_ATTACK_COOLDOWN_MS = 500
const METEOR_COOLDOWN_MS = 5000
const METEOR_NO_MOVE_DUR_MS = 500  # Character can walk after this time

const AC = preload("res://scripts/attack_controller.gd")
var attack_controller = AC.new()
@onready var attack_buttons = {
	AC.BASIC: beam_button,
	AC.METEOR: meteor_button
}
var cooldown_masks = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	beam_button.button_pressed = true
	beam_button.pressed.connect(func ():
		attack_controller.selected_attack = AC.BASIC
	)
	meteor_button.pressed.connect(func ():
		attack_controller.selected_attack = AC.METEOR
	)

	for attack_name in attack_controller.cooldowns.keys():
		var mask = Panel.new()
		mask.size.y = 0
		mask.size.x = attack_buttons[attack_name].size.x
		mask.position = Vector2(0, 0)

		cooldown_masks[attack_name] = mask
		attack_buttons[attack_name].add_child(mask)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_1:
			beam_button.pressed.emit()
		elif event.keycode == KEY_2:
			meteor_button.pressed.emit()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Manage the position of the menu tray
	var visible_area = get_viewport().get_visible_rect()

	menu_tray.size.x = menu_width
	menu_tray.size.y = visible_area.size.y
	
	menu_tray.position.x = visible_area.size.x - menu_tray.size.x
	menu_tray.position.y = 0

	# Position buttons
	beam_button.position.x = menu_tray.position.x + 5
	meteor_button.position.x = beam_button.position.x + beam_button.size.x + 5

	# Manage cooldowns
	attack_controller.tick_cooldowns(delta)

	# Move the attack selector to the relevant button
	selection_highlight.position = (
		attack_buttons[attack_controller.selected_attack].position - 
		Vector2(4, 4)
	)

	# Apply masks based on which attack is selected and which cooldowns are 
	# active.
	for attack_name in attack_controller.cooldowns.keys():
		var rem_pct = (
			float(attack_controller.cooldowns[attack_name]) / 
			float(attack_controller.MAX_COOLDOWNS_MS[attack_name])
		)

		cooldown_masks[attack_name].size.y = int(
			attack_buttons[attack_name].size.y * rem_pct
		)
