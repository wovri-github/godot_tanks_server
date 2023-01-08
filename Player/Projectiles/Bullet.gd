extends RigidBody2D

var player_path = NodePath("")



func _on_LifeTime_timeout():
	queue_free()



func _on_Bullet_body_entered(body):
	if !body.is_in_group("Player"): return
	var player = get_node_or_null(player_path)
	if !(player == null):
		player.score += 1
		Transfer.send_score_update(player.name, player.score)
	body.die(name)
	queue_free()
