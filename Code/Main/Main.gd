extends Node

const DEFALUT_PORT = 42521
const MAX_CLIENTS = 16
const NEW_BATTLE_START_WAITING = 500 # ms

#var network = NetworkedMultiplayerENet.new()
var network = WebSocketServer.new()
var game_tscn = preload("res://Code/Main/Game/Game.tscn")

onready var upgrades_gd = load("res://Code/Main/Upgrades.gd").new(MAX_CLIENTS)
onready var stance_timer = $StanceSender
onready var battle_timer_n = $Game/BattleTimer
onready var game_n = $Game
onready var map_n = $Game/Map



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
	print("[Main]: Player " + str(player_id) + " disconnected")
	var _err = Data.players.erase(player_id)
	var player_n = get_node_or_null("/root/Main/Game/Players/" + str(player_id))
	if player_n:
		player_n.die()
	game_n.check_battle_timer()

func _ready():
	game_n.connect("player_destroyed", self, "_on_player_destroyed")
	battle_timer_n.connect("timeout", self, "end_of_battle")

func _process(delta):
	network.poll()

func get_init_data() -> Dictionary:
	var init_data = {
		"PlayerSData": Data.get_merged_players_data(),
		"PlayerSCorpses": get_playerS_corpses(),
		"BulletsStances": get_bullets_stances(),
		"MapData": map_n.get_map_data(),
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
	init_data["TimeLeft"] = int(battle_timer_n.get_time_left())
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
			"Color": player_corpse.color
		})
	return playerS_corpses_dict

func get_bullets_stances() -> Array:
	var bullets = $Game/Projectiles.get_children()
	var stances: Array = []
	for bullet in bullets:
		stances.append(bullet.get_data())
	return stances

func start_new_game():
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

func end_of_battle():
	print("[Main]: End of battle")
	stance_timer.stop()
	var players_in_game = game_n.get_node("Players").get_children()
	if players_in_game.size() == 1:
		var player_id = int(players_in_game[0].name)
		Data.players[player_id].Score.Wins += 1
	game_n.queue_free()
	upgrades_gd.add_temp_upgrades_to_player_data()
	yield(game_n, "tree_exited")
	game_n = null
	Data.playerS_stance.clear()
	get_tree().set_pause(true)
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


func _on_player_destroyed(wreck_data, slayer_id, is_slayer_dead):
	upgrades_gd.set_points_to_upgrade_points(wreck_data, slayer_id, is_slayer_dead)
	Transfer.send_player_possible_upgrades(wreck_data.ID, upgrades_gd.player_choosen_upgrades[wreck_data.ID])
	if wreck_data.ID == slayer_id:
		upgrades_gd.player_choosen_upgrades.erase(wreck_data.ID)


func _on_Button_pressed():
	# [info] only for testing purposes
	battle_timer_n.stop()
	end_of_battle()
