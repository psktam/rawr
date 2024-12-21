# Emit this any time a burning object ticks over
signal BURN(location: Vector2, heat: int)

# Emit this anytime an explosion happens on the scene
signal EXPLOSION(location: Vector2, size: float, base_damage: int)

signal BEAM_LANDING(location: Vector2)
signal METEOR_LANDING(location: Vector2)