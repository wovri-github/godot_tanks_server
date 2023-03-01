class_name GameSettings

const AMMO_TYPE = Ammunition.TYPES


static func get_paths():
	var properties: Array = []
	var path: Array = []
	_get_paths_recursion(null, get_settings(), properties, path)
	return properties

static func _get_paths_recursion(_key, dict, properties, path):
	if typeof(dict) != TYPE_DICTIONARY:
		properties.append(path.duplicate(true))
		return
	for key in dict:
		path.append(key)
		_get_paths_recursion(key, dict[key], properties, path)
		path.pop_back()

static func get_duplicate_settings():
	var settings = {
		"Tank": TANK,
		"Wreck": WRECK,
		"Ammunition": AMMUNITION,
	}
	return settings.duplicate(true)

static func get_settings():
	var settings = {
		"Tank": TANK,
		"Wreck": WRECK,
		"Ammunition": AMMUNITION,
	}
	return settings

const TANK = {
	"Speed" : 100.0,
	"RotationSpeed" : 2.0,
	"MaxAmmo" : 5,
	"BaseAmmoType" : Ammunition.TYPES.BULLET,
	"MaxAmmoTypes" : 3, # including default bullet
}
const WRECK = {
	"LifeTime" : 20,
}
const AMMUNITION = {
	AMMO_TYPE.BULLET:{
		"Speed" : 200,
	},
	AMMO_TYPE.ROCKET: {
		"Speed" : 200,
		"FollowSpeed" : 150,
	},
	AMMO_TYPE.FRAG_BOMB: {
		"Speed" : 200,
		"Count" : 30,
		"Frag":{
			"Speed" : 150,
			"Scale" : 0.5,
			"LifetimeMultiplayer" : 0.2,
			"Type" : NAN,
		},
	},
	AMMO_TYPE.LASER:{
		"Length" : 2000,
		"MaxBounces" : 15,
		"MaxWidth" : 5,
	},
	AMMO_TYPE.LASER_BULLET:{
		"Speed" : 200,
		"Length" : 50,
		"MaxBounces" : 15,
	},
	AMMO_TYPE.FIREBALL:{
		"Speed" : 200,
	},
}
