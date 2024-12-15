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

