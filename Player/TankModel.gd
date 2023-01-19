extends KinematicBody2D

const CORPSE_LIFE_TIME = 20

onready var main_n = $"/root/Main"
onready var game_n = $"/root/Main/Game"

var special_ammo = {
	Ammunition.TYPES.BULLET : INF,
	Ammunition.TYPES.ROCKET : 0,
	Ammunition.TYPES.FRAG_BOMB : 0,
	Ammunition.TYPES.LASER: INF
}
var player_name = "Player" # defined when spawning


	

func set_stance(_position, _rotation):
	position = _position
	$"%Hitbox".rotation = _rotation

func rotate_turret(turret_rotation):
	$"%Turret".rotation = turret_rotation

#func get_bullet_spawn() -> Vector2:
#	return $"%BulletSpawn".get_global_position()

func die(projectile_name, slayer_id):
	var static_body2d = StaticBody2D.new()
	static_body2d.name = name
	static_body2d.position = get_global_position()
	static_body2d.rotation = $Hitbox.get_global_rotation()
	static_body2d.add_to_group("Corpse")
	
	var lifeTime = Timer.new()
	lifeTime.wait_time = CORPSE_LIFE_TIME
	lifeTime.autostart = true
	static_body2d.add_child(lifeTime)
	lifeTime.connect("timeout",static_body2d,"queue_free")
	
	Transfer.send_player_destroyed(\
			int(name), static_body2d.position, static_body2d.rotation, slayer_id, projectile_name)
	static_body2d.add_child($Hitbox.duplicate(true))
	game_n.spawn_wall(static_body2d)
	queue_free()
