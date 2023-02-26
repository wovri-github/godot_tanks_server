extends Resource
class_name GameSettings

const AMMO_TYPE = Ammunition.TYPES

static func get_duplicate_settings():
	var settings = {
		"TANK": TANK,
		"WRECK": WRECK,
		"AMMUNITION": AMMUNITION,
	}
	return settings.duplicate(true)

const TANK = {
	"SPEED" : 100.0,
	"ROTATION_SPEED" : 2.0,
	"MAX_AMMO" : 5,
	"BASE_AMMO_TYPE" : Ammunition.TYPES.BULLET,
	"MAX_AMMO_TYPES" : 3, # including default bullet
}
const WRECK = {
	"LIFE_TIME" : 20,
}
const AMMUNITION = {
	AMMO_TYPE.BULLET:{
		"SPEED" : 200,
	},
	AMMO_TYPE.ROCKET: {
		"SPEED" : 200,
		"FOLLOW_SPEED" : 150,
	},
	AMMO_TYPE.FRAG_BOMB: {
		"SPEED" : 200,
		"COUNT" : 30,
		"FRAG":{
			"SPEED" : 150,
			"SCALE" : 0.5,
			"LIFETIME_MULTIPLIER" : 0.2,
			"TYPE" : NAN,
		},
	},
	AMMO_TYPE.LASER:{
		"LENGTH" : 2000,
		"MAX_BOUNCES" : 15,
		"MAX_WIDTH" : 5,
	},
	AMMO_TYPE.LASER_BULLET:{
		"SPEED" : 200,
		"LENGTH" : 50,
		"LASER_MAX_BOUNCES" : 15,
	},
	AMMO_TYPE.FIREBALL:{
		"SPEED" : 200,
	},
}
