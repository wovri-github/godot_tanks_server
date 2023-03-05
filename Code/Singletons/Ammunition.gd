extends Reference
class_name Ammunition

enum TYPES{BULLET, ROCKET, FRAG_BOMB, LASER, LASER_BULLET, FIREBALL}


const _ammo_box_texture = {
	TYPES.BULLET: preload("res://textures/bullet.png"),
	TYPES.ROCKET: preload("res://textures/rocket.png"),
	TYPES.FRAG_BOMB: preload("res://textures/bullet.png"),
	TYPES.LASER: preload("res://textures/laser_box.png"),
	TYPES.LASER_BULLET: preload("res://textures/laser_bullet_box.png"),
	TYPES.FIREBALL: preload("res://textures/fireball_box.png")
}

const shootable = {
	TYPES.BULLET: "res://Code/Shootable/Projectiles/Bullet.tscn",
	TYPES.ROCKET: "res://Code/Shootable/Projectiles/Rocket.tscn",
	TYPES.FRAG_BOMB: "res://Code/Shootable/Projectiles/FragBomb.tscn",
	TYPES.LASER: "res://Code/Shootable/Laser.tscn",
	TYPES.LASER_BULLET: "res://Code/Shootable/Projectiles/LaserBullet.tscn",
	TYPES.FIREBALL: "res://Code/Shootable/Projectiles/Fireball.tscn"
}

static func get_box_texture(name):
	return _ammo_box_texture[name]
