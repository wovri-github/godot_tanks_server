#extends Object

static func is_recive_upgrades_input_valid(player_id: int, game_n: Node, upgrades: Dictionary, player_choosen_upgrades: Dictionary, MAX_CLIENTS: int) -> bool:
	if !game_n.player_upgrade_points.has(player_id):
		printerr("[Main]: Upgrades may be recived only once per game. New upgrades droped.")
		return false
	var available_upgrade_points = game_n.player_upgrade_points[player_id]
	var sum = 0
	for upgrade in upgrades:
		if !player_choosen_upgrades.has(player_id):
			printerr("[Main]: There is no player in choosen upgrades. Upgrades droped.")
			return false
		if !upgrade in player_choosen_upgrades[player_id]:
			printerr("[Main]: There is no upgrade in choosen upgrades. Upgrades droped.")
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
