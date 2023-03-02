class_name GameSettings

const AMMO_TYPE = Ammunition.TYPES
const MAX_UPGRADES = 3
const PERCENTAGE_OF_BASE_VALUE_PER_POINT = 0.1


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


const CAMERA = {
	"CAMERA_ZOOM_SPEED" : 0.3,
	"CAMERA_MAX_ZOOM_IN" : Vector2(0.1, 0.1),
	"CAMERA_MAX_ZOOM_OUT" : Vector2(2, 2),
}

const SPECATOR = {
	"CAMERA":{
		"ZOOM_SPEED" : 0.3,
		"MOVE_SPEED" : 50,
		"MAX_ZOOM_IN" : Vector2(0.1, 0.1),
		"MAX_ZOOM_OUT" : Vector2(100, 100),
	}
}

const INDICATORS = {
	"MAX_COUNT" : 5,
	"ARROW_MARGIN" : 20,
}
