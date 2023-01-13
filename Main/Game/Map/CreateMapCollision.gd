extends TileMap
# [info] Map cannot be on negative coordinates and have to start from 0,0

enum TURN{FOWARD, LEFT, BACKWARD, RIGHT, FULL}
const TILESIZE = 64
const SEQUENCE = [\
		TURN.LEFT,\
		TURN.FOWARD,\
		TURN.RIGHT,\
		TURN.BACKWARD]
var collision_points = []


func _matrix_map(map, up_left_corners, rect):
	for y in range(rect.position.y, rect.end.y):
		var row = []
		for x in range(rect.position.x, rect.end.x):
			row.push_back(get_cell(x,y)+1)
			if y <= 0 or x <= 0:
				continue
			if row[-1] == 1 and get_cell(x,y-1)+1 == 0 and get_cell(x-1,y)+1 == 0:
				up_left_corners.push_back(Vector2(x,y))
		map.push_back(row)
	# [info] make first block as 0 and put nextone as corner
	map[0][0] = 0
	up_left_corners.push_back(Vector2(1,0))

func _turn(current_pos: Vector2, step):
	for _i in range(step):
		current_pos = current_pos.tangent()
	return current_pos

func _go(steps, last_direction, corners, pointer):
	if steps == 0:
		corners.push_back(pointer)
		return pointer
	pointer = pointer + _turn(last_direction, SEQUENCE[1]) * TILESIZE
	steps -=1
	for move in steps:
		corners.push_back(pointer)
		pointer = pointer + _turn(last_direction, SEQUENCE[(move+2)%4]) * TILESIZE
	return pointer

func step(map, last_direction, current_field, corners, pointer):
	map[current_field.y][current_field.x] = 2
	if len(corners) >= 2 and corners[0] == corners[-1]:
		return []
	elif len(corners) >= 3 and corners[0] == corners[-2]:
		corners.pop_back()
		return []
	for step in range(4):
		var new_direction = _turn(last_direction, SEQUENCE[step])
		var new_field = current_field + new_direction
		if new_field.y >= 0 and new_field.y < len(map)\
				and new_field.x >= 0 and new_field.x < len(map[0])\
				and map[new_field.y][new_field.x] >= 1\
		:
			pointer = _go(step, last_direction, corners, pointer)
			return {
				"LastDirection": new_direction,
				"CurrentTile": new_field,
				"Pointer": pointer
			}
	_go(4, last_direction, corners, pointer)
	corners.push_back(pointer)
	corners.push_back(pointer)
	return []

func _ready():
	var map = []
	var up_left_corners = []
	var rect = get_used_rect()
	_matrix_map(map, up_left_corners, rect)
	while !up_left_corners.empty():
		var current_tile = up_left_corners.pop_front()
		if map[current_tile.y][current_tile.x] != 1:
			continue
		var corners = []
		var last_direction = Vector2.RIGHT
		var pointer = (current_tile + rect.position) * TILESIZE
		var varibles = step(map, last_direction, current_tile, corners, pointer)
		while !varibles.empty():
			varibles = step(map, varibles.LastDirection, varibles.CurrentTile, corners, varibles.Pointer)
		corners.pop_back()
		var pool = PoolVector2Array(corners)
		var poly = CollisionPolygon2D.new()
		poly.set_polygon(pool)
		collision_points.push_back(pool)
		$StaticBody2D.add_child(poly)
