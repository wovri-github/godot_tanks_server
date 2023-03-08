extends KinematicBody2D

signal player_destroyed(slayer_id, wreck_data)


var s = GameSettings.TANK
var arms= {
		s.BaseAmmoType: INF,
}
var player_name = "Player" # defined when spawning
var player_color = Color.blue # defined when spawning
var kills: int = 0



func setup(player_id, spawn_point, color, _settings):
	s = _settings
	name = str(player_id)
	player_color = color
	position = spawn_point
	

func pick_up_ammo_box(ammo_type) -> bool:
	if !arms.has(ammo_type) and arms.size() < s.MaxAmmoTypes:
		arms[ammo_type] = 1
		return true
	elif arms.has(ammo_type):
		arms[ammo_type] += 1
		return true
	return false

func subtract_ammo_type(ammo_type) -> int:
	if !arms.has(ammo_type):
		print("[Game]: Player ", name, " want to shoot without ammo!")
		return FAILED
	arms[ammo_type] -= 1
	if arms[ammo_type] == 0:
		arms.erase(ammo_type)
	return OK

func set_stance(_position, _rotation):
	position = _position
	$"%Hitbox".rotation = _rotation

func rotate_turret(turret_rotation):
	$"%Turret".rotation = turret_rotation

func die(kill_event_data={"KillerID" : "", "KilledID" : "", "AT" : NAN, "PName" : ""}):
	var wreck_data = {
		"ID": int(name),
		"Pos": get_global_position(),
		"Rot": $Hitbox.get_global_rotation(),
		"Color": player_color,
		"Kills": kills,
		"LT": GameSettings.WRECK.LifeTime
	}
	get_parent().remove_child(self)
	emit_signal("player_destroyed", kill_event_data.KillerID, wreck_data)
	Transfer.send_player_destroyed(wreck_data, kill_event_data)
	queue_free()
