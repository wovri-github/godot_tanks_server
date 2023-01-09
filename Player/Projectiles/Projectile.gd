extends RigidBody2D
class_name Projectile

var player_path = NodePath("")


# [info] Server doesn't have ammo_left property
func _init():
	# collision and mask for every projectile
	set_collision_layer(2)
	set_collision_mask(7)

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
