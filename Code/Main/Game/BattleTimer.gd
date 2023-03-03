extends Timer

const SECONDS_PER_PLAYER = 60
onready var game_n = get_parent()


func check_time(players_alive):
	if get_tree().multiplayer.get_network_connected_peers().size() != players_alive:
		var left_sec = calculate_time(players_alive)
		if players_alive == 0:
			left_sec = 1
		if left_sec == -1:
			return
		Transfer.send_new_battle_time(left_sec)
		start(left_sec)
	else:
		Transfer.send_new_battle_time(INF)
		stop()

func calculate_time(players_alive) -> int:
	var left_sec = players_alive * SECONDS_PER_PLAYER
	var actual_time = int(get_time_left())
	if players_alive == 1:
		left_sec = 7
	if actual_time <= left_sec && !is_stopped():
		return -1
	return left_sec
