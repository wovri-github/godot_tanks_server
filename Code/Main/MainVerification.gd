#extends Object

static func is_recive_upgrades_input_valid(player_id: int, game_n: Node, upgrades: Dictionary, MAX_CLIENTS: int) -> bool:
	if !game_n.player_upgrade_points.has(player_id):
		printerr("[Main]: Upgrades may be recived only once per game. New upgrades droped.")
		return false
	var available_upgrade_points = game_n.player_upgrade_points[player_id]
	var sum = 0
	for upgrade in upgrades:
		var temp_dict = GameSettings.get_settings()
		var i = 0
		for path_step in upgrade:
			i += 1
			if !temp_dict.has(path_step):
				printerr("[Main]: There is no such key. Upgrades droped.")
				return false
			temp_dict = temp_dict[path_step]
			if i == upgrade.size() and \
					typeof(temp_dict) != TYPE_REAL and \
					typeof(temp_dict) != TYPE_INT:
				printerr("[Main]: Last value is not Float number. Upgrades droped.")
				return false
		var val = upgrades[upgrade]
		if typeof(val) != TYPE_INT:
			printerr("[Main]: Values has to be integer! It only show how much points player spend on each upgrade")
			val = 0
		val = clamp(val, 0, MAX_CLIENTS)
		if val == 0 or val == MAX_CLIENTS:
			printerr("[Main]: Value out of range. Upgrades droped.")
			return false
		sum += val
	if sum > available_upgrade_points:
		printerr("[Main]: More spended points than kills. Upgrades droped.")
		return false
	return true
