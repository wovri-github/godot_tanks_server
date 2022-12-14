extends RigidBody2D

var player_path = null



func _on_LifeTime_timeout():
	queue_free()



func _on_Bullet_body_entered(body):
	if body.is_in_group("Player"):
		body.die()
		queue_free()
