extends KinematicBody2D



func set_stance(_position, _rotation):
	position = _position
	$"%Hitbox".rotation = _rotation

func rotate_turret(turret_rotation):
	$"%Turret".rotation = turret_rotation

func get_bullet_spawn() -> Vector2:
	return $"%BulletSpawn".get_global_position()

func die():
	Transfer.send_depsawn_player(int(name))
	queue_free()
