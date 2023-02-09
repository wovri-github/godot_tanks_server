extends TileMap

# ---- settings ----
export(int, 0, 100) var MAX_PLAYERS = 16
export(int, 0, 100) var PLAYER_SPAWN_MIN_DISTANCE = 2
export(int, 0, 100) var START_AMMO_BOXES_AMOUNT = 32
export(Vector2) var MAP_SIZE = Vector2(50, 30)
export(float, 0, 1) var EMPTY_CELLS_DENSITY = 0.2
export(float, 0, 1) var EMPTY_RECT_DENSITY = 0.03
export(Vector2) var EMPTY_RECT_MIN_SIZE = Vector2(2,2)
export(Vector2) var EMPTY_RECT_MAX_SIZE = Vector2(4,4)
export(int) var GENERATOR_SEED = 0
# ------------------

enum TURN{FOWARD, LEFT, BACKWARD, RIGHT, FULL}
var TILESIZE = cell_size.x # tiles must be square!!!
const SEQUENCE = [\
		TURN.LEFT,\
		TURN.FOWARD,\
		TURN.RIGHT,\
		TURN.BACKWARD]
var collision_points = []

const player_spawn_marker_tscn = preload("res://Main/Game/Map/PlayerSpawnMarker.tscn")
const ammo_box_tscn = preload("res://Objects/AmmoBox.tscn")
onready var spawn_points_n = $"%SpawnPoints"
onready var ammo_boxes_n = $"%AmmoBoxes"

var rng = RandomNumberGenerator.new()

func _ready():
	_generate_map_shape()
	_generate_collision_shape()
	_generate_player_spawn_points_and_start_ammo_boxes()

# ---- generate shape of the map ----

func _generate_map_shape():
	if !GENERATOR_SEED:
		rng.randomize()
	else:
		rng.seed = GENERATOR_SEED
	
	var visited_cells = []
	for _y in range(1, MAP_SIZE.y + 1, 2):
		var row = []
		for _x in range(1, MAP_SIZE.x + 1, 2):
			row.push_back(false)
		visited_cells.push_back(row)
	for y in range(MAP_SIZE.y + 1):
		for x in range(MAP_SIZE.x + 1):
			if x * y % 2 == 0:
				set_cell(x,y,0)
				
	_generate_maze(visited_cells)
	_generate_empty_rects(visited_cells)
	_generate_empty_cells(visited_cells)
	
	update_bitmask_region(Vector2.ZERO, MAP_SIZE)
	
func _generate_empty_rects(visited_cells : Array):
	for row in visited_cells.size():
		for col in visited_cells[0].size():
			if rng.randf() < EMPTY_RECT_DENSITY:
				var size_x = rng.randi_range(EMPTY_RECT_MIN_SIZE.x, EMPTY_RECT_MAX_SIZE.x)
				var size_y = rng.randi_range(EMPTY_RECT_MIN_SIZE.y, EMPTY_RECT_MAX_SIZE.y)
				for y in range(size_y):
					if row + y >= visited_cells.size():
						break
					for x in range(size_x):
						if col + x >= visited_cells[0].size():
							break
						visited_cells[row + y][col + x] = true
						set_cell(2*col + x + 1, 2*row + y + 1, -1)

func _generate_empty_cells(visited_cells : Array):
	for row in visited_cells.size() - 1:
		for col in visited_cells[0].size() - 1:
			if rng.randf() < EMPTY_CELLS_DENSITY:
				set_cell(2*col+2, 2*row+2, -1)

func _generate_maze(visited_cells : Array):
	var stack = []
	var first_cell = Vector2(\
	rng.randi_range(0, visited_cells[0].size()-1),\
	rng.randi_range(0, visited_cells.size() - 1)\
	)

	visited_cells[first_cell.y][first_cell.x] = true
	stack.push_back(first_cell)

	while !stack.empty():
		var current_cell = stack.pop_back()
		var candidates = []

		if current_cell.y > 0 and !visited_cells[current_cell.y - 1][current_cell.x]:
			candidates.push_back(Vector2(current_cell.x, current_cell.y - 1))

		if current_cell.y < visited_cells.size() - 1 and !visited_cells[current_cell.y + 1][current_cell.x]:
			candidates.push_back(Vector2(current_cell.x, current_cell.y + 1))

		if current_cell.x > 0 and !visited_cells[current_cell.y][current_cell.x - 1]:
			candidates.push_back(Vector2(current_cell.x - 1, current_cell.y))

		if current_cell.x < visited_cells[0].size() - 1 and !visited_cells[current_cell.y][current_cell.x + 1]:
			candidates.push_back(Vector2(current_cell.x + 1, current_cell.y))

		if !candidates.empty():
			stack.push_back(current_cell)
			var index = rng.randi_range(0, candidates.size() - 1)
			# not use shuffle to make maze reproducabe with generator_seed
			var chosen_cell = candidates[index]
			var diff = chosen_cell - current_cell
			set_cellv(current_cell * 2 + diff + Vector2.ONE, -1)
			visited_cells[chosen_cell.y][chosen_cell.x] = true
			stack.push_back(chosen_cell)
			
# ---- generate collision shapes ----

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

func _generate_collision_shape():
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

# ---- generate player spawn points and start ammo boxes----
func _generate_player_spawn_points_and_start_ammo_boxes():
	var available_spots = []
	for y in range(1, MAP_SIZE.y + 1, 2):
		for x in range(1, MAP_SIZE.x + 1, 2):
			available_spots.push_back(Vector2(x, y))
	
	_generate_player_spawn_points(available_spots)
	_generate_start_ammo_boxes(available_spots)
		
	
func _generate_player_spawn_points(available_spots):
	for _p in range(MAX_PLAYERS):
		if available_spots.empty():
			print("Not enough space for player spawns!")
			break
		var index = rng.randi_range(0, available_spots.size() - 1)
		var tile_pos = available_spots.pop_at(index)
		
		for y in range(2 * PLAYER_SPAWN_MIN_DISTANCE + 1):
			for x in range(2 * PLAYER_SPAWN_MIN_DISTANCE + 1):
				available_spots.erase(Vector2(tile_pos.x - (PLAYER_SPAWN_MIN_DISTANCE - x) * 2, tile_pos.y - (PLAYER_SPAWN_MIN_DISTANCE - y) * 2))
		
		var pos = Vector2((tile_pos.x+0.5)*TILESIZE*scale.x,(tile_pos.y+0.5)*TILESIZE*scale.y)
		
		var new_spawn_point = Position2D.new()
		new_spawn_point.position = pos
		new_spawn_point.name = "SP"
		spawn_points_n.add_child(new_spawn_point, true)

		var player_spawn_marker = player_spawn_marker_tscn.instance()
		player_spawn_marker.position = pos
		player_spawn_marker.name = "SP"
		get_parent().call_deferred("add_child", player_spawn_marker, true)
		
func _generate_start_ammo_boxes(available_spots):
	for _b in range(START_AMMO_BOXES_AMOUNT):
		if available_spots.empty():
			print("Not enough space for default ammo boxes!")
			break
		var index = rng.randi_range(0, available_spots.size() - 1)
		var tile_pos = available_spots.pop_at(index)
		var pos = Vector2((tile_pos.x+0.5)*TILESIZE*scale.x,(tile_pos.y+0.5)*TILESIZE*scale.y)
		
		var ammo_box = ammo_box_tscn.instance()
		ammo_box.position = pos
		ammo_boxes_n.add_child(ammo_box, true)
		ammo_box.set_type(rng.randi_range(1, Ammunition.TYPES.size()-1))
		
		
