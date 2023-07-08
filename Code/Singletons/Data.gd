extends Node

const MAX_PLAYERS = 2

var spectators_data: Dictionary
var spectators_queue: Array
var players: Dictionary

var playerS_stance: Dictionary
var playerS_last_time: Dictionary

var current_special_upgrades: Dictionary


func get_merged_players_data() -> Array:
	var data: Array = []
	for player_data in players.values():
		var player_data_copy = player_data.duplicate()
		if playerS_stance.has(player_data.ID):
			player_data_copy.merge(playerS_stance[player_data.ID], true)
		data.append(player_data_copy)
	return data

func manage_new_player(player_id, data):
	if players.size() < MAX_PLAYERS and spectators_queue.empty():
		add_new_player(player_id, data)
	else:
		add_new_spectator(player_id, data)

func add_new_spectator(player_id, data):
	spectators_queue.append(player_id)
	spectators_data[player_id] = data

func add_new_player(player_id, data):
	players[player_id] = {
			"ID": player_id,
			"Nick": data.Nick,
			"Color": data.Color,
			"Score": {
				"Wins": 0,
				"Kills": 0,
			},
			"Upgrades": {}
	}
	playerS_last_time[player_id] = -INF

func peer_left(peer_id):
	var was_player = players.erase(peer_id)
	if not spectators_queue.empty() and was_player:
		var spectator_id = spectators_queue.pop_front()
		add_new_player(spectator_id, spectators_data[spectator_id])
		spectators_data.erase(spectator_id)
	elif not was_player:
		spectators_data.erase(peer_id)
		spectators_queue.erase(peer_id)
		


func add_first_playerS_stance(player_id, spawn_point):
	playerS_stance[player_id] = {
		"ID": player_id,
		"P": spawn_point,
		"R": 0,
		"TR": 0,
	}

func add_player_stance(player_id, player_stance):
	# [info] This number [T] IS ONLY for making chronology. Don't use it
	if playerS_stance.has(player_id) and playerS_last_time[player_id] < player_stance["T"]:
		playerS_last_time[player_id] = player_stance["T"]
		player_stance.erase("T")
		player_stance.ID = player_id
		playerS_stance[player_id] = player_stance
