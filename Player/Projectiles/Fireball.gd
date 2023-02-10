extends Projectile


func die():
	.die()


func _on_Fireball_body_entered(body):
	explode()
	.die()
	
	
func kill(body):
	if !body.is_in_group("Players"): 
		return
	if owner_id != int(body.name) and main_n.player_data.has(owner_id):
		main_n.player_data[int(owner_id)].Score.Kills += 1
	var _name = name
	body.die(_name, owner_id)
	
	
func explode():
	for body in $ExplosionArea.get_overlapping_bodies():
			kill(body)
	.die()
