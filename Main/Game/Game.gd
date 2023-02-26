extends Node2D

var settings = GameSettings.get_duplicate_settings()
var tank_tscn = preload("res://Player/TankModel.tscn")
const AMMO_TYPES = Ammunition.TYPES
var projectiles_tscn = {
	AMMO_TYPES.BULLET: preload("res://Shootable/Projectiles/Bullet.tscn"),
	AMMO_TYPES.ROCKET: preload("res://Shootable/Projectiles/Rocket.tscn"),
	AMMO_TYPES.FRAG_BOMB: preload("res://Shootable/Projectiles/FragBomb.tscn"),
	AMMO_TYPES.LASER: preload("res://Shootable/Laser.tscn"),
	AMMO_TYPES.LASER_BULLET: preload("res://Shootable/Projectiles/LaserBullet.tscn"),
	AMMO_TYPES.FIREBALL: preload("res://Shootable/Projectiles/Fireball.tscn")
}
onready var projectile_n = $Projectiles
onready var players_n = $Players


func _ready():
	settings.WRECK.LIFE_TIME -= 1

func spawn_player(player_id, spawn_point, color):
	var player_inst = tank_tscn.instance()
	player_inst.setup(player_id, spawn_point, color, settings.TANK)
	$Players.add_child(player_inst)

func despawn_player(player_id):
	if !$Players.has_node(str(player_id)):
		return
	var player_path: String = "Players/" + str(player_id)
	get_node(player_path).queue_free()

func spawn_wreck(corpse_inst):
	$Objects.call_deferred("add_child", corpse_inst)

func spawn_bullet(player_id, turret_rotation, ammo_type):
	if !is_player_alive(player_id):
		return null
	var player_n = players_n.get_node(str(player_id))
	if player_n.subtract_ammo_type(ammo_type) != OK:
		return null
	player_n.rotate_turret(turret_rotation)
	var bullet_inst = projectiles_tscn[ammo_type].instance()
	bullet_inst.setup(player_n, ammo_type, settings.AMMUNITION[ammo_type])
	projectile_n.add_child(bullet_inst, true)
	return bullet_inst.get_data()


func _physics_process(_delta):
	var players_stance = get_parent().playerS_stance
	if players_stance.empty() == true:
		return
	for player_stance in players_stance.values():
		update_player_position(player_stance)

func update_player_position(player_stance):
	if !is_player_alive(player_stance.ID):
		return
	get_node("Players/" + str(player_stance.ID)).call_deferred(\
			"set_stance", player_stance.P, player_stance.R)


#---------Verification----------
func is_player_alive(player_id) -> bool:
	if has_node("Players/" + str(player_id)):
		return true
	return false
