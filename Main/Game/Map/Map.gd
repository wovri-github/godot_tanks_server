extends Node

onready var tilemap_n = $"%TileMap"



func get_mapset():
	return tilemap_n.get_used_cells()
