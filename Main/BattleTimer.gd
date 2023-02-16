extends Timer

const SECONDS_PER_PLAYER = 60
onready var game_n = $"../Game"



func check_battle_timer():
	var left_sec = calculate_time()
	if left_sec == -1:
		return
	Transfer.send_new_battle_time(left_sec)
	start(left_sec)

func calculate_time() -> int:
	var num_players_in_game = game_n.get_node("Players").get_child_count()
	var left_sec = num_players_in_game * SECONDS_PER_PLAYER
	var actual_time = int(get_time_left())
	if num_players_in_game == 1:
		left_sec = 7
	if actual_time < left_sec && !is_stopped():
		return -1
	return left_sec


func _on_BattleTimer_timeout():
	get_parent().end_of_battle()
