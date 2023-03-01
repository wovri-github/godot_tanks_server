extends Projectile



func _on_Fireball_body_entered(_body):
	explode()

func explode():
	for body in $ExplosionArea.get_overlapping_bodies():
		kill(body)
	die()

func kill(body):
	if body.is_in_group("Players"): 
		if owner_id != int(body.name) and main_n.player_data.has(owner_id):
			main_n.player_data[int(owner_id)].Score.Kills += 1
		var _name = name
		body.die(_name, owner_id)
	if body.is_in_group("Projectile"):
		body.die()