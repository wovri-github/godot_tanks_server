extends Node

const DEFALUT_PORT = 42521
const MAX_CLIENTS = 16

const NEW_BATTLE_START_WAITING = 500 # ms

var network = NetworkedMultiplayerENet.new()

var playerS_last_time: Dictionary
var playerS_stance: Dictionary
var bulletS_stance_on_collision: Array
var player_data: Dictionary
var temp_upgrades: Dictionary
var game_tscn = preload("res://Code/Main/Game/Game.tscn")

onready var processing_timer = $Stance_process
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
	var _err = player_data.erase(player_id)
	var player_n = get_node_or_null("/root/Main/Game/Players/" + str(player_id))
	if player_n:
		player_n.die(null, null)
	battle_timer_n.check_battle_timer()


func _ready():
	battle_timer_n._ready()

func get_init_data() -> Dictionary:
	var init_data = {
		"PlayerSData": get_playerS_data(),
		"PlayerSCorpses": get_playerS_corpses(),
		"BulletsStances": get_bullets_stances(),
		"MapData": map_n.get_map_data(),
	}
	return init_data

func player_initiation(player_id: int, player_name : String, player_color : Color, player_version):
	var err = Functions.check_version(player_version)
	if err == ERR_UNAUTHORIZED:
		Transfer.send_old_version_info(player_id)
		network.disconnect_peer(player_id)
		print("[Main]: Old version. Connection droped")
		return
	player_data[player_id] = {
			"ID": player_id,
			"Nick": player_name,
			"Color": player_color,
			"Score": {
				"Wins": 0,
				"Kills": 0,
			},
			"Upgrades": {}
	}
	var init_data = get_init_data()
	init_data["TimeLeft"] = int(battle_timer_n.get_time_left())
	playerS_last_time[player_id] = -INF
	Transfer.send_init_data(player_id, init_data)
	battle_timer_n.check_battle_timer()

func get_playerS_data() -> Array:
	var data: Array = []
	for player in player_data.values():
		if playerS_stance.has(player.ID):
			player.merge(playerS_stance[player.ID], true)
			data.append(player)
	return data

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
	for player_id in player_data.keys():
		var spawn_point = map_n.get_spawn_position()
		playerS_stance[player_id] = {
			"ID": player_id,
			"P": spawn_point,
			"R": 0,
			"TR": 0,
		}
		game_n.spawn_player(player_id, spawn_point, player_data[player_id].Color)
	var init_data = get_init_data()
	init_data["TimeToStartNewGame"] = time_of_game_start
	Transfer.send_new_battle(init_data)
	yield(get_tree().create_timer((time_of_game_start - OS.get_ticks_msec()) * 0.001),"timeout")
	begin_battle()

func begin_battle():
	print("[Main]: Battle has begun")
	get_tree().set_pause(false)
	processing_timer.start_timer()

func end_of_battle():
	print("[Main]: End of battle")
	processing_timer.stop_timer()
	var players_in_game = game_n.get_node("Players").get_children()
	if players_in_game.size() == 1:
		var player_id = int(players_in_game[0].name)
		player_data[player_id].Score.Wins += 1
	game_n.queue_free()
	add_temp_upgrades_to_player_data()
	yield(game_n, "tree_exited")
	game_n = null
	playerS_stance.clear()
	temp_upgrades.clear()
	get_tree().set_pause(true)
	start_new_game()

func add_player_stance(player_id, player_stance):
	if !get_tree().is_paused(): 
		# [info] This number [T] IS ONLY for making chronology. Don't use it
		if playerS_last_time[player_id] < player_stance["T"] && \
				$Game/Players.has_node(str(player_id)): 
			playerS_last_time[player_id] = player_stance["T"]
			player_stance.erase("T")
			player_stance.ID = player_id
			playerS_stance[player_id] = player_stance

func player_shoot(player_stance, ammo_type):
	if get_tree().is_paused(): 
		return
	game_n.update_player_position(player_stance)
	var bullet_data = game_n.spawn_bullet(player_stance.ID, player_stance.TR, ammo_type)
	if bullet_data != null:
		Transfer.send_shoot(player_stance.ID, bullet_data)

func add_bullet_stance_on_collision(bullet_stance_on_collision):
	bulletS_stance_on_collision.append(bullet_stance_on_collision)
	#[info] When two bullets collide its better to send it in one file
	yield(get_tree(), "idle_frame")
	if bulletS_stance_on_collision.empty() == false:
		Transfer.send_shoot_bounce_state(bulletS_stance_on_collision, OS.get_ticks_msec())
		bulletS_stance_on_collision.clear()

func recive_upgrades(player_id: int, upgrades: Dictionary):
	if !game_n.player_upgrade_points.has(player_id):
		printerr("[Main]: Upgrades may be recived only once per game. New upgrades droped.")
		return
	var available_upgrade_points = game_n.player_upgrade_points[player_id]
	var sum = 0
	for upgrade in upgrades:
		var temp_dict = GameSettings.get_settings()
		var i = 0
		for path_step in upgrade:
			i += 1
			if !temp_dict.has(path_step):
				printerr("[Main]: There is no such key. Upgrades droped.")
				return
			temp_dict = temp_dict[path_step]
			if i == upgrade.size() and \
					typeof(temp_dict) != TYPE_REAL and \
					typeof(temp_dict) != TYPE_INT:
				printerr("[Main]: Last value is not Float number. Upgrades droped.")
				return
		var val = upgrades[upgrade]
		if typeof(val) != TYPE_INT:
			printerr("[Main]: Values has to be integer! It only show how much points player spend on each upgrade")
			val = 0
		val = clamp(val, 0, MAX_CLIENTS)
		if val == 0 or val == MAX_CLIENTS:
			printerr("[Main]: Value out of range. Upgrades droped.")
			return
		sum += val
	if sum > available_upgrade_points:
		printerr("[Main]: More spended points than kills. Upgrades droped.")
		return
	var points_left = sum - available_upgrade_points
	game_n.player_upgrade_points[player_id] = points_left
	temp_upgrades[player_id] = upgrades

func add_temp_upgrades_to_player_data():
	for player_id in temp_upgrades:
		var player_data_upgrades = player_data[player_id].Upgrades
		for upgrade in temp_upgrades[player_id]:
			if player_data_upgrades.has(upgrade):
				player_data_upgrades[upgrade] += temp_upgrades[player_id][upgrade]
				continue
			player_data_upgrades[upgrade] = temp_upgrades[player_id][upgrade]


func _on_Button_pressed():
	# [info] only for testing purposes
	$BattleTimer.stop()
	end_of_battle()
