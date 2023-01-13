extends Node

onready var tilemap_n = $"%TileMap"
onready var spawn_points_n = $"%SpawnPoints"
onready var ammo_boxes_n = $"%AmmoBoxes"

var last_spawn_point = 0
onready var spawn_pointS: Array = spawn_points_n.get_children()



func get_spawn_position() -> Vector2:
	var spawn_point = spawn_pointS[last_spawn_point]
	last_spawn_point += 1
	last_spawn_point %= spawn_pointS.size()
	return spawn_point.position

func get_ammo_boxes():
	var ammo_boxes_data: Array = []
	for ab in ammo_boxes_n.get_children():
		ammo_boxes_data.append({
			"P": ab.get_position(),
			"Type": ab.type,
		})
	return ammo_boxes_data


func get_map_data():
	var map_data = {
		"MapSet": tilemap_n.get_used_cells(),
		"AB": get_ammo_boxes()
	}
	return map_data
