extends Node2D

var player_model = preload("res://Player/TankModel.tscn")
enum AMMO_TYPES {BULLET, ROCKET, FRAG_BOMB}
var projectiles_modelS = {
	AMMO_TYPES.BULLET: preload("res://Player/Projectiles/Bullet.tscn"),
	AMMO_TYPES.ROCKET: null,
	AMMO_TYPES.FRAG_BOMB: null,
}
const BULLET_SPEED = 200
var last_spawn_point = 0
onready var spawn_pointS = [$SpawnPoints/SP1.position, $SpawnPoints/SP2.position]



func get_spawn_position() -> Vector2:
	var spawn_point = spawn_pointS[last_spawn_point]
	last_spawn_point += 1
	last_spawn_point %= spawn_pointS.size()
	return spawn_point

func spawn_player(player_id, spawn_point):
	var player_inst = player_model.instance()
	player_inst.name = str(player_id)
	player_inst.position = spawn_point
	$Players.add_child(player_inst)

func despawn_player(player_id):
	if !$Players.has_node(str(player_id)):
		return
	var player_path: String = "Players/" + str(player_id)
	get_node(player_path).die()

func spawn_wall(object):
	$Objects.call_deferred("add_child", object)

func spawn_bullet(player_id, turret_rotation, ammo_type):
	if !is_player_alive(player_id):
		return
	get_node("Players/" + str(player_id)).rotate_turret(turret_rotation)
	var spawn_position = get_node("Players/" + str(player_id)).get_bullet_spawn()
	var bullet_inst = projectiles_modelS[ammo_type].instance()
	var velocity = Vector2.UP.rotated(turret_rotation) * BULLET_SPEED
	bullet_inst.position = spawn_position
	bullet_inst.set_linear_velocity(velocity)
	$Projectiles.add_child(bullet_inst)
	return {"SP": spawn_position,"V": velocity, "AT": ammo_type}


func _on_Processing_timer_timeout():
	var playerS_stance = get_parent().playerS_stance
	if playerS_stance.empty() == true:
		return
	for player_id in playerS_stance:
		update_player_position(player_id, playerS_stance[player_id])

#func _physics_process(delta):
#	var playerS_stance = get_parent().playerS_stance
#	if playerS_stance.empty() == true:
#		return
#	for player_id in playerS_stance:
#		update_player_position(player_id, playerS_stance[player_id])

func update_player_position(player_id, player_stance):
	if !is_player_alive(player_id):
		return
	get_node("Players/" + str(player_id)).call_deferred(\
			"set_stance",player_stance.P, player_stance.R)


#---------Verification----------
func is_player_alive(player_id) -> bool:
	if has_node("Players/" + str(player_id)):
		return true
	return false
