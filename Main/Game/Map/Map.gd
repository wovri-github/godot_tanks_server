extends Node

signal map_created

const ammo_box_tscn = preload("res://Objects/AmmoBox.tscn")
#const TILE_MAP_TSCN = preload("res://Main/Game/Map/TileMap.tscn")
const TYPE = MapGlobal.TILE_TYPE

var number_of_repetition = 0
var rng = RandomNumberGenerator.new()
var is_map_exist = false

onready var tilemap_n = $"TileMap"
onready var ammo_boxes_n = $"%AmmoBoxes"



func _ready():
#	generate_new_map()
	rng.randomize()
	spawn_ammo_boxes()
	emit_signal("map_created")


func spawn_ammo_boxes():
	for _i in tilemap_n.get_used_cells_by_id(TYPE.AMMO):
		var global_position = tilemap_n.get_random_point(TYPE.AMMO)
		var ammo_box = ammo_box_tscn.instance()
		ammo_box.position = global_position
#		ammo_box.set_type(rng.randi_range(1, Ammunition.TYPES.size()-1))
		#test
		ammo_box.set_type(1)
		ammo_boxes_n.add_child(ammo_box, true)

func get_spawn_position() -> Vector2:
	var global_position = tilemap_n.get_random_point(TYPE.SPAWN)
	return global_position


func get_map_data():
	var map_data = {
		"MapSet": tilemap_n.get_used_cells_by_id(0),
		"AB": _get_ammo_boxes(),
		"Scale": tilemap_n.scale
	}
	return map_data

func _get_ammo_boxes():
	var ammo_boxes_data: Array = []
	for ab in ammo_boxes_n.get_children():
		ammo_boxes_data.append({
			"P": ab.get_position(),
			"Type": ab.type,
		})
	return ammo_boxes_data
