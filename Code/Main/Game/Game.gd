extends Node2D

signal player_destroyed(wreck_data, slayer_id, is_slayer_dead)


const VALUE_PER_POINT = GameSettings.PERCENTAGE_OF_BASE_VALUE_PER_POINT
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
var orginal_settings = GameSettings.get_settings()
var player_upgrade_points: Dictionary
var bulletS_stance_on_collision: Array
onready var projectile_n = $Projectiles
onready var players_n = $Players
onready var battle_timer_n = $BattleTimer



func _ready():
	add_upgrades_to_settings()

func add_upgrades_to_settings():
	var all_upgrades = get_all_players_upgrades()
	for players_upgrades in all_upgrades:
		for upgrade in players_upgrades:
			var temp_dict = settings
			var temp_orginal_dict = orginal_settings
			var i = 0
			for path_step in upgrade:
				i += 1
				if i == upgrade.size():
					temp_dict[path_step] += players_upgrades[upgrade] * \
							temp_orginal_dict[path_step] * \
							VALUE_PER_POINT
					break
				temp_dict = temp_dict[path_step]
				temp_orginal_dict = temp_orginal_dict[path_step]

func get_all_players_upgrades():
	var upgrades: Array = []
	for player_id in Data.players:
		upgrades.append(Data.players[player_id].Upgrades)
	return upgrades


func spawn_player(player_id, spawn_point, color):
	var player_inst = TANK_TSCN.instance()
	player_inst.connect("player_destroyed", self, "_on_player_destroyed")
	player_inst.setup(player_id, spawn_point, color, settings.Tank)
	$Players.add_child(player_inst)

func _on_player_destroyed(slayer_id, wreck_data):
	spawn_wreck(wreck_data)
	Data.playerS_stance.erase(wreck_data.ID)
	Data.playerS_last_time.erase(wreck_data.ID)
	check_battle_timer()
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

func spawn_bullet(player_id, turret_rotation, ammo_type):
	if !is_player_alive(player_id):
		return null
	var player_n = players_n.get_node(str(player_id))
	if player_n.subtract_ammo_type(ammo_type) != OK:
		return null
	player_n.rotate_turret(turret_rotation)
	var bullet_inst = shootable_tscn[ammo_type].instance()
	bullet_inst.connect("wall_collided", self, "_on_wall_collided")
	bullet_inst.setup(player_n, ammo_type, settings.Ammunition[ammo_type])
	projectile_n.add_child(bullet_inst, true)
	return bullet_inst.get_data()


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


func check_battle_timer():
	var players_alive = players_n.get_child_count()
	battle_timer_n.check_time(players_alive)


#---------Verification----------
func is_player_alive(player_id) -> bool:
	if has_node("Players/" + str(player_id)):
		return true
	return false
