extends RigidBody2D
class_name Projectile

const BULLET_SPEED = 200
var owner_id = NAN
var is_frag_bomb_frag = false
onready var main_n = $"/root/Main"


# [info] Server doesn't have ammo_left property

func setup(player : KinematicBody2D) -> Dictionary:
	owner_id = int(player.name)
	var point = player.get_node("%BulletSpawn")
	position = point.global_position
	var velocity = Vector2.UP.rotated(point.global_rotation) * BULLET_SPEED
	set_linear_velocity(velocity)
	return {"SP": position,"V": velocity}

func _on_LifeTime_timeout():
	die()

func die():
	queue_free()

func _on_Projectile_body_entered(body):
	if !body.is_in_group("Players"): 
		return
	if owner_id != int(body.name) and main_n.player_data.has(owner_id):
		main_n.player_data[int(owner_id)].Score.Kills += 1
	var _name = name
	if is_frag_bomb_frag:
		_name = null
	body.die(_name, owner_id)
	queue_free()
