extends Timer

const SECONDS_PER_PLAYER = 3
const BATTLE_END_WAITING = 1 # ms
onready var game_n = get_parent()


func check_time(players_alive):
	if get_tree().multiplayer.get_network_connected_peers().size() != players_alive:
		var left_sec = calculate_time(players_alive)
		if players_alive <= 1:
			left_sec = BATTLE_END_WAITING
		if left_sec == -1:
			return
		Transfer.send_new_battle_time(OS.get_ticks_msec() + left_sec * 1000)
		start(left_sec)
	else:
		Transfer.send_new_battle_time(INF)
		stop()

func calculate_time(players_alive) -> int:
	var left_sec = players_alive * SECONDS_PER_PLAYER
	var actual_time = int(get_time_left())
	if actual_time <= left_sec && !is_stopped():
		return -1
	return left_sec
