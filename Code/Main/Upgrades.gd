extends GDScript

const MAX_UPGRADES = GameSettings.MAX_UPGRADES
var player_choosen_upgrades: Dictionary
var max_points
var temp_upgrades: Dictionary
var settings_paths = GameSettings.get_paths()
var player_upgrade_points: Dictionary


func _init(_max_points: int):
	max_points = _max_points

func recive_upgrades(player_id: int, upgrades: Dictionary):
	if !is_recive_upgrades_input_valid(player_id, upgrades):
		return
	var available_upgrade_points = player_upgrade_points[player_id]
	var sum = 0
	for upgrade in upgrades:
		var val = upgrades[upgrade]
		sum += val
	var points_left = sum - available_upgrade_points
	player_upgrade_points[player_id] = points_left
	temp_upgrades[player_id] = upgrades

func is_recive_upgrades_input_valid(player_id, upgrades) -> bool:
	if !player_upgrade_points.has(player_id):
		printerr("[Main]: Upgrades may be recived only once per game. New upgrades droped.")
		return false
	var available_upgrade_points = player_upgrade_points[player_id]
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
		val = clamp(val, 0, max_points+1)
		if val == 0 or val == max_points+1:
			printerr("[Main]: Value out of range. Upgrades droped.")
			return false
		sum += val
	if sum > available_upgrade_points:
		printerr("[Main]: More spended points than kills. Upgrades droped.")
		return false
	return true

func add_temp_upgrades_to_player_data():
	for player_id in temp_upgrades:
		var player_data_upgrades = Data.players[player_id].Upgrades
		for upgrade in temp_upgrades[player_id]:
			if player_data_upgrades.has(upgrade):
				player_data_upgrades[upgrade] += temp_upgrades[player_id][upgrade]
				continue
			player_data_upgrades[upgrade] = temp_upgrades[player_id][upgrade]

func choose_player_upgrades(player_id):
	var upgrades: Array = []
	var size = settings_paths.size()
	for _i in range(MAX_UPGRADES):
		randomize()
		upgrades.append(settings_paths[randi() % size])
	player_choosen_upgrades[player_id] = upgrades

func set_points_to_upgrade_points(wreck_data, slayer_id, is_slayer_dead):
	if is_slayer_dead:
		if player_upgrade_points.has(slayer_id):
			player_upgrade_points[int(slayer_id)] += 1
		else:
			player_upgrade_points[int(slayer_id)] = 1
	player_upgrade_points[wreck_data.ID] = wreck_data.Kills
	
