extends Node



const TANK = {
	"SPEED" : 100.0,
	"ROTATION_SPEED" : 2.0,
	"MAX_AMMO" : 5,
	"BASE_AMMO_TYPE" : Ammunition.TYPES.BULLET,
	"MAX_AMMO_TYPES" : 3, # including default bullet
	"CORPSE_LIFE_TIME" : 20,
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

const AMMUNITION = {
	"BULLET":{
		"SPEED" : 200,
	},
	"ROCKET": {
		"SPEED" : 200,
		"FOLLOW_SPEED" : 150,
	},
	"FRAG_BOMB": {
		"SPEED" : 200,
		"COUNT" : 30,
		"FRAG":{
			"SPEED" : 150,
			"SCALE" : 0.5,
			"LIFETIME_MULTIPLIER" : 0.2,
			"TYPE" : Ammunition.TYPES.BULLET,
		},
	},
	"LASER_BEAM":{
		"LENGTH" : 2000,
		"MAX_BOUNCES" : 15,
		"MAX_WIDTH" : 5,
	},
	"LASER_BULLET":{
		"SPEED" : 200,
		"LENGTH" : 50,
		"LASER_MAX_BOUNCES" : 15,
	},
	"FIREBALL":{
		"SPEED" : 200,
	},
}
