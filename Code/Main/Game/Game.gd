extends Node2D

const WRECK_TSCN = preload("res://Code/Objects/Wreck.tscn")
const TANK_TSCN = preload("res://Code/Player/TankModel.tscn")
const AMMO_TYPES = Ammunition.TYPES
const shootable_tscn = {
	AMMO_TYPES.BULLET: preload("res://Code/Shootable/Projectiles/Bullet.tscn"),
	AMMO_TYPES.ROCKET: preload("res://Code/Shootable/Projectiles/Rocket.tscn"),
	AMMO_TYPES.FRAG_BOMB: preload("res://Code/Shootable/Projectiles/FragBomb.tscn"),
	AMMO_TYPES.LASER: preload("res://Code/Shootable/Laser.tscn"),
	AMMO_TYPES.LASER_BULLET: preload("res://Code/Shootable/Projectiles/LaserBullet.tscn"),
	AMMO_TYPES.FIREBALL: preload("res://Code/Shootable/Projectiles/Fireball.tscn")
}
var settings = GameSettings.get_duplicate_settings()
var player_upgrade_points: Dictionary
onready var projectile_n = $Projectiles
onready var players_n = $Players




func setup(all_upgrades):
	for players_upgrades in all_upgrades:
		for upgrade in players_upgrades:
			var temp_dict = settings
			var i = 0
			for path_step in upgrade:
				i += 1
				if i == upgrade.size():
					temp_dict[path_step] += players_upgrades[upgrade]
					break
				temp_dict = temp_dict[path_step]

func spawn_player(player_id, spawn_point, color):
	var player_inst = TANK_TSCN.instance()
	player_inst.connect("player_destroyed", self, "player_destroyed")
	player_inst.setup(player_id, spawn_point, color, settings.Tank)
	$Players.add_child(player_inst)

func player_destroyed(slayer_id, wreck_data):
	spawn_wreck(wreck_data)
	if !slayer_id.empty() and int(slayer_id) != wreck_data.ID:
		if players_n.has_node(slayer_id):
			players_n.get_node(slayer_id).kills += 1
		else:
			player_upgrade_points[int(slayer_id)] += 1
	player_upgrade_points[wreck_data.ID] = wreck_data.Kills

func spawn_wreck(wreck_data):
	var wreck_inst = WRECK_TSCN.instance()
	wreck_inst.setup(wreck_data)
	$Objects.call_deferred("add_child", wreck_inst)

func spawn_bullet(player_id, turret_rotation, ammo_type):
	if !is_player_alive(player_id):
		return null
	var player_n = players_n.get_node(str(player_id))
	if player_n.subtract_ammo_type(ammo_type) != OK:
		return null
	player_n.rotate_turret(turret_rotation)
	var bullet_inst = shootable_tscn[ammo_type].instance()
	bullet_inst.setup(player_n, ammo_type, settings.Ammunition[ammo_type])
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
