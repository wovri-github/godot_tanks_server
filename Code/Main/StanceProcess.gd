extends Timer

var rockets_stances: Dictionary
onready var world_stance = {
	"PlayersStance": Data.playerS_stance,
	"RocketsStance": rockets_stances,
}

func get_rocket_stances():
	rockets_stances.clear()
	for rocket in get_tree().get_nodes_in_group("Rocket"):
		rockets_stances[rocket.name] = rocket.get_stance()

func _on_StanceSender_timeout():
	get_rocket_stances()
	if world_stance.empty() == true:
		return
	Transfer.send_world_stance(OS.get_ticks_msec(), world_stance)
