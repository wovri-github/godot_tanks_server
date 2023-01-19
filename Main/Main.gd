extends Node

const DEFALUT_PORT = 42521
const MAX_CLIENTS = 16

const NEW_BATTLE_START_WAITING = 5000 # ms

var network = NetworkedMultiplayerENet.new()

var playerS_last_time: Dictionary
var playerS_stance: Dictionary
var player_data: Dictionary
var game_tscn = preload("res://Main/Game/Game.tscn")

onready var processing_timer = $Processing_timer
onready var game_n = $Game
onready var map_n = game_n.get_node("Map")



func _ready() -> void:
	_start_server()
	network.connect("peer_connected", self, "_peer_conected")
	network.connect("peer_disconnected", self, "_peer_disconnected")

func _start_server() -> void:
	network.create_server(DEFALUT_PORT, MAX_CLIENTS)
	get_tree().set_network_peer(network)
	print("[Main]: Server started")

func _peer_conected(player_id) -> void:
	print("[Main]: Player " + str(player_id) + " connected")

func _peer_disconnected(player_id) -> void:
	print("[Main]: Player " + str(player_id) + " disconnected")
	player_data.erase(player_id)
	var player_n = get_node_or_null("/root/Main/Game/Players/" + str(player_id))
	if player_n:
		player_n.die(null, null)



#--------Stance--------
func player_initiation(player_id: int, player_name : String):
	player_data[player_id] = {
		"ID": player_id,
		"Nick": player_name,
		"Score": {
			"Wins": 0,
			"Kills": 0,
		},
		"SP": -1,
	}
	playerS_last_time[player_id] = -INF
	var spawn_point = map_n.get_spawn_position()
	var init_data = {
		"PlayerSTemplateData": get_playerS_data(),
		"PlayerSCorpses": get_playerS_corpses(),
		"MapData": map_n.get_map_data(),
	}
	Transfer.send_init_data(player_id, init_data)
#	battle_timer_logick()

#[info] when somebody die or connect then calculate how many second left of battle
#func battle_timer_logick():
#	$EndOfBattle.start()

func get_playerS_data() -> Array:
	var playerS = $Game/Players.get_children()
	var playerS_name: Array = []
	for player in playerS:
		var player_id = int(player.name)
		playerS_name.append({
			"ID": player_id, 
			"Nick": player_data[player_id].Nick, 
			"SP": player.get_position(),
			"Score": player_data[player_id].Score,
		})
	return playerS_name

func start_new_game():
	var time_of_game_start = OS.get_ticks_msec() + NEW_BATTLE_START_WAITING
	for player_id in player_data.keys():
		var spawn_point = map_n.get_spawn_position()
		player_data[player_id].SP = spawn_point
		game_n.spawn_player(player_id, spawn_point)
	var new_game_data = {
		"PlayerSData": player_data,
		"MapData": map_n.get_map_data(),
		"TimeOfNewGame": time_of_game_start,
	}
	Transfer.send_new_battle(new_game_data)
	print("[Main]: Time left for start new game: ", time_of_game_start - OS.get_ticks_msec())


func get_playerS_corpses():
	var playerS_corpses = $Game/Objects.get_children()
	var playerS_corpses_dict: Array = []
	for player_corpse in playerS_corpses:
		playerS_corpses_dict.append({
			"Name": player_corpse.name,
			"P": player_corpse.get_global_position(),
			"R": player_corpse.get_global_rotation(),
		})
	return playerS_corpses_dict

func add_player_stance(player_id, player_stance):
	# This number [T] IS ONLY for making chronology. Don't use it
	# [improve] How to drop data when player_id is not in playerS_last_time???
	if playerS_last_time[player_id] < player_stance["T"]: 
		playerS_last_time[player_id] = player_stance["T"]
		player_stance.erase("T")
		playerS_stance[player_id] = player_stance

func dc(player_id):
	#warning-ignore:return_value_discarded
	playerS_stance.erase(player_id)
	#warning-ignore:return_value_discarded
	playerS_last_time.erase(player_id)
	if get_tree().multiplayer.get_network_connected_peers().has(player_id):
		network.disconnect_peer(player_id)

func end_of_battle():
#	processing_timer.stop()
	game_n.queue_free()
	yield(game_n, "tree_exited")
	var game_inst = game_tscn.instance()
	add_child(game_inst)
	game_n = get_node(Dir.GAME)
	map_n = get_node(Dir.MAP)
	start_new_game()

#--------Shoot----------
func player_shoot(player_id, player_stance, ammo_slot):
	game_n.update_player_position(player_id, player_stance)
	var bullet_data = game_n.spawn_bullet(player_id, player_stance.TR, ammo_slot)
	if bullet_data != null:
		Transfer.send_shoot(player_id, bullet_data)


func _on_Button_pressed():
	end_of_battle()


func _on_EndOfBattle_timeout():
	end_of_battle()
