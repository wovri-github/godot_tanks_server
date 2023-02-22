extends Node

var player_hp = {}
var rockets_stances: Dictionary
onready var world_stance = {
	"PlayersStance": get_parent().playerS_stance,
	"RocketsStance": rockets_stances,
}

func start_timer():
	$Processing_timer.start()

func stop_timer():
	$Processing_timer.stop()

func get_rocket_stances():
	rockets_stances.clear()
	for rocket in get_tree().get_nodes_in_group("Rocket"):
		rockets_stances[rocket.name] = rocket.get_stance()


func _on_Processing_timer_timeout():
	get_rocket_stances()
	if world_stance.empty() == true:
		return
	# Verification
	# Anti-cheate
	Transfer.send_world_stance(OS.get_ticks_msec(), world_stance)
