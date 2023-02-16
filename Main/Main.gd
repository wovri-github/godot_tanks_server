extends Node

const DEFALUT_PORT = 42521
const MAX_CLIENTS = 16

const NEW_BATTLE_START_WAITING = 5000 # ms

var network = NetworkedMultiplayerENet.new()

var playerS_last_time: Dictionary
var playerS_stance: Dictionary
var bulletS_stance_on_collision: Array
var player_data: Dictionary
var game_tscn = preload("res://Main/Game/Game.tscn")

onready var processing_timer = $Processing_timer
onready var battle_timer_n = $BattleTimer
onready var game_n = get_node(Dir.GAME)
onready var map_n = get_node(Dir.MAP)



func _enter_tree() -> void:
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

func _ready():
	battle_timer_n._ready()


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
	var init_data = {
		"PlayerSData": get_playerS_data(),
		"PlayerSCorpses": get_playerS_corpses(),
		"MapData": map_n.get_map_data(),
	}
	Transfer.send_init_data(player_id, init_data)
	battle_timer_n.check_battle_timer()

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

func get_playerS_corpses():
	var playerS_corpses = $Game/Objects.get_children()
	var playerS_corpses_dict: Array = []
	for player_corpse in playerS_corpses:
		playerS_corpses_dict.append({
			"ID": int(player_corpse.name),
			"Pos": player_corpse.get_global_position(),
			"Rot": player_corpse.get_global_rotation(),
		})
	return playerS_corpses_dict

func start_new_game():
	_ready()
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
	network.set_refuse_new_connections(false)
	print("[Main]: Time left for start new game: ", time_of_game_start - OS.get_ticks_msec())

func end_of_battle():
	network.set_refuse_new_connections(true)
	var players_in_game = game_n.get_node("Players").get_children()
	if players_in_game.size() == 1:
		var player_id = int(players_in_game[0].name)
		player_data[player_id].Score.Wins += 1
	game_n.queue_free()
	var game_inst = game_tscn.instance()
#	game_inst.get_node("Map").connect("map_created", self, "start_new_game")
	yield(game_n, "tree_exited")
	add_child(game_inst, true)
	start_new_game()


func add_player_stance(player_id, player_stance):
	# [info] This number [T] IS ONLY for making chronology. Don't use it
	if playerS_last_time[player_id] < player_stance["T"]: 
		playerS_last_time[player_id] = player_stance["T"]
		player_stance.erase("T")
		playerS_stance[player_id] = player_stance

func player_shoot(player_id, player_stance, ammo_slot):
	yield(get_tree().create_timer(0), "timeout")
	game_n.update_player_position(player_id, player_stance)
	var bullet_data = game_n.spawn_bullet(player_id, player_stance.TR, ammo_slot)
	if bullet_data != null:
		Transfer.send_shoot(player_id, bullet_data)

func add_bullet_stance_on_collision(bullet_stance_on_collision):
	bulletS_stance_on_collision.append(bullet_stance_on_collision)
	#[info] When two bullets collide its better to send it in one file
	yield(get_tree(), "idle_frame")
	if bulletS_stance_on_collision.empty() == false:
		Transfer.send_shoot_bounce_state(bulletS_stance_on_collision, OS.get_ticks_msec())
		bulletS_stance_on_collision.clear()


func _on_Button_pressed():
	# [info] only for testing purposes
	$BattleTimer.stop()
	end_of_battle()
