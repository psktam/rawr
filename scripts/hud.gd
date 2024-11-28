extends CanvasLayer

@onready var menu_tray: ColorRect = $MenuTray
@onready var beam_button: Button = $BeamButton
@onready var meteor_button: Button = $MeteorButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var visible_area = get_viewport().get_visible_rect()

	menu_tray.size.x = 250
	menu_tray.size.y = visible_area.size.y
	
	menu_tray.position.x = visible_area.size.x - menu_tray.size.x
	menu_tray.position.y = 0

	# Position buttons
	beam_button.position.x = menu_tray.position.x + 5
	meteor_button.position.x = beam_button.position.x + beam_button.size.x + 5
