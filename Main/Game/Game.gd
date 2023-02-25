extends Node2D

var settings = GameSettings
var tank_tscn = preload("res://Player/TankModel.tscn")
const AMMO_TYPES = Ammunition.TYPES
var projectiles_tscn = {
	AMMO_TYPES.BULLET: preload("res://Player/Projectiles/Bullet.tscn"),
	AMMO_TYPES.ROCKET: preload("res://Player/Projectiles/Rocket.tscn"),
	AMMO_TYPES.FRAG_BOMB: preload("res://Player/Projectiles/FragBomb.tscn"),
	AMMO_TYPES.LASER: preload("res://Player/Projectiles/Laser.tscn"),
	AMMO_TYPES.LASER_BULLET: preload("res://Player/Projectiles/LaserBullet.tscn"),
	AMMO_TYPES.FIREBALL: preload("res://Player/Projectiles/Fireball.tscn")
}
onready var projectile_n = $Projectiles
onready var players_n = $Players


func _ready():
	print(settings)
	#settings.AMMUNITION = 200
	print(settings.AMMUNITION[AMMO_TYPES.BULLET].SPEED)


func spawn_player(player_id, spawn_point, color):
	var player_inst = tank_tscn.instance()
	player_inst.name = str(player_id)
	player_inst.player_name = "No_Need"
	player_inst.player_color = color
	player_inst.position = spawn_point
	$Players.add_child(player_inst)


func despawn_player(player_id):
	if !$Players.has_node(str(player_id)):
		return
	var player_path: String = "Players/" + str(player_id)
	get_node(player_path).queue_free()

func spawn_wall(corpse_inst):
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
