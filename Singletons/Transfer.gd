extends Node

onready var map_node = $"/root/Main/Map"
onready var main_node = $"/root/Main"


#---- INIT DATA ----
remote func recive_init_data():
	var player_id = get_tree().get_rpc_sender_id()
	main_node.player_initiation(player_id)
	send_new_player(player_id)

func send_init_data(player_id, spawn_point, init_data):
	rpc_id(player_id, "recive_init_data", spawn_point, init_data)


func send_new_player(player_id):
	rpc("recive_new_player", player_id)

#----- CORE GAME MECHANIC -----

func send_player_destroyed(player_id, position, rotation):
	rpc("recive_player_destroyed", player_id, position, rotation)

remote func recive_stance(player_stance: Dictionary):
	var player_id = get_tree().get_rpc_sender_id()
	main_node.add_player_stance(player_id, player_stance)

func send_world_stance(time, playerS_stance):
	rpc_unreliable("recive_world_stance", time, playerS_stance)

remote func recive_shoot(player_stance: Dictionary, ammo_type: int): 
	# [improve] Make ammo_type as server authorytative
	var player_id = get_tree().get_rpc_sender_id()
	main_node.player_shoot(player_id, player_stance, ammo_type)

func send_shoot(player_id, player_stance, ammo_type):
	rpc("recive_shoot", player_id, player_stance, ammo_type)



