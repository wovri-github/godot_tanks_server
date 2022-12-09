extends Node


#------ Map ------
func is_player_alive(player_id) -> bool:
	var map = $"/root/Main/Map"
	if !map.has_node("Players/" + str(player_id)):
		return false
	return true
