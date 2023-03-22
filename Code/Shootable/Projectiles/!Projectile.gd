extends RigidBody2D
class_name Projectile

signal wall_collided(bullet_stance)

var common_s = {
	"Speed": null,
	"Reload": null,
	"LifeTime": null,
} setget set_common_s
var creation_time = OS.get_ticks_msec()
var general_info = preload("res://Code/Shootable/ShootableInfo.gd").new()
onready var main_n = $"/root/Main"



func get_data():
	var projectile_info = {
		"P": get_position(),
		"R": get_rotation(),
		"V": get_linear_velocity(),
		"DT": creation_time + common_s.LifeTime*1000
	}
	projectile_info.merge(general_info.get_info())
	return projectile_info


func setup(_owner_id, _spawn_point, _spawn_rotation, _ammo_type, is_frag = false):
	general_info.set_info(_owner_id, name, _ammo_type, is_frag)
	position =_spawn_point
	rotation = _spawn_rotation
	set_common_s(GameSettings.Dynamic.Ammunition[_ammo_type])
	add_to_group("Projectiles")
	if is_frag:
		set_frag()

func set_common_s(ammo_s):
	for setting in common_s:
		common_s[setting] = ammo_s[setting]

func set_frag():
	var frag_s = GameSettings.Dynamic.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag
	common_s.LifeTime *= frag_s.LifetimeMultiplayer
	common_s.Speed *= frag_s.Speed
	set_scale(scale * frag_s.Scale)


func _ready():
	set_movement()
	$LifeTime.start(common_s.LifeTime)

func set_movement():
	var velocity = Vector2(0, -common_s.Speed).rotated(rotation)
	set_linear_velocity(velocity)


func _on_Projectile_body_entered(body):
	if !body.is_in_group("Players"):
		if general_info.is_frag:
			return
		var bullet_stance = {
			"Name": name, 
			"Pos": get_position(), 
			"LV": get_linear_velocity(),
		}
		emit_signal("wall_collided", bullet_stance)
	else:
		var _name = name
		if general_info.is_frag:
			_name = null
		body.die({"KillerID" : str(general_info.get_info().PlayerID), "KilledID" : body.name, "AT" : general_info.get_info().AT, "PName" : _name})
		die()


func _on_LifeTime_timeout():
	die()

func die():
	queue_free()
