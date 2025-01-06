# Emit this any time a burning object ticks over
# location: source of the burn event, in global coordinates
# heat: how hot the flame is. It indicates the furthest distance the fire 
#       can affect other entities, in terms of tilemap coordinates. So if 
#       heat = 1, it can affect tiles up to 1 tile away. heat=10 means it 
#       can affect tiles up to 10 tiles away, in a rough approximation of a 
#       circle
signal BURN(location: Vector2, heat: int)

# Similar to the BURN signal. It indicates a burning event for the whole 
# level.
signal WORLD_BURN(locations: PackedVector2Array)

# Emit this anytime an explosion happens on the scene
signal EXPLOSION(location: Vector2, size: float, base_damage: int)

signal BEAM_LANDING(location: Vector2)
signal METEOR_LANDING(location: Vector2, landing_base_damage: int)
