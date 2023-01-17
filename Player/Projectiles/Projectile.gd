extends RigidBody2D
class_name Projectile

const BULLET_SPEED = 200

var player_path = NodePath("")


# [info] Server doesn't have ammo_left property

func setup(player : KinematicBody2D) -> Dictionary:
	player_path = player.get_path()
	var point = player.get_node("%BulletSpawn")
	position = point.global_position
	var velocity = Vector2.UP.rotated(point.global_rotation) * BULLET_SPEED
	set_linear_velocity(velocity)
	return {"SP": position,"V": velocity}

func _on_LifeTime_timeout():
	die()

func die():
	queue_free()

func _on_Projectile_body_entered(body):
	if !body.is_in_group("Players"): return
	var player = get_node_or_null(player_path)
	if !(player == null):
		player.score += 1
		Transfer.send_score_update(player.name, player.score)
	body.die(name)
	queue_free()
