extends Node

signal recive_init_data(player_id, player_name, player_color, player_version)
signal recive_shoot(player_stance, ammo_type)
signal recive_charge_shoot(player_id, ammo_type)
signal recive_ammo_type_change(player_id, ammo_type)
signal recive_upgrade(player_id, upgrades)
signal recive_update_acknowledge(player_id)

const DEFALUT_PORT = 42521
const MAX_CLIENTS = 16
var cert = load("res://cert/tanksgf.online.crt")
var key = load("res://cert/tanksgf.online.key")

var network = WebSocketServer.new()
onready var clock_n = $Clock

func _enter_tree() -> void:
	if OS.is_debug_build() == false:
		network.set_private_key(key)
		network.set_ssl_certificate(cert)
	_start_server()

func _start_server() -> void:
	network.listen(DEFALUT_PORT, PoolStringArray(), true)
	get_tree().set_network_peer(network)
	network.connect("peer_connected", self, "_peer_conected")
	network.connect("peer_disconnected", self, "_peer_disconnected")
	Logger.info("[Transfer]: Server started")

func _peer_conected(player_id) -> void:
	Logger.info("[Transfer]: Player " + str(player_id) + " connected")

func _peer_disconnected(player_id) -> void:
	Logger.info("[Transfer]: Player " + str(player_id) + " disconnected")
	var _err = Data.players.erase(player_id)

func _process(_delta):
	network.poll()


#---- INIT DATA ----
remote func recive_init_data(player_data, client_time):
	var player_id = get_tree().get_rpc_sender_id()
	clock_n.rec_determine_begining_time_diff(client_time)
	emit_signal("recive_init_data", player_id, player_data)

func send_old_version_info(player_id):
	var available_versions = ProjectSettings.get_setting("application/other/available_versions")
	rpc_id(player_id, "recive_old_version_info", available_versions)

func send_init_data(player_id, init_data):
	rpc_id(player_id, "recive_data_during_game", init_data)

func send_new_battle(new_game_data):
	rpc("recive_new_battle", new_game_data)
#---- CORE GAME MECHANIC -----

func send_phase(phase):
	rpc("recive_phase", phase)

func send_player_destroyed(corpse_data, kill_event_data):
	rpc("recive_player_destroyed", corpse_data, kill_event_data)

func send_ammobox_destroyed(name):
	rpc("recive_ammobox_destroyed", name)


remote func recive_stance(player_stance: Dictionary):
	if get_tree().is_paused(): 
		return
	var player_id = get_tree().get_rpc_sender_id()
	Data.add_player_stance(player_id, player_stance)

func send_world_stance(time, playerS_stance):
	rpc_unreliable("recive_world_stance", time, playerS_stance)

remote func recive_shoot(player_stance: Dictionary, ammo_type: int): 
	if get_tree().is_paused(): 
		return
	var player_id = get_tree().get_rpc_sender_id()
	player_stance.ID = player_id
	emit_signal("recive_shoot", player_stance, ammo_type)

remote func recive_charge_shoot(ammo_type : int):
	if get_tree().is_paused(): 
		return
	var player_id = get_tree().get_rpc_sender_id()
	emit_signal("recive_charge_shoot", player_id, ammo_type)

func send_shoot(player_id, bullet_data):
	rpc("recive_shoot", player_id, bullet_data)

func send_shoot_fail(player_id):
	rpc_id(player_id, "recive_shoot_fail", player_id)

func send_player_charge(player_id, ammo_type):
	rpc("recive_player_charge", player_id, ammo_type)

remote func recive_ammo_type_change(ammo_type):
	if get_tree().is_paused(): 
		return
	var player_id = get_tree().get_rpc_sender_id()
	emit_signal("recive_ammo_type_change", player_id, ammo_type)

func send_player_turret_change(player_id, ammo_type):
	rpc("recive_turret_change", player_id, ammo_type)

func send_shoot_bounce_state(bulletS_state, time):
	rpc_unreliable("recive_shoot_bounce_state", bulletS_state, time)


func send_player_possible_upgrades(player_id, data):
	rpc_id(player_id, "recive_player_possible_upgrades", data)

remote func recive_upgrade(upgrades: Dictionary):
	var player_id = get_tree().get_rpc_sender_id()
	emit_signal("recive_upgrade", player_id, upgrades)

remote func recive_update_acknowledge():
	var player_id = get_tree().get_rpc_sender_id()
	emit_signal("recive_update_acknowledge", player_id)
	
