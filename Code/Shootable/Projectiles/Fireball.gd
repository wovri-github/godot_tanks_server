extends Projectile



func _on_Fireball_body_entered(_body):
	explode()

func explode():
	for body in $ExplosionArea.get_overlapping_bodies():
		kill(body)
	die()

func kill(body):
	if body.is_in_group("Players"): 
		if owner_id != int(body.name) and Data.players.has(owner_id):
			Data.players[int(owner_id)].Score.Kills += 1
		var _name = name
		body.die({"KillerID" : str(owner_id), "KilledID" : body.name, "AT" : ammo_type, "PName" : _name})
	if body.is_in_group("Projectile"):
		body.die()
