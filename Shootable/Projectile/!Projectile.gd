extends RigidBody2D
class_name Projectile

var s: Dictionary
var owner_id = NAN
var ammo_type = NAN
var is_frag_bomb_frag = false
var position_1 = position
onready var main_n = $"/root/Main"



func get_data():
	var pck = Shootable.get_data(
			owner_id, 
			name,
			get_position(),
			get_rotation(),
			get_linear_velocity(),
			ammo_type
	)
	return pck
#	var pck = {
#		"PlayerID": owner_id,
#		"ID": name,
#		"SP": get_position(),
#		"AT": ammo_type,
#		"V": get_linear_velocity(),
#		"ST": OS.get_ticks_msec() #Spawn Time
#	}
#	return pck


func setup(player_n : KinematicBody2D, _ammo_type, _settings):
	s = _settings
	owner_id = int(player_n.name)
	ammo_type = _ammo_type
	var point = player_n.get_node("%BulletSpawn")
	position = point.global_position
	var velocity = Vector2.UP.rotated(point.global_rotation) * _settings.SPEED
	set_linear_velocity(velocity)


func _on_Projectile_body_entered(body):
	if !body.is_in_group("Players"):
		if is_frag_bomb_frag:
			return
		var bullet_stance = {
			"Name": name, 
			"Pos": get_position(), 
			"LV": get_linear_velocity(),
		}
		main_n.add_bullet_stance_on_collision(bullet_stance)
	else:
		if owner_id != int(body.name) and main_n.player_data.has(owner_id):
			main_n.player_data[int(owner_id)].Score.Kills += 1
		var _name = name
		if is_frag_bomb_frag:
			_name = null
		body.die(_name, owner_id)
		queue_free()


func _on_LifeTime_timeout():
	die()

func die():
	queue_free()