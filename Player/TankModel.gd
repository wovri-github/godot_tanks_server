extends KinematicBody2D

onready var wall = $Hitbox.duplicate(true)
onready var game_n = $"/root/Main/Game"

var score = 0
var player_name = "Player" # defined when spawning

func set_stance(_position, _rotation):
	position = _position
	$"%Hitbox".rotation = _rotation

func rotate_turret(turret_rotation):
	$"%Turret".rotation = turret_rotation

func get_bullet_spawn() -> Vector2:
	return $"%BulletSpawn".get_global_position()

func die(projectile_name):
	var static_body2d = StaticBody2D.new()
	static_body2d.name = name
	static_body2d.position = get_global_position()
	static_body2d.rotation = $Hitbox.get_global_rotation()
	Transfer.send_player_destroyed(\
			int(name), static_body2d.position, static_body2d.rotation, projectile_name)
	static_body2d.add_child(wall)
	game_n.spawn_wall(static_body2d)
	$"/root/Main".dc(int(name))
	queue_free()
