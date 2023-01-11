extends Node

onready var tilemap_n = $"%TileMap"
onready var spawn_points_n = $"%SpawnPoints"
onready var ammo_boxes_n = $"%AmmoBoxes"

const TILESIZE = 64

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


func _next_free_tile(map : Array) -> Array:
	for y in map.size():
		for x in map[y].size():
			if map[y][x] == 1:
				return [x, y]
	return []

func get_coords_from_direction(current_coords, direction):
	if direction == 0:  return [current_coords[0],current_coords[1]-1]
	if direction == 1:  return [current_coords[0]+1,current_coords[1]]
	if direction == 2:  return [current_coords[0],current_coords[1]+1]
	return [current_coords[0]-1,current_coords[1]]

func turn_left_coords(d,x,y,corners):
	if d == 0:  corners.push_back(Vector2(x*TILESIZE, (y+1)*TILESIZE))
	elif d == 1:  corners.push_back(Vector2(x*TILESIZE, y*TILESIZE))
	elif d == 2:  corners.push_back(Vector2((x+1)*TILESIZE, y*TILESIZE))
	else:  corners.push_back(Vector2((x+1)*TILESIZE, (y+1)*TILESIZE))

func turn_right_coords(d,x,y,corners):
	if d == 0:  corners.push_back(Vector2(x*TILESIZE, y*TILESIZE))
	elif d == 1:  corners.push_back(Vector2((x+1)*TILESIZE, y*TILESIZE))
	elif d == 2:  corners.push_back(Vector2((x+1)*TILESIZE, (y+1)*TILESIZE))
	else:  corners.push_back(Vector2(x*TILESIZE, (y+1)*TILESIZE))

func turn_back_coords(d,x,y,corners):
	if d == 0:
		corners.push_back(Vector2(x*TILESIZE, y*TILESIZE))
		corners.push_back(Vector2((x+1)*TILESIZE, y*TILESIZE))
	elif d == 1:
		corners.push_back(Vector2((x+1)*TILESIZE, y*TILESIZE))
		corners.push_back(Vector2((x+1)*TILESIZE, (y+1)*TILESIZE))
	elif d == 2:
		corners.push_back(Vector2((x+1)*TILESIZE, (y+1)*TILESIZE))
		corners.push_back(Vector2(x*TILESIZE, (y+1)*TILESIZE))
	else:
		corners.push_back(Vector2(x*TILESIZE, (y+1)*TILESIZE))
		corners.push_back(Vector2(x*TILESIZE, y*TILESIZE))

func step(map, last_direction, current_field, corners,rect):
	map[current_field[1]][current_field[0]] = 2
	if len(corners) >= 2 and corners[0] == corners[-1]:
		return []
	elif len(corners) >= 3 and corners[0] == corners[-2]:
		corners.pop_back()
		return []
	
	for i in range(4): # left forward right back
		var d = (last_direction - 1 + i + 4) % 4
		var c = get_coords_from_direction(current_field, d)
		if c[0] >= 0 and c[0] < len(map[0]) and c[1] >= 0 and c[1] < len(map) and map[c[1]][c[0]] >= 1:
			if i == 0:  turn_left_coords(last_direction, current_field[0]+rect.position[0], current_field[1]+rect.position[1], corners)
			if i == 2:  turn_right_coords(last_direction, current_field[0]+rect.position[0], current_field[1]+rect.position[1], corners)
			if i == 3:  turn_back_coords(last_direction, current_field[0]+rect.position[0], current_field[1]+rect.position[1], corners)
			return [d, [c[0],c[1]]]
	
	corners.push_back(Vector2((current_field[0]+rect.position[0])*TILESIZE, (current_field[1]+rect.position[1])*TILESIZE))
	corners.push_back(Vector2((current_field[0]+1+rect.position[0])*TILESIZE, (current_field[1]+rect.position[1])*TILESIZE))
	corners.push_back(Vector2((current_field[0]+1+rect.position[0])*TILESIZE, (current_field[1]+1+rect.position[1])*TILESIZE))
	corners.push_back(Vector2((current_field[0]+rect.position[0])*TILESIZE, (current_field[1]+1+rect.position[1])*TILESIZE))
	corners.push_back(Vector2((current_field[0]+rect.position[0])*TILESIZE, (current_field[1]+rect.position[1])*TILESIZE))
	return []

func _ready():
	var map = []
	var rect = tilemap_n.get_used_rect()
	for y in range(rect.position[1], rect.end[1]):
		var row = []
		for x in range(rect.position[0], rect.end[0]):
			row.push_back(tilemap_n.get_cell(x,y)+1)
		map.push_back(row)
	
	var current_tile = _next_free_tile(map)
	while !current_tile.empty():
		var corners = []
		# 0 - up    1 - right   2 - down    3 - left
		var last_direction = 0
		var s = step(map,last_direction,current_tile,corners,rect)
		while !s.empty():
			s = step(map,s[0],s[1], corners,rect)
		corners.pop_back()
		var pool = PoolVector2Array(corners)
		var poly = CollisionPolygon2D.new()
		poly.set_polygon(pool)
		$StaticBody2D.add_child(poly, true)
		print(pool)
		
		current_tile = _next_free_tile(map)

