extends Projectile

var s = GameSettings.Dynamic.Ammunition[Ammunition.TYPES.FIREBALL]


func _on_Fireball_body_entered(_body):
	explode()

func explode():
	for body in $ExplosionArea.get_overlapping_bodies():
		kill(body)
	die()

func kill(body):
	if body.is_in_group("Players"): 
		if !body.is_inside_tree():
			return
		var _name = name
		body.die({"KillerID" : str(general_info.get_info().PlayerID), "KilledID" : body.name, "AT" : general_info.get_info().AT, "PName" : _name})
	if body.is_in_group("Projectiles"):
		body.die()
