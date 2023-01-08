extends Node

onready var tilemap_n = $"%TileMap"
onready var spawn_points_n = $"%SpawnPoints"

var last_spawn_point = 0
onready var spawn_pointS: Array = spawn_points_n.get_children()



func get_spawn_position() -> Vector2:
	var spawn_point = spawn_pointS[last_spawn_point]
	last_spawn_point += 1
	last_spawn_point %= spawn_pointS.size()
	return spawn_point.position



func get_mapset():
	return tilemap_n.get_used_cells()
