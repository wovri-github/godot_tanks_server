extends Reference
class_name Shootablex



static func get_data(owner_id, _name, position, rotation, velocity, ammo_type, death_time):
	var pck = {
		"PlayerID": owner_id,
		"ID": _name,
		"P": position,
		"R": rotation,
		"V": velocity,
		"AT": ammo_type,
		"DT": death_time # DeathTime
	}
	return pck

