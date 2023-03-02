# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name GameTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://Code/Main/Game/Game.gd'
var game_n

func before():
	game_n = preload(__source).new()


func test_add_upgrades_to_settings_null() -> void:
	game_n.add_upgrades_to_settings()
	assert_dict(game_n.settings).is_not_empty()

func test_setup_one_upgrade() -> void:
	var game_n = preload(__source).new()
	Data.players = {
		1:{
			"Upgrades":{
				["Tank", "Speed"]: 3
			}
		}
	}
	var dict = GameSettings.get_duplicate_settings()
	dict.Tank.Speed += 30
	game_n.add_upgrades_to_settings()
	assert_dict(game_n.settings.Tank).contains_key_value("Speed", dict.Tank.Speed)
	game_n.queue_free()
	
func test_setup_two_upgrades() -> void:
	var game_n = preload(__source).new()
	Data.players ={
		1:{
			"Upgrades":{
				["Tank", "Speed"]: 5,
				["Wreck", "LifeTime"]: 10,
			}
		}
	}
	var dict = GameSettings.get_duplicate_settings()
	dict.Tank.Speed += float(50)
	dict.Wreck.LifeTime += float(20)
	game_n.add_upgrades_to_settings()
	assert_dict(game_n.settings.Tank)\
			.contains_key_value("Speed", dict.Tank.Speed)
	assert_dict(game_n.settings.Wreck)\
			.contains_key_value("LifeTime", dict.Wreck.LifeTime)
	game_n.queue_free()

func test_setup_inner_upgrade() -> void:
	var game_n = preload(__source).new()
	Data.players ={
		1:{
			"Upgrades":{
				["Ammunition", Ammunition.TYPES.FRAG_BOMB, "Frag", "Scale"]: 1
				
			}
		}
	}
	var dict = GameSettings.get_duplicate_settings()
	dict.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag.Scale += float(0.05)
	game_n.add_upgrades_to_settings()
	assert_dict(game_n.settings.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag)\
			.contains_key_value("Scale", dict.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag.Scale)
	game_n.queue_free()

func test_setup_multiple_players() -> void:
	var game_n = preload(__source).new()
	Data.players ={
		1:{
			"Upgrades":{
				["Tank", "Speed"]: 1,
				
			}
		},
		2:{
			"Upgrades":{
				["Wreck", "LifeTime"]: 5,
				["Tank", "Speed"]: 1,
				
			}
		},
		3:{
			"Upgrades":{
				["Ammunition", Ammunition.TYPES.FRAG_BOMB, "Frag", "Scale"]: 1,
			}
		},
	}
	var dict = GameSettings.get_duplicate_settings()
	dict.Tank.Speed += float(20)
	dict.Wreck.LifeTime += float(10)
	dict.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag.Scale += 0.05
	game_n.add_upgrades_to_settings()
	assert_dict(game_n.settings.Wreck)\
			.contains_key_value("LifeTime", dict.Wreck.LifeTime)
	assert_dict(game_n.settings.Tank)\
			.contains_key_value("Speed",dict.Tank.Speed)
	assert_dict(game_n.settings.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag)\
			.contains_key_value("Scale", dict.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag.Scale)
	game_n.queue_free()
