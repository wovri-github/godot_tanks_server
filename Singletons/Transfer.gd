extends Node

onready var game_n = $"/root/Main/Game"
onready var main_n = $"/root/Main"


#---- INIT DATA ----
remote func recive_init_data(player_name):
	var player_id = get_tree().get_rpc_sender_id()
	main_n.player_initiation(player_id, player_name)
	send_new_player(player_id, player_name) # main_n.get_node("Players/"+str(player_id)).player_name

func send_init_data(player_id, spawn_point, players, walls, scores):
	rpc_id(player_id, "recive_init_data", spawn_point, players, walls, scores)


func send_new_player(player_id, player_name):
	rpc("recive_new_player", player_id, player_name)

#----- CORE GAME MECHANIC -----

func send_player_destroyed(player_id, position, rotation, projectile_name):
	rpc("recive_player_destroyed", player_id, position, rotation, projectile_name)

remote func recive_stance(player_stance: Dictionary):
	var player_id = get_tree().get_rpc_sender_id()
	main_n.add_player_stance(player_id, player_stance)

func send_world_stance(time, playerS_stance):
	rpc_unreliable("recive_world_stance", time, playerS_stance)

remote func recive_shoot(player_stance: Dictionary, ammo_type: int): 
	# [improve] Make ammo_type as server authorytative
	var player_id = get_tree().get_rpc_sender_id()
	main_n.player_shoot(player_id, player_stance, ammo_type)

func send_shoot(player_id, bullet_data):
	rpc("recive_shoot", player_id, bullet_data)
	
func send_score_update(player_id: String, new_score: int):
	rpc("recive_score_update", player_id, new_score)



