# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name GameSettingsTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://Code/Singletons/GameSettings.gd'


func test_set_dynamic_settings() -> void:
	var dict = GameSettings.Dynamic
	GameSettings.set_dynamic_settings()
	check_value(dict)

func check_value(dict):
	if typeof(dict) != TYPE_DICTIONARY:
		assert_that(dict).is_not_null()
		return
	for key in dict:
		check_value(dict[key])


func test_default_existance() -> void:
	for upgrade_path in GameSettings.DEFAULT:
		check_existance(upgrade_path)

func test_special_default_existance() -> void:
	for upgrade_path in GameSettings.SPECIAL_DEFAULT:
		check_existance(upgrade_path)

func check_existance(upgrade_path):
	var temp_dict = GameSettings.Dynamic
	for path_pice in upgrade_path:
		assert_dict(temp_dict).contains_keys([path_pice])
		if !temp_dict.has(path_pice):
			break
		temp_dict = temp_dict[path_pice]



func test_setup_one_upgrade() -> void:
	Data.players = {
		1:{
			"Upgrades":{
				["Tank", "Speed"]: 3
			}
		}
	}
	GameSettings.set_dynamic_settings()
	assert_float(GameSettings.Dynamic.Tank.Speed).is_equal(130)

func test_setup_two_upgrades() -> void:
	Data.players ={
		1:{
			"Upgrades":{
				["Tank", "Speed"]: 5,
				["Wreck", "LifeTime"]: 10,
			}
		}
	}
	GameSettings.set_dynamic_settings()
	assert_float(GameSettings.Dynamic.Tank.Speed).is_equal(150)
	assert_float(GameSettings.Dynamic.Wreck.LifeTime).is_equal(40)

func test_setup_inner_upgrade() -> void:
	Data.players ={
		1:{
			"Upgrades":{
				["Ammunition", Ammunition.TYPES.FRAG_BOMB, "Frag", "Scale"]: 2
			}
		}
	}
	GameSettings.set_dynamic_settings()
	assert_float(GameSettings.Dynamic.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag.Scale).is_equal(0.6)

func test_setup_multiple_players() -> void:
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
	GameSettings.set_dynamic_settings()
	assert_float(GameSettings.Dynamic.Tank.Speed).is_equal(120)
	assert_float(GameSettings.Dynamic.Wreck.LifeTime).is_equal(30)
	assert_float(GameSettings.Dynamic.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag.Scale).is_equal(0.55)

func test_setup_special_upgrade() -> void:
	Data.players ={
		1:{
			"Upgrades":{
				["Tank", "BaseAmmoType"]:  Ammunition.TYPES.ROCKET,
				["Visibility"]: false,
			}
		},
	}
	GameSettings.set_dynamic_settings()
	assert_int(GameSettings.Dynamic.Tank.BaseAmmoType).is_equal(Ammunition.TYPES.ROCKET)
	assert_bool(GameSettings.Dynamic.Visibility).is_false()
	
	
