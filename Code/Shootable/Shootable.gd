extends Reference
class_name Shootable



static func get_data(owner_id, _name, position, rotation, velocity, ammo_type):
	var pck = {
		"PlayerID": owner_id,
		"ID": _name,
		"P": position,
		"R": rotation,
		"V": velocity,
		"AT": ammo_type,
		"ST": OS.get_ticks_msec() #Spawn Time
	}
	return pck

