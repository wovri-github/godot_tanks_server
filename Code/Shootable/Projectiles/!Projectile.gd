extends RigidBody2D
class_name Projectile

signal wall_collided(bullet_stance)

var owner_id = NAN
var ammo_type = NAN
var is_frag_bomb_frag = false
var spawn_point 
var spawn_rotation 
var death_time = OS.get_ticks_msec() + 10_000
onready var main_n = $"/root/Main"



func get_data():
	var pck = Shootable.get_data(
			owner_id, 
			name,
			get_position(),
			get_rotation(),
			get_linear_velocity(),
			ammo_type,
			death_time
	)
	return pck


func setup(_owner_id, _spawn_point, _spawn_rotation, _ammo_type):
	owner_id = _owner_id
	ammo_type = _ammo_type
	spawn_point =_spawn_point
	spawn_rotation = _spawn_rotation


func _on_Projectile_body_entered(body):
	if !body.is_in_group("Players"):
		if is_frag_bomb_frag:
			return
		var bullet_stance = {
			"Name": name, 
			"Pos": get_position(), 
			"LV": get_linear_velocity(),
		}
		emit_signal("wall_collided", bullet_stance)
	else:
		if owner_id != int(body.name) and Data.players.has(owner_id):
			Data.players[int(owner_id)].Score.Kills += 1
		var _name = name
		if is_frag_bomb_frag:
			_name = null
		body.die({"KillerID" : str(owner_id), "KilledID" : body.name, "AT" : ammo_type, "PName" : _name})
		queue_free()


func _on_LifeTime_timeout():
	die()

func die():
	queue_free()
