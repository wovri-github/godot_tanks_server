extends Node

var network = WebSocketServer.new()
var game_tscn = preload("res://Code/Main/Game/Game.tscn")

onready var stance_timer = $StanceSender
onready var game_n = $Game
onready var map_n = $Game/Map
onready var upgrades_gd = load("res://Code/Main/Upgrades.gd").new()
onready var phase_manager = $PhaseManager



func _enter_tree() -> void:
	var _err
	_err = Transfer.connect("recive_init_data", self, "player_initiation")

func _ready():
	phase_manager.connect("phase_changed", self, "_on_phase_changed")
	update_game_n()

func update_game_n():
	game_n = $Game
	map_n = $Game/Map
	game_n.connect("battle_over", self, "_on_battle_over")
	game_n.connect("player_destroyed", upgrades_gd, "_on_player_destroyed")
	phase_manager.game_n = game_n
	


func get_init_data() -> Dictionary:
	var init_data = {
		"PlayerSData": Data.get_merged_players_data(),
		"PlayerSCorpses": get_playerS_corpses(),
		"BulletsStances": get_bullets_stances(),
		"MapData": map_n.get_map_data(),
		"SpecialUpgrades": Data.current_special_upgrades,
		"Phase": phase_manager.get_phase(),
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
	Transfer.send_init_data(player_id, init_data)
	Data.add_new_player(player_data)

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
	update_game_n()
	for player_id in Data.players:
		var spawn_point = map_n.get_spawn_position()
		Data.add_first_playerS_stance(player_id, spawn_point)
		game_n.spawn_player(player_id, spawn_point, Data.players[player_id].Color)
		upgrades_gd.choose_player_upgrades(player_id)
	var init_data = get_init_data()
	Transfer.send_new_battle(init_data)

func begin_battle():
	get_tree().set_pause(false)
	stance_timer.start()

func _on_battle_over():
	var alived_players_id = game_n.get_alived_players_id()
	get_tree().set_pause(true)
	stance_timer.stop()
	if alived_players_id.size() == 1:
		Data.players[alived_players_id[0].ID].Score.Wins += 1
		upgrades_gd.make_upgrade(alived_players_id[0], "Winner")
	else:
		for player_data in alived_players_id:
			upgrades_gd.make_upgrade(player_data, "Normal")

func end_of_battle():
	game_n.queue_free()
	upgrades_gd.add_temp_upgrades_to_player_data()
	upgrades_gd.remove_passed_special_upgrades()
	yield(game_n, "tree_exited")
	game_n = null
	Data.playerS_stance.clear()
	var game_inst = game_tscn.instance()
	add_child(game_inst, true)
	start_new_game()

func _on_phase_changed(phase):
	print("[Main]: ", phase)
	match phase.Name:
		"Prepare":
			end_of_battle()
		"Battle":
			begin_battle()
		"Upgrade":
			_on_battle_over()


func _on_Button_pressed():
	# [info] only for testing purposes
	phase_manager._on_PhaseManager_timeout()
