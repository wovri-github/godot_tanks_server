extends KinematicBody2D

onready var wall = $Hitbox.duplicate(true)
onready var map_node = $"/root/Main/Map"



func set_stance(_position, _rotation):
	position = _position
	$"%Hitbox".rotation = _rotation

func rotate_turret(turret_rotation):
	$"%Turret".rotation = turret_rotation

func get_bullet_spawn() -> Vector2:
	return $"%BulletSpawn".get_global_position()

func die():
	var static_body2d = StaticBody2D.new()
	static_body2d.name = name
	static_body2d.position = get_global_position()
	static_body2d.rotation = $Hitbox.get_global_rotation()
	Transfer.send_player_destroyed(int(name), static_body2d.position, static_body2d.rotation)
	static_body2d.add_child(wall)
	map_node.spawn_wall(static_body2d)
	$"/root/Main".dc(int(name))
	queue_free()
