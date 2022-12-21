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
	map_node.despawn_player(player_id)



#--------Stance--------
func player_initiation(player_id: int):
	playerS_last_time[player_id] = -INF
	var spawn_point = map_node.get_spawn_position()
	Transfer.send_init_data(player_id, spawn_point, get_playerS_name(), get_playerS_corpses(), get_playerS_score())
	map_node.spawn_player(player_id, spawn_point)

func get_playerS_name() -> Array:
	var playerS = $Map/Players.get_children()
	var playerS_name: Array = []
	for player in playerS:
		playerS_name.append(player.name)
	return playerS_name

func get_playerS_score():
	var playerS = $Map/Players.get_children()
	var playerS_score: Array = []
	for player in playerS:
		playerS_score.append({"Name": player.name, "Score": player.score})
	return playerS_score

func get_playerS_corpses():
	var playerS_corpses = $Map/Objects.get_children()
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
	network.disconnect_peer(player_id)

#--------Shoot----------
func player_shoot(player_id, player_stance, ammo_type):
	map_node.update_player_position(player_id, player_stance)
	var bullet_data = map_node.spawn_bullet(player_id, player_stance.TR, ammo_type)
	Transfer.send_shoot(player_id, bullet_data)
