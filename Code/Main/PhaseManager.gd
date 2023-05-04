extends Timer

signal phase_changed(phase)


const SECONDS_PER_PLAYER = 30
const SECONDS_ON_LAST_ALIVE = 5
const phase_list: Array = ["Prepare", "Battle", "Upgrade"]
const phase_time = {
	"Prepare": 7,
	"Battle": INF,
	"Upgrade": 10,
}
var game_n = null setget set_game_n # Setted by Main 
var fast_time: bool = false
export (String) var current_phase = "Battle"


func set_game_n(_game_n):
	game_n = _game_n
	game_n.connect("player_destroyed", self, "_on_player_destroyed")
	

func _ready():
	var _err
	Transfer.network.connect("peer_disconnected", self , "_on_peer_disconnected")
	Transfer.network.connect("peer_connected", self, "_on_peer_conected")

func get_phase():
	var phase = {
		"Name": current_phase,
		"ClosingTick": round(OS.get_ticks_msec() + get_time_left() * 1000),
	}
	return phase

func set_next_phase():
	var current_phase_position = phase_list.find(current_phase)
	var next_phase_position = (current_phase_position + 1) % phase_list.size()
	current_phase = phase_list[next_phase_position]
	var time = phase_time[current_phase]
	if fast_time:
		time *= 0.1
	start(time)

func phase_emiter():
	emit_signal("phase_changed", get_phase())
	Transfer.send_phase(get_phase())

func battle_logic():
	if current_phase != "Battle":
		return
	var players_alive = game_n.get_alive_players()
	if get_tree().multiplayer.get_network_connected_peers().size() == players_alive:
		start(INF)
		Transfer.send_phase(get_phase())
		return
	var left_sec = calculate_time(players_alive)
	if players_alive == 1:
		start(SECONDS_ON_LAST_ALIVE)
		Transfer.send_phase(get_phase())
		return
	if players_alive == 0:
		_on_PhaseManager_timeout()
		return
	if left_sec == -1:
		return
	start(left_sec)
	Transfer.send_phase(get_phase())

func calculate_time(players_alive) -> int:
	var left_sec = players_alive * SECONDS_PER_PLAYER
	var actual_time = int(get_time_left())
	if actual_time <= left_sec && get_time_left() != INF:
		return -1
	return left_sec



func _on_peer_conected(_player_id):
	battle_logic()
func _on_player_destroyed(_wreck_data, _slayer_id, _is_slayer_dead):
	battle_logic()
func _on_peer_disconnected(player_id):
	if game_n.is_player_alive(player_id):
		return
	yield(get_tree(), "idle_frame")
	battle_logic()


func _on_CheckButton_toggled(button_pressed):
	fast_time = button_pressed

func _on_PhaseManager_timeout():
	set_next_phase()
	phase_emiter()
#	if current_phase == "Battle":
#		battle_logic()
