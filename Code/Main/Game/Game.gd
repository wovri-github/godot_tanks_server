extends Node2D

signal player_destroyed(player_id, slayer_id, is_slayer_dead)
signal battle_over(alived_players)

const WRECK_TSCN = preload("res://Code/Objects/Wreck.tscn")
const TANK_TSCN = preload("res://Code/Player/TankModel.tscn")
const AMMO_TYPES = Ammunition.TYPES
const shootable_tscn = {
	AMMO_TYPES.BULLET: preload("res://Code/Shootable/Projectiles/Bullet.tscn"),
	AMMO_TYPES.ROCKET: preload("res://Code/Shootable/Projectiles/Rocket.tscn"),
	AMMO_TYPES.FRAG_BOMB: preload("res://Code/Shootable/Projectiles/FragBomb.tscn"),
	AMMO_TYPES.LASER: preload("res://Code/Shootable/NonProjectiles/Laser.tscn"),
	AMMO_TYPES.LASER_BULLET: preload("res://Code/Shootable/Projectiles/LaserBullet.tscn"),
	AMMO_TYPES.FIREBALL: preload("res://Code/Shootable/Projectiles/Fireball.tscn")
}

var player_upgrade_points: Dictionary
var bulletS_stance_on_collision: Array
onready var projectile_n = $Projectiles
onready var players_n = $Players
var rng = RandomNumberGenerator.new()


func _ready():
	var _err
	Transfer.network.connect("peer_disconnected", self , "_on_peer_disconnected")
	_err = Transfer.connect("recive_shoot", self, "_on_recive_shoot")
	_err = Transfer.connect("recive_charge_shoot", self, "_on_recive_charge_shoot")
	_err = Transfer.connect("recive_ammo_type_change", self, "_on_recive_ammo_type_change")


func spawn_player(player_id, spawn_point, color):
	var player_inst = TANK_TSCN.instance()
	player_inst.connect("player_destroyed", self, "_on_player_destroyed")
	player_inst.setup(player_id, spawn_point, color)
	$Players.add_child(player_inst)

func _on_player_destroyed(slayer_id, wreck_data):
	spawn_wreck(wreck_data)
	var _err = Data.playerS_stance.erase(wreck_data.ID)
	if wreck_data.ID != int(slayer_id) and Data.players.has(wreck_data.ID):
		Data.players[wreck_data.ID].Score.Kills += 1
	var is_slayer_dead = false
	if players_n.has_node(slayer_id):
		players_n.get_node(slayer_id).kills += 1
	else:
		is_slayer_dead = true
	emit_signal("player_destroyed", wreck_data, int(slayer_id), is_slayer_dead)

func spawn_wreck(wreck_data):
	var wreck_inst = WRECK_TSCN.instance()
	wreck_inst.setup(wreck_data)
	$Objects.call_deferred("add_child", wreck_inst)


func _on_recive_shoot(player_stance, ammo_type):
	update_player_position(player_stance)
	var bullet_data = spawn_bullet(player_stance.ID, player_stance.TR, ammo_type)
	if bullet_data != null:
		Transfer.send_shoot(player_stance.ID, bullet_data)
	else:
		Transfer.send_shoot_fail(player_stance.ID)

func spawn_bullet(player_id, turret_rotation, ammo_type):
	if !is_player_alive(player_id):
		return null
	var player_n = players_n.get_node(str(player_id))
	player_n.rotate_turret(turret_rotation)
	if player_n.shoot(ammo_type) != OK:
		return null
	var bullet_inst = shootable_tscn[ammo_type].instance()
	bullet_inst.name = str(rng.randi()) # just in case
	if ammo_type != Ammunition.TYPES.LASER:
		bullet_inst.connect("wall_collided", self, "_on_wall_collided")
	var position2d = player_n.get_node("%BulletSpawn")
	var spawn_point = position2d.global_position
	var spawn_rotation = position2d.global_rotation
	bullet_inst.setup(player_id, spawn_point, spawn_rotation, ammo_type)
	projectile_n.add_child(bullet_inst, true)
	var bullet_data = bullet_inst.get_data()
	bullet_data["ST"] =  OS.get_ticks_msec()
	return bullet_data

func _on_recive_charge_shoot(player_id, ammo_type):
	if player_charge_shoot(player_id, ammo_type):
		Transfer.send_player_charge(player_id, ammo_type)
	else:
		Transfer.send_shoot_fail(player_id)

func player_charge_shoot(player_id, ammo_type):
	if !is_player_alive(player_id):
		return false
	var player_n = players_n.get_node(str(player_id))
	return player_n.shoot_after_charging(ammo_type)


func _on_recive_ammo_type_change(player_id, ammo_type):
	if player_change_ammo_type(player_id, ammo_type):
		Transfer.send_player_turret_change(player_id, ammo_type)

func player_change_ammo_type(player_id, ammo_type):
	if !is_player_alive(player_id):
		return false
	var player_n = players_n.get_node(str(player_id))
	return player_n.change_ammo_type(ammo_type)


func _on_wall_collided(bullet_stance_on_collision):
	bulletS_stance_on_collision.append(bullet_stance_on_collision)
	#[info] When two bullets collide its better to send it in one file
	yield(get_tree(), "idle_frame")
	if bulletS_stance_on_collision.empty() == false:
		Transfer.send_shoot_bounce_state(bulletS_stance_on_collision, OS.get_ticks_msec())
		bulletS_stance_on_collision.clear()


func _physics_process(_delta):
	var players_stance = Data.playerS_stance
	if players_stance.empty() == true:
		return
	for player_stance in players_stance.values():
		update_player_position(player_stance)

func update_player_position(player_stance):
	if !is_player_alive(player_stance.ID):
		return
	get_node("Players/" + str(player_stance.ID)).call_deferred(\
			"set_stance", player_stance.P, player_stance.R)

#---------Getters----------
func get_alive_players() -> int:
	return players_n.get_child_count()

func get_alived_players_id() -> Array:
	var alived_players_id: Array = []
	for player in players_n.get_children():
		alived_players_id.append({"ID":int(player.name), "Kills":player.kills})
	return alived_players_id


#---------Verification----------
func is_player_alive(player_id) -> bool:
	if has_node("Players/" + str(player_id)):
		return true
	return false

	

#-----------Signals----------
func _on_peer_disconnected(player_id):
	yield(get_tree(), "idle_frame")
	if is_player_alive(player_id):
		players_n.get_node(str(player_id)).die()

#func _on_BattleTimer_timeout():
#	var alived_players_id: Array = []
#	for player in players_n.get_children():
#		alived_players_id.append({"ID":int(player.name), "Kills":player.kills})
#	emit_signal("battle_over", alived_players_id)
