extends Node

const DEFALUT_PORT = 42521
const MAX_CLIENTS = 16
#test
const NEW_BATTLE_START_WAITING = 350 # ms
const BATTLE_END_WAITING = 850 # ms

#var network = NetworkedMultiplayerENet.new()
var network = WebSocketServer.new()
var game_tscn = preload("res://Code/Main/Game/Game.tscn")

onready var stance_timer = $StanceSender
onready var battle_timer_n = $Game/BattleTimer
onready var game_n = $Game
onready var map_n = $Game/Map

onready var upgrades_gd = load("res://Code/Main/Upgrades.gd").new(MAX_CLIENTS)



func _enter_tree() -> void:
	_start_server()
	network.connect("peer_connected", self, "_peer_conected")
	network.connect("peer_disconnected", self, "_peer_disconnected")

#func _start_server() -> void:
#	network.create_server(DEFALUT_PORT, MAX_CLIENTS)
#	get_tree().set_network_peer(network)
#	print("[Main]: Server started")
func _start_server() -> void:
	network.listen(DEFALUT_PORT, PoolStringArray(), true)
	get_tree().set_network_peer(network)
	print("[Main]: Server started")

func _peer_conected(player_id) -> void:
	print("[Main]: Player " + str(player_id) + " connected")

func _peer_disconnected(player_id) -> void:
	yield(get_tree(), "idle_frame")
	print("[Main]: Player " + str(player_id) + " disconnected")
	var _err = Data.players.erase(player_id)
	var player_n = get_node_or_null("/root/Main/Game/Players/" + str(player_id))
	if player_n:
		player_n.die()
	game_n.check_battle_timer()


func _ready():
	game_n.connect("battle_over", self, "_on_battle_over")
	game_n.connect("player_destroyed", upgrades_gd, "_on_player_destroyed")

func _process(_delta):
	network.poll()

func get_init_data() -> Dictionary:
	var init_data = {
		"PlayerSData": Data.get_merged_players_data(),
		"PlayerSCorpses": get_playerS_corpses(),
		"BulletsStances": get_bullets_stances(),
		"MapData": map_n.get_map_data(),
		"SpecialUpgrades": Data.current_special_upgrades
	}
	return init_data

func player_initiation(player_id: int, player_name : String, player_color : Color, player_version):
	var err = check_version(player_version)
	if err == ERR_UNAUTHORIZED:
		Transfer.send_old_version_info(player_id)
		network.disconnect_peer(player_id)
		print("[Main]: Old version detected. Connection droped")
		return
	var player_data = {
		"ID": player_id,
		"Nick": player_name,
		"Color": player_color,
		"Version": player_version,
	}
	var init_data = get_init_data()
	init_data["TimeLeft"] = OS.get_ticks_msec() + battle_timer_n.get_time_left()*1000
	Transfer.send_init_data(player_id, init_data)
	Data.add_new_player(player_data)
	game_n.check_battle_timer()

static func check_version(version) -> int:
	if version == null:
		return OK
	version = version.left(version.find_last("."))
	if version in ProjectSettings.get_setting("application/other/available_versions"):
		return OK
	return ERR_UNAUTHORIZED


func get_playerS_corpses():
	var playerS_corpses = $Game/Objects.get_children()
	var playerS_corpses_dict: Array = []
	for player_corpse in playerS_corpses:
		playerS_corpses_dict.append({
			"ID": int(player_corpse.name),
			"Pos": player_corpse.get_global_position(),
			"Rot": player_corpse.get_global_rotation(),
			"Color": player_corpse.color,
			"LT": player_corpse.life_timer_n.time_left
		})
	return playerS_corpses_dict

func get_bullets_stances() -> Array:
	var bullets = $Game/Projectiles.get_children()
	var stances: Array = []
	for bullet in bullets:
		stances.append(bullet.get_data())
	return stances

func start_new_game():
	GameSettings.set_dynamic_settings()
	var game_inst = game_tscn.instance()
	add_child(game_inst, true)
	_ready()
	var time_of_game_start = OS.get_ticks_msec() + NEW_BATTLE_START_WAITING
	for player_id in Data.players:
		var spawn_point = map_n.get_spawn_position()
		Data.add_first_playerS_stance(player_id, spawn_point)
		game_n.spawn_player(player_id, spawn_point, Data.players[player_id].Color)
		upgrades_gd.choose_player_upgrades(player_id)
	var init_data = get_init_data()
	init_data["TimeToStartNewGame"] = time_of_game_start
	Transfer.send_new_battle(init_data)
	yield(get_tree().create_timer((time_of_game_start - OS.get_ticks_msec()) * 0.001),"timeout")
	begin_battle()

func begin_battle():
	print("[Main]: Battle has begun")
	get_tree().set_pause(false)
	stance_timer.start()

func _on_battle_over(alived_players_id):
	var time_to_end = OS.get_ticks_msec() + BATTLE_END_WAITING
	get_tree().set_pause(true)
	stance_timer.stop()
	if alived_players_id.size() == 1:
		Data.players[alived_players_id[0].ID].Score.Wins += 1
		upgrades_gd.make_upgrade(alived_players_id[0], "Winner")
	else:
		for player_data in alived_players_id:
			upgrades_gd.make_upgrade(player_data, "Normal")
	Transfer.send_battle_over_time(time_to_end)
	yield(get_tree().create_timer((time_to_end - OS.get_ticks_msec()) * 0.001),"timeout")
	end_of_battle()

func end_of_battle():
	print("[Main]: End of battle")
	game_n.queue_free()
	upgrades_gd.add_temp_upgrades_to_player_data()
	upgrades_gd.remove_passed_special_upgrades()
	yield(game_n, "tree_exited")
	game_n = null
	Data.playerS_stance.clear()
	start_new_game()
	
func ammo_box_destroyed(name):
	Transfer.send_ammobox_destroyed(name)

func player_shoot(player_stance, ammo_type):
	if get_tree().is_paused(): 
		return
	game_n.update_player_position(player_stance)
	var bullet_data = game_n.spawn_bullet(player_stance.ID, player_stance.TR, ammo_type)
	if bullet_data != null:
		Transfer.send_shoot(player_stance.ID, bullet_data)
	else:
		Transfer.send_shoot_fail(player_stance.ID)

func player_charge_shoot(player_id, ammo_type):
	if get_tree().is_paused(): 
		return
	if game_n.player_charge_shoot(player_id, ammo_type):
		Transfer.send_player_charge(player_id, ammo_type)
	else:
		Transfer.send_shoot_fail(player_id)

func player_change_ammo_type(player_id, ammo_type):
	if get_tree().is_paused(): 
		return
	if game_n.player_change_ammo_type(player_id, ammo_type):
		Transfer.send_player_turret_change(player_id, ammo_type)

func _on_Button_pressed():
	# [info] only for testing purposes
	battle_timer_n.stop()
	end_of_battle()
