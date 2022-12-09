extends Node

const DEFALUT_PORT = 42521
const MAX_CLIENTS = 16
var network = NetworkedMultiplayerENet.new()

var playerS_last_time: Dictionary
var playerS_stance: Dictionary

onready var map_node = $"%Map"



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
	Transfer.send_depsawn_player(player_id) # [improve] set it by lacking player in playerS_stance
	var _err = playerS_stance.erase(player_id)
	_err = playerS_last_time.erase(player_id)
	map_node.despawn_player(player_id)



#--------Stance--------
func player_initiation(player_id: int):
	playerS_last_time[player_id] = -INF
	Transfer.send_init_data(player_id, get_playerS_name())
	map_node.spawn_player(player_id)

func get_playerS_name() -> Array:
	var playerS = $Map/Players.get_children()
	var playerS_name: Array
	for player in playerS:
		playerS_name.append(player.name)
	return playerS_name

func add_player_stance(player_id, player_stance):
	# This number [T] IS ONLY for making chronology. Don't use it
	# [improve] How to drop data when player_id is not in playerS_last_time???
	if playerS_last_time[player_id] < player_stance["T"]: 
		playerS_last_time[player_id] = player_stance["T"]
		player_stance.erase("T")
		playerS_stance[player_id] = player_stance


#--------Shoot----------
func player_shoot(player_id, player_stance, ammo_type):
	map_node.update_player_position(player_id, player_stance)
	map_node.spawn_bullet(player_id, player_stance.TR,ammo_type)

