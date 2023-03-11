extends GDScript

const MAX_UPGRADES = GameSettings.MAX_UPGRADES
var player_choosen_upgrades: Dictionary

var winner = null
var special_choosen_upgrades: Dictionary

var max_points
var temp_upgrades: Dictionary
var settings_paths = GameSettings.DEFAULT.keys()
var player_upgrade_points: Dictionary


func _init(_max_points: int):
	max_points = _max_points
	set_random_special_upgrades()



func set_random_special_upgrades():
	var all_special_choosen_upgrades = GameSettings.SPECIAL_DEFAULT.duplicate(true)
	for upgrade in all_special_choosen_upgrades:
		randomize()
		if Data.current_special_upgrades.has(upgrade) and Data.current_special_upgrades[upgrade].RoundsLeft > 0:
			continue
		var choosen_ammo = randi() % 2 + 4
		special_choosen_upgrades[upgrade] = choosen_ammo


func recive_upgrades(player_id: int, upgrades: Dictionary):
	if player_id == winner:
		var upgrade_path = upgrades.keys()[0]
		if !special_choosen_upgrades.has(upgrade_path):
			print("[Upgrades]: I dont have it")
			return
		if player_upgrade_points[player_id] <= 0:
			print("[Upgrades]: Not enough points")
			return 
		var dict = {
			"Val": special_choosen_upgrades[upgrade_path], 
			"RoundsLeft": player_upgrade_points[player_id]
		}
		Data.current_special_upgrades[upgrade_path] = dict
		player_upgrade_points[player_id] = 0
		return
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
		printerr("[Main]: Plyayer do not exist on list of awaiting upgrade. New upgrades droped.")
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

func remove_passed_special_upgrades():
	for special_upgrade in Data.current_special_upgrades:
		if Data.current_special_upgrades[special_upgrade].RoundsLeft <= 0:
			var _err = Data.current_special_upgrades.erase(special_upgrade)
		else:
			Data.current_special_upgrades[special_upgrade].RoundsLeft -=1

func add_temp_upgrades_to_player_data():
	for player_id in temp_upgrades:
		if !Data.players.has(player_id):
			continue
		var player_data_upgrades = Data.players[player_id].Upgrades
		for upgrade in temp_upgrades[player_id]:
			assert(!GameSettings.SPECIAL_DEFAULT.has(upgrade), "[Upgrades]: Something went wrong")
			if player_data_upgrades.has(upgrade):
				player_data_upgrades[upgrade] += temp_upgrades[player_id][upgrade]
				continue
			player_data_upgrades[upgrade] = temp_upgrades[player_id][upgrade]

func choose_player_upgrades(player_id):
	var upgrades: Array = []
	var size = settings_paths.size()
	var repetition_counter = 0
	while upgrades.size() < MAX_UPGRADES:
		randomize()
		var new_upgrade = settings_paths[randi() % size]
		if !upgrades.has(new_upgrade):
			upgrades.append(new_upgrade)
			continue
		repetition_counter += 1
		if repetition_counter > MAX_UPGRADES * 2:
			break
	player_choosen_upgrades[player_id] = upgrades


func set_upgrade_points(player_id, kills):
	player_upgrade_points[player_id] = kills

func add_points_to_slayer(slayer_id):
	if player_upgrade_points.has(slayer_id):
		player_upgrade_points[int(slayer_id)] += 1
	else:
		player_upgrade_points[int(slayer_id)] = 1
	var data = {
		"Upgrades": player_choosen_upgrades[slayer_id],
		"AdditionalPoint": 1,
		"State": null
	}
	Transfer.send_player_possible_upgrades(slayer_id, data)

func block_points(player_id):
	player_upgrade_points[player_id] = -INF


func make_upgrade(player_data, state):
	var player_id = player_data.ID
	var kills = player_data.Kills
	set_upgrade_points(player_id, kills)
	var data = {
		"Upgrades": player_choosen_upgrades[player_id],
		"Points": player_upgrade_points[player_id],
		"State": state
	}
	if state == "Winner":
		winner = player_id
		data.Upgrades = special_choosen_upgrades
	Transfer.send_player_possible_upgrades(player_id, data)
	if state == "SelfDestroyed":
		block_points(player_id)


func _on_player_destroyed(wreck_data, slayer_id, is_slayer_dead):
	var state = "Normal"
	if wreck_data.ID == slayer_id:
		state = "SelfDestroyed"
	if is_slayer_dead:
		add_points_to_slayer(slayer_id)
	make_upgrade(wreck_data, state)
