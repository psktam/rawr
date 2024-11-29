const BASIC = "basic"
const METEOR = "meteor"

var cooldowns = {
	BASIC: 0,
	METEOR: 0
}
var targets = {
	BASIC: Vector2.ZERO,
	METEOR: Vector2.ZERO
}

var selected_attack = "basic"

const MAX_COOLDOWNS_MS = {
	BASIC: 250,
	METEOR: 5000
}
const WALK_STOP_DURATIONS_MS = {
	BASIC: 250,
	METEOR: 500
}


func tick_cooldowns(delta_s: float):
	for attack_name in cooldowns.keys():
		cooldowns[attack_name] = max(
			0,
			cooldowns[attack_name] - int(delta_s * 1000)
		)


func fire(target: Vector2) -> bool: 
	"""
	If the selected attack is ready to use, set its target location and start 
	the cooldown. Return an indication that the initiation was successful.
	"""
	if cooldowns[selected_attack] <= 0:
		cooldowns[selected_attack] = MAX_COOLDOWNS_MS[selected_attack]
		targets[selected_attack] = target
		return true
	return false


func can_walk() -> bool:
	return cooldowns[selected_attack] <= (
		MAX_COOLDOWNS_MS[selected_attack] - 
		WALK_STOP_DURATIONS_MS[selected_attack]
	)


func ready_for_attack() -> bool:
	return cooldowns[selected_attack] <= 0
