extends Node

onready var game_n = $"/root/Main/Game"
onready var main_n = $"/root/Main"


#---- INIT DATA ----
remote func recive_init_data(player_name):
	var player_id = get_tree().get_rpc_sender_id()
	main_n.player_initiation(player_id, player_name)


func send_init_data(player_id, init_data):
	rpc_id(player_id, "recive_init_data", init_data)


func send_new_player(player_id, spawn_point):
	rpc("recive_new_player", player_id, spawn_point)

func send_new_battle(new_game_data):
	rpc("recive_new_battle", new_game_data)
#---- CORE GAME MECHANIC -----

func send_new_battle_time(left_sec):
	rpc("recive_new_battle_time", left_sec)

func send_player_destroyed(corpse_data, slayer_id, projectile_name):
	rpc("recive_player_destroyed", corpse_data, slayer_id, projectile_name)

remote func recive_stance(player_stance: Dictionary):
	var player_id = get_tree().get_rpc_sender_id()
	main_n.add_player_stance(player_id, player_stance)

func send_world_stance(time, playerS_stance):
	rpc_unreliable("recive_world_stance", time, playerS_stance)

remote func recive_shoot(player_stance: Dictionary, ammo_slot: int): 
	# [improve] Make ammo_type as server authorytative
	var player_id = get_tree().get_rpc_sender_id()
	main_n.player_shoot(player_id, player_stance, ammo_slot)

func send_shoot(player_id, bullet_data):
	rpc("recive_shoot", player_id, bullet_data, OS.get_ticks_msec())

func send_shoot_bounce_state(bulletS_state, time):
	rpc_unreliable("recive_shoot_bounce_state", bulletS_state, time)
