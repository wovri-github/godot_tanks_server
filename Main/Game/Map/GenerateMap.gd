extends TileMap
# [INFORMATION]:
# This node contains only possible places for objects.
# Object existance should be in other place.
# Only walls could be generated there!


# ---- settings ----
export(int, 0, 100) var MAX_PLAYERS = 16
export(int, 0, 100) var PLAYER_SPAWN_MIN_DISTANCE = 2
export(int, 0, 100) var AMMOBOX_MIN_DISTANCE = 1
export(Vector2) var MAP_SIZE = Vector2(50, 30)
export(float, 0, 1) var EMPTY_CELLS_DENSITY = 0.2
export(float, 0, 1) var EMPTY_RECT_DENSITY = 0.03
export(Vector2) var EMPTY_RECT_MIN_SIZE = Vector2(2,2)
export(Vector2) var EMPTY_RECT_MAX_SIZE = Vector2(4,4)
export(int, 0, 100) var MAX_WALL_LENGTH = 9
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
var rng = RandomNumberGenerator.new()
#---
const TILE_TYPE = MapGlobal.TILE_TYPE
const SIMPLE_DIRECTION = [
	Vector2.UP, 
	Vector2.RIGHT,
	Vector2.DOWN,
	Vector2.LEFT,
]
const DIRECTIONS: Array = [
	Vector2.UP, 
	Vector2.UP + Vector2.RIGHT,
	Vector2.RIGHT,
	Vector2.DOWN + Vector2.RIGHT,
	Vector2.DOWN,
	Vector2.DOWN + Vector2.LEFT,
	Vector2.LEFT,
	Vector2.UP + Vector2.LEFT
]
var points: Dictionary setget set_points
var enough_players = false
var repetition = 0



func set_points(tile_type):
	points[tile_type] = get_used_cells_by_id(tile_type)
	

func get_random_point(tile_type):
	var pointS = points[tile_type]
	var pos = rng.randi_range(0, pointS.size()-1)
	var glob_pos = map_to_world(pointS.pop_at(pos)) + Vector2(TILESIZE * 0.5, TILESIZE * 0.5)
	return glob_pos


func _ready():
	if !GENERATOR_SEED:
		rng.randomize()
	else:
		rng.seed = GENERATOR_SEED
	set_values_logick()
	_generate_map_shape()
	_generate_player_spawn_points_and_start_ammo_boxes()
	if enough_players == false:
		repetition += 1
		clear()
		_ready()
		return
	_generate_collision_shape()
	for tile_type in TILE_TYPE.values():
		if tile_type == TILE_TYPE.WALL:
			continue
		set_points(tile_type)


func set_values_logick():
	MAX_PLAYERS = get_node("/root/Main").player_data.size()
	MAX_PLAYERS = 16
	define_map_size()
	define_removing_cell()

func define_map_size():
	var side
	if MAX_PLAYERS < 4:
		side = 9 + repetition
	else:
		side = floor(sqrt(MAX_PLAYERS-1) * 6) + repetition
	MAP_SIZE = Vector2(side, side)
	MAP_SIZE += Vector2(rng.randi_range(0, min(MAX_PLAYERS, 10)), rng.randi_range(0, min(MAX_PLAYERS, 10)))
	MAP_SIZE.x += int(MAP_SIZE.x) % 2
	MAP_SIZE.y += int(MAP_SIZE.y) % 2
	print(MAP_SIZE, "Rep: ", repetition)

func define_removing_cell():
	EMPTY_CELLS_DENSITY = 0.02 * MAX_PLAYERS
	EMPTY_RECT_DENSITY = 0.003 * MAX_PLAYERS
	EMPTY_RECT_MIN_SIZE = Vector2(2, 2)
	EMPTY_RECT_MAX_SIZE = Vector2(int(MAP_SIZE.x/10 + 3),  int(MAP_SIZE.y/10 + 3))
	
# ---- generate shape of the map ----

func _generate_map_shape():
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
	for _i in range(10):
		if !_remove_long_walls():
			break
	update_bitmask_region(Vector2.ZERO, MAP_SIZE)

func _remove_long_walls():
	var check_again: bool = false
	var rect = get_used_rect()
	var rows = rect.size.y
	var cols = rect.size.x
	var matrix = create_matrix(rows, cols)
	fill_matrix_inner_wall(matrix, get_used_cells_by_id(TILE_TYPE.WALL), rows, cols)
	var complexs = look_for_complex_walls(matrix, rows, cols)
	for complex in complexs:
		if complex.size() > MAX_WALL_LENGTH:
			check_again = true
			destroy_complex(matrix, complex)
	return check_again

func create_matrix(rows, cols):
	var matrix = []
	for i in range(rows):
		var row = []
		for j in range(cols):
			row.append(0)
		matrix.append(row)
	return matrix

func fill_matrix_inner_wall(matrix, positions: Array, rows, cols):
	for pos in positions:
		if pos.x != 0 and pos.y != 0 and pos.y != rows - 1 and pos.x != cols - 1:
			matrix[pos.y][pos.x] = 1

func look_for_complex_walls(_matrix, rows, cols) -> Array:
	var matrix = _matrix.duplicate(true)
	var complexes: Array
	var check_positions: Array
	for y in range(rows):
		for x in range(cols):
			if matrix[y][x] == 1:
				var positions_vector: PoolVector2Array
				check_positions.append(Vector2(y, x))
				while check_positions.empty() == false:
					var pos = check_positions.pop_front()
					positions_vector.append(pos)
					hunt_element(matrix, pos, check_positions)
				complexes.append(positions_vector)
	return complexes

func hunt_element(matrix, pos, check_positions):
	matrix[pos.x][pos.y] = 0
	for dir in DIRECTIONS:
		var new_pos = pos + dir
		if matrix[new_pos.x][new_pos.y] == 1:
			if !check_positions.has(new_pos):
				check_positions.append(new_pos)

func destroy_complex(matrix, complex: PoolVector2Array):
	var size = complex.size()
	var number_of_cuts = size / MAX_WALL_LENGTH
	var step_size = size / (number_of_cuts+1)
	var middle_indexes: Array
	for i in range(number_of_cuts):
		i += 1
		middle_indexes.append(round(step_size * i))
	find_cut_position(matrix, complex, middle_indexes)

func find_cut_position(matrix, complex, middle_indexes):
	for index in middle_indexes:
		var cut_proposition = complex[index]
		set_cell(cut_proposition.y, cut_proposition.x, -1)
		for dir in SIMPLE_DIRECTION:
			var second_cut_position = cut_proposition + dir
			if matrix[second_cut_position.x][second_cut_position.y] == 1:
				break
				set_cell(cut_proposition.y, cut_proposition.x, -1)


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

func fill_matrix_wall(matrix, positions: Array):
	for pos in positions:
		var x = pos.y
		var y = pos.x
		matrix[x][y] = 1
	matrix[0][0] = 0

func find_up_left_corners(matrix, rows, cols, up_left_corners):
	up_left_corners.push_back(Vector2(1,0))
	for y in rows:
		for x in cols:
			if matrix[y][x] == 1:
				if x <= 0 or y <= 0:
					continue
				if get_cell(x,y-1) != TILE_TYPE.WALL and get_cell(x-1,y) != TILE_TYPE.WALL:
					up_left_corners.push_back(Vector2(x,y))
	

func _generate_collision_shape():
	var up_left_corners = []
	var rect = get_used_rect()
	var rows = rect.size.y
	var cols = rect.size.x
	var matrix2 = create_matrix(rows, cols)
	fill_matrix_wall(matrix2, get_used_cells_by_id(TILE_TYPE.WALL))
	find_up_left_corners(matrix2, rows, cols, up_left_corners)
	while !up_left_corners.empty():
		var current_tile = up_left_corners.pop_front()
		if matrix2[current_tile.y][current_tile.x] != 1:
			continue
		var corners = []
		var last_direction = Vector2.RIGHT
		var pointer = (current_tile + rect.position) * TILESIZE
		var varibles = step(matrix2, last_direction, current_tile, corners, pointer)
		while !varibles.empty():
			varibles = step(matrix2, varibles.LastDirection, varibles.CurrentTile, corners, varibles.Pointer)
		corners.pop_back()
		var pool = PoolVector2Array(corners)
		var poly = CollisionPolygon2D.new()
		poly.set_polygon(pool)
		collision_points.push_back(pool)
		$StaticBody2D.add_child(poly)

# ---- generate player spawn points and start ammo boxes----
func _generate_player_spawn_points_and_start_ammo_boxes():
	var available_spots = find_available_spots()
	var available_ammo_boxes = available_spots
	var available_spawn_points = available_spots.duplicate(true)
	enough_players = _generate_player_spawn_points(available_spawn_points, available_ammo_boxes)
	_generate_start_ammo_boxes(available_ammo_boxes)

func find_available_spots() -> Array:
	var available_spots = []
	for y in range(1, MAP_SIZE.y + 1, 2):
		for x in range(1, MAP_SIZE.x + 1, 2):
			available_spots.push_back(Vector2(x, y))
	return available_spots

func _generate_player_spawn_points(available_spawn_points, available_ammo_boxes: Array) -> bool:
	for _i in range(MAX_PLAYERS):
		if available_spawn_points.empty():
			return false
		var index
		var tile_pos
		index = rng.randi_range(0, available_spawn_points.size() - 1)
		tile_pos = available_spawn_points.pop_at(index)
		available_ammo_boxes.erase(tile_pos)
		set_cellv(tile_pos, TILE_TYPE.SPAWN)
		remove_avilable_places_until_wall(tile_pos, available_spawn_points, INF)
		remove_avilable_places_in_range(tile_pos, available_spawn_points)
		remove_avilable_places_until_wall(tile_pos, available_ammo_boxes, AMMOBOX_MIN_DISTANCE * 2)
	return true

# -----------------
# And should not be able to see directly (without wall between) each other
func remove_avilable_places_until_wall(tile_pos, available_spots, distance_to_run):
	for direction in DIRECTIONS:
		var dynamic_distance_to_run = distance_to_run
		var dynamic_tile_pos = tile_pos
		while dynamic_distance_to_run:
			dynamic_distance_to_run -= 1
			dynamic_tile_pos += direction
			var cell = get_cellv(dynamic_tile_pos)
			if cell == TILE_TYPE.WALL:
				break
			available_spots.erase(dynamic_tile_pos)

# Logick is that player should not be next to each other
func remove_avilable_places_in_range(tile_pos, available_spots):
	var min_distance_vector = Vector2(PLAYER_SPAWN_MIN_DISTANCE, PLAYER_SPAWN_MIN_DISTANCE)
	for y in range(2 * PLAYER_SPAWN_MIN_DISTANCE + 1):
		for x in range(2 * PLAYER_SPAWN_MIN_DISTANCE + 1):
			var vector = Vector2(x, y)
			available_spots.erase(tile_pos - (min_distance_vector - vector) * 2)

func _generate_start_ammo_boxes(available_spots):
	while available_spots.empty() == false:
		var index = rng.randi_range(0, available_spots.size() - 1)
		var tile_pos = available_spots.pop_at(index)
		var pos = Vector2((tile_pos.x+0.5)*TILESIZE*scale.x,(tile_pos.y+0.5)*TILESIZE*scale.y)
		set_cellv(tile_pos, 2)
		remove_avilable_places_until_wall(tile_pos, available_spots, INF)
		remove_avilable_places_in_range(tile_pos, available_spots)
