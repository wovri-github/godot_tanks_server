# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name MainTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://Code/Main/Main.gd'
const main_tscn = 'res://Code/Main/Main.tscn'
const game_tscn = 'res://Code/Main/Game/Game.tscn'
var runner
var player_upgrade_points

func before_test():
	runner = preload(main_tscn).instance()
	runner.game_n = load(game_tscn).instance()
	player_upgrade_points = runner.game_n.player_upgrade_points
	

func test_recive_upgrades_invalid_data() -> void:
	runner.recive_upgrades(1, {[1]: ""})
	runner.player_choosen_upgrades = {1: ["Wreck", "LifeTime"]}
	runner.game_n.player_upgrade_points = {1: 3}
	runner.recive_upgrades(1, {"[1]asfasdga": 3})
	runner.game_n.player_upgrade_points = {1: 3}
	runner.recive_upgrades(2, {[1, 2, 5, 4, 2]: [2,3,5]})
	runner.game_n.player_upgrade_points = {1: 3}
	runner.recive_upgrades(1, {[1, "ABC"]: "3"})
	runner.game_n.player_upgrade_points = {1: 3}
	runner.recive_upgrades(1, {["Tank", "Speed"]: 5})
	runner.game_n.player_upgrade_points = {1: 3}
	runner.recive_upgrades(1, {["Tank", "Speed"]: 5, ["Tanks", "Speed"]: 5})
	runner.game_n.player_upgrade_points = {1: 3}
	runner.recive_upgrades(1, {[]: 5})
	runner.game_n.player_upgrade_points = {1: 3}
	runner.recive_upgrades(1, {["Tank", "Speed"]: 2, ["Wreck", "LifeTime"]: 2})
	runner.game_n.player_upgrade_points = {1: 3}
	runner.recive_upgrades(1, {["Ammunition"]: 1})
	runner.game_n.player_upgrade_points = {1: 3}
	runner.recive_upgrades(1, {["Tank", "Speed"]: 2})
	assert_dict(runner.temp_upgrades).is_empty()

func test_recive_upgrades_one_upgrade_one_player() -> void:
	runner.game_n.player_upgrade_points = {1: 3}
	var upgrade = {["Tank", "Speed"]: 3}
	runner.player_choosen_upgrades = {1: [["Tank", "Speed"]]}
	runner.recive_upgrades(1, upgrade)
	assert_dict(runner.temp_upgrades).contains_key_value(1, upgrade)
	
func test_recive_upgrades_two_upgrades_one_player() -> void:
	runner.game_n.player_upgrade_points = {1: 6}
	var upgrade = {["Tank", "Speed"]: 3, ["Tank", "MaxAmmo"]: 3}
	runner.player_choosen_upgrades = {1: [["Tank", "Speed"],["Tank", "MaxAmmo"]]}
	runner.recive_upgrades(1, upgrade)
	assert_dict(runner.temp_upgrades).contains_key_value(1, upgrade)
	
func test_recive_upgrades_two_upgrades_two_players() -> void:
	runner.game_n.player_upgrade_points = {1: 6, 2:9}
	var upgrade = {["Tank", "Speed"]: 3, ["Tank", "MaxAmmo"]: 3}
	runner.player_choosen_upgrades = {1: [["Tank", "Speed"],["Tank", "MaxAmmo"]]}
	runner.recive_upgrades(1, upgrade)
	var upgrade2 = {["Ammunition",0 , "Speed"]: 3, ["Tank", "MaxAmmo"]: 3}
	runner.player_choosen_upgrades[2] = [["Ammunition",0 , "Speed"],["Tank", "MaxAmmo"]]
	runner.recive_upgrades(2, upgrade2)
	assert_dict(runner.temp_upgrades).contains_key_value(1, upgrade).contains_key_value(2, upgrade2)



func test_add_temp_upgrades_to_player_data() -> void:
	runner.player_data[1] = {
			"ID": 1,
			"Nick": "",
			"Color": null,
			"Score": {
				"Wins": 0,
				"Kills": 0,
			},
			"Upgrades": {}
	}
	var upgrade = {["Tank", "Speed"]: 3, ["Tank", "MaxAmmo"]: 3}
	runner.temp_upgrades = {1: upgrade}
	runner.add_temp_upgrades_to_player_data()
	runner.temp_upgrades.clear()
	runner.temp_upgrades = {1: upgrade}
	runner.add_temp_upgrades_to_player_data()
	assert_dict(runner.player_data[1]["Upgrades"])\
			.contains_key_value(["Tank", "Speed"], 6)\
			.contains_key_value(["Tank", "MaxAmmo"], 6)
