# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name GameTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = 'res://Code/Main/Game/Game.gd'
#var game_n = preload(__source).new()

func test_setup_null() -> void:
	var game_n = preload(__source).new()
	var upgrades = []
	var target_dict = GameSettings.get_duplicate_settings()
	game_n.setup(upgrades)
	assert_dict(game_n.settings).is_not_empty()
	game_n.queue_free()

func test_setup_one_upgrade() -> void:
	var game_n = preload(__source).new()
	var upgrades = [
		{
			["Tank", "Speed"]: 5
		}
	]
	var dict = GameSettings.get_duplicate_settings()
	dict.Tank.Speed += 5
	game_n.setup(upgrades)
	assert_dict(game_n.settings.Tank).contains_key_value("Speed", dict.Tank.Speed)
	game_n.queue_free()
	
func test_setup_two_upgrades() -> void:
	var game_n = preload(__source).new()
	var upgrades = [
		{
			["Tank", "Speed"]: 5
		},
		{
			["Wreck", "LifeTime"]: 10
		},
	]
	var dict = GameSettings.get_duplicate_settings()
	dict.Tank.Speed += 5
	dict.Wreck.LifeTime += 10
	game_n.setup(upgrades)
	assert_dict(game_n.settings.Tank)\
			.contains_key_value("Speed", dict.Tank.Speed)
	assert_dict(game_n.settings.Wreck)\
			.contains_key_value("LifeTime", dict.Wreck.LifeTime)
	game_n.queue_free()

func test_setup_inner_upgrade() -> void:
	var game_n = preload(__source).new()
	var upgrades = [
		{
			["Ammunition", Ammunition.TYPES.FRAG_BOMB, "Frag", "Scale"]: 0.5
		},
	]
	var dict = GameSettings.get_duplicate_settings()
	dict.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag.Scale += 0.5
	game_n.setup(upgrades)
	assert_dict(game_n.settings.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag)\
			.contains_key_value("Scale", dict.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag.Scale)
	game_n.queue_free()

func test_setup_multiple_players() -> void:
	var game_n = preload(__source).new()
	var upgrades = [
		{
			["Tank", "Speed"]: 5
		},
		{
			["Tank", "Speed"]: 5
		},
		{
			["Wreck", "LifeTime"]: 10,
			["Tank", "Speed"]: 5
		},
		{
			["Ammunition", Ammunition.TYPES.FRAG_BOMB, "Frag", "Scale"]: 0.5
		},
		{
			["Ammunition", Ammunition.TYPES.FRAG_BOMB, "Frag", "Scale"]: 0.5
		},
	]
	var dict = GameSettings.get_duplicate_settings()
	dict.Tank.Speed += 15
	dict.Wreck.LifeTime += 10
	dict.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag.Scale += 1
	game_n.setup(upgrades)
	assert_dict(game_n.settings.Wreck)\
			.contains_key_value("LifeTime", dict.Wreck.LifeTime)
	assert_dict(game_n.settings.Tank)\
			.contains_key_value("Speed",dict.Tank.Speed)
	assert_dict(game_n.settings.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag)\
			.contains_key_value("Scale", dict.Ammunition[Ammunition.TYPES.FRAG_BOMB].Frag.Scale)
	game_n.queue_free()
