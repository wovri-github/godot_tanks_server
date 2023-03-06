extends Node

onready var main_n = $"/root/Main"



#---- INIT DATA ----
remote func recive_init_data(player_name, player_color, player_version):
	var player_id = get_tree().get_rpc_sender_id()
	main_n.player_initiation(player_id, player_name, player_color, player_version)

func send_old_version_info(player_id):
	var available_versions = ProjectSettings.get_setting("application/other/available_versions")
	rpc_id(player_id, "recive_old_version_info", available_versions)

func send_init_data(player_id, init_data):
	rpc_id(player_id, "recive_data_during_game", init_data)

func send_new_battle(new_game_data):
	rpc("recive_new_battle", new_game_data)

#---- CORE GAME MECHANIC -----

func send_new_battle_time(left_sec):
	rpc("recive_new_battle_time", left_sec)

func send_player_destroyed(corpse_data, kill_event_data):
	rpc("recive_player_destroyed", corpse_data, kill_event_data)

func send_ammobox_destroyed(name):
	rpc("recive_ammobox_destroyed", name)

remote func recive_stance(player_stance: Dictionary):
	var player_id = get_tree().get_rpc_sender_id()
	Data.add_player_stance(player_id, player_stance)

func send_world_stance(time, playerS_stance):
	rpc_unreliable("recive_world_stance", time, playerS_stance)

remote func recive_shoot(player_stance: Dictionary, ammo_type: int): 
	var player_id = get_tree().get_rpc_sender_id()
	player_stance.ID = player_id
	main_n.player_shoot(player_stance, ammo_type)

func send_shoot(player_id, bullet_data):
	rpc("recive_shoot", player_id, bullet_data, OS.get_ticks_msec())

func send_shoot_bounce_state(bulletS_state, time):
	rpc_unreliable("recive_shoot_bounce_state", bulletS_state, time)


func send_player_possible_upgrades(player_id, player_choosen_upgrades):
	pass
#	rpc_id(player_id, "recive_player_possible_upgrades", player_choosen_upgrades)


remote func recive_upgrade(upgrades: Dictionary):
	var player_id = get_tree().get_rpc_sender_id()
	main_n.upgrades_gd.recive_upgrades(player_id, upgrades)
