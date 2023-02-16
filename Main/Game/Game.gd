extends Node2D

var player_model = preload("res://Player/TankModel.tscn")
enum AMMO_TYPES {BULLET, ROCKET, FRAG_BOMB, LASER, LASER_BULLET, FIREBALL}
var projectiles_modelS = {
	AMMO_TYPES.BULLET: preload("res://Player/Projectiles/Bullet.tscn"),
	AMMO_TYPES.ROCKET: preload("res://Player/Projectiles/Rocket.tscn"),
	AMMO_TYPES.FRAG_BOMB: preload("res://Player/Projectiles/FragBomb.tscn"),
	AMMO_TYPES.LASER: preload("res://Player/Projectiles/LaserBeam.tscn"),
	AMMO_TYPES.LASER_BULLET: preload("res://Player/Projectiles/LaserBullet.tscn"),
	AMMO_TYPES.FIREBALL: preload("res://Player/Projectiles/Fireball.tscn")
}
const BULLET_SPEED = 200



func spawn_player(player_id, spawn_point):
	var player_inst = player_model.instance()
	player_inst.name = str(player_id)
	player_inst.player_name = "No_Need"
	player_inst.position = spawn_point
	$Players.add_child(player_inst)

func despawn_player(player_id):
	if !$Players.has_node(str(player_id)):
		return
	var player_path: String = "Players/" + str(player_id)
	get_node(player_path).queue_free()

func spawn_wall(corpse_inst):
	$Objects.call_deferred("add_child", corpse_inst)

func spawn_bullet(player_id, turret_rotation, ammo_slot):
	if !is_player_alive(player_id):
		return null
	var player_n = get_node("Players/" + str(player_id))
	if player_n.special_ammo.size() <= ammo_slot:
		print("[Game]: Player ", player_id, " want to shoot without ammo!")
		return null
	player_n.rotate_turret(turret_rotation)
	var bullet_inst = projectiles_modelS[player_n.special_ammo[ammo_slot].type].instance()
	var bullet_data : Dictionary = bullet_inst.setup(player_n)
	bullet_data["Name"] = bullet_inst.name
	bullet_data["AT"] = player_n.special_ammo[ammo_slot].type
	bullet_data["ST"] = OS.get_ticks_msec() #Spawn Time
	player_n.special_ammo[ammo_slot].amount -= 1
	if player_n.special_ammo[ammo_slot].amount == 0:
		player_n.special_ammo.pop_at(ammo_slot)
	
	$Projectiles.add_child(bullet_inst, true)
	return bullet_data


func _physics_process(_delta):
	var playerS_stance = get_parent().playerS_stance
	if playerS_stance.empty() == true:
		return
	for player_id in playerS_stance:
		update_player_position(player_id, playerS_stance[player_id])

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
