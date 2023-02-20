extends TileMap
# [INFORMATION]:
# This node contains only possible places for objects.
# Object existance should be in other place.
# Only walls could be generated there!

############[IMPORTANT]############
# If you gonna ever need to change this and you struggle
# please, just use the UnitTest
# This is for Adam 


# ---- settings ----
export(int, 0, 100) var PLAYER_SPAWN_MIN_DISTANCE = 2
export(int, 0, 100) var AMMOBOX_MIN_DISTANCE = 1
export(int, 0, 100) var MAX_WALL_LENGTH = 9
export(int) var GENERATOR_SEED = 0
var MAX_PLAYERS
var MAP_SIZE
var EMPTY_CELLS_DENSITY
var EMPTY_RECT_DENSITY
var EMPTY_RECT_MIN_SIZE
var EMPTY_RECT_MAX_SIZE 
# ------------------
enum TURN{FOWARD, LEFT, BACKWARD, RIGHT, FULL}
var TILESIZE = cell_size.x # tiles must be square!!!
const SEQUENCE = [
		TURN.LEFT,
		TURN.FOWARD,
		TURN.RIGHT,
		TURN.BACKWARD
]
const OPPOSITE_SEQUENCE = [
		TURN.RIGHT,
		TURN.FOWARD,
		TURN.LEFT,
		TURN.BACKWARD
]
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
	_manage_structure_based_on_polygons()
	for tile_type in TILE_TYPE.values():
		if tile_type == TILE_TYPE.WALL:
			continue
		set_points(tile_type)


func set_values_logick():
	MAX_PLAYERS = get_node("/root/Main").player_data.size()
	define_map_size()
	define_removing_cell()

func define_map_size():
	var side
	if MAX_PLAYERS < 4:
		side = 9 + repetition
	else:
		side = floor(1.3*MAX_PLAYERS + 3) + repetition
	MAP_SIZE = Vector2(side, side)
	MAP_SIZE += Vector2(rng.randi_range(0, min(MAX_PLAYERS, 10)), rng.randi_range(0, min(MAX_PLAYERS, 10)))
	MAP_SIZE.x += int(MAP_SIZE.x) % 2
	MAP_SIZE.y += int(MAP_SIZE.y) % 2

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
	for _i in range(rows):
		var row = []
		for _j in range(cols):
			row.append(0)
		matrix.append(row)
	return matrix

func fill_matrix_inner_wall(matrix, positions: Array, rows, cols):
	for pos in positions:
		if pos.x != 0 and pos.y != 0 and pos.y != rows - 1 and pos.x != cols - 1:
			matrix[pos.y][pos.x] = 1
	return matrix

func look_for_complex_walls(_matrix, rows, cols) -> Array:
	var matrix = _matrix.duplicate(true)
	var complexes: Array = []
	var check_positions: Array = []
	for y in range(rows):
		for x in range(cols):
			if matrix[y][x] == 1:
				var positions_vector: PoolVector2Array = []
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
	var middle_indexes: Array = []
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
	return matrix

func find_up_left_corners(matrix, rows, cols):
	var up_left_corners: Array
	for y in rows:
		for x in cols:
			if matrix[y][x] == 1:
				if matrix[y][x-1] == 0 and matrix[y-1][x] == 0:
					up_left_corners.push_back(Vector2(x,y))
	return up_left_corners


func find_down_right_corners(matrix, rows, cols, up_left_corners):
	for y in range(0,rows,-1):
		for x in range(0,cols,-1):
			if matrix[y][x] == 1:
				if x <= 0 or y <= 0:
					continue
				if get_cell(x,y-1) != TILE_TYPE.WALL and get_cell(x-1,y) != TILE_TYPE.WALL:
					up_left_corners.push_back(Vector2(x,y))

func swap_zeros_and_ones(matrix):
	for y in range(matrix.size()):
		for i in range(matrix[y].size()):
			var cell = matrix[y][i]
			if cell == 0:
				matrix[y][i] = 1
			if cell == 1:
				matrix[y][i] = 0
	return matrix



func _manage_structure_based_on_polygons():
	#################3var polygons_pool = _create_polygons()
	###################################_generate_collision_shape(polygons_pool)
	_generate_navigation_map()

func _create_polygons()-> Array:
	var polygons_pool: Array
	var rect = get_used_rect()
	var rows = rect.size.y
	var cols = rect.size.x
	var matrix = create_matrix(rows, cols)
	matrix = fill_matrix_inner_wall(matrix, get_used_cells_by_id(TILE_TYPE.WALL), rows, cols)
	var up_left_corners = find_up_left_corners(matrix, rows, cols)
	while !up_left_corners.empty():
		var current_tile = up_left_corners.pop_front()
		if matrix[current_tile.y][current_tile.x] != 1:
			continue
		var corners = []
		var last_direction = Vector2.RIGHT
		var pointer = (current_tile + rect.position) * TILESIZE
		var varibles = step(matrix, last_direction, current_tile, corners, pointer)
		while !varibles.empty():
			varibles = step(matrix, varibles.LastDirection, varibles.CurrentTile, corners, varibles.Pointer)
		corners.pop_back()
		polygons_pool.append(PoolVector2Array(corners))
	return polygons_pool

func _generate_collision_shape(polygons_pool:Array):
	var up_left_corners = []
	var rect = get_used_rect()
	var rows = rect.size.y
	var cols = rect.size.x
	var matrix = create_matrix(rows, cols)
	matrix = fill_matrix_outer_wall(matrix, get_used_cells_by_id(TILE_TYPE.WALL), cols, rows)
	matrix[0][0] = 0
	up_left_corners.push_back(Vector2(1,0))
	var current_tile = up_left_corners.pop_front()
	var corners = []
	var last_direction = Vector2.RIGHT
	var pointer = (current_tile + rect.position) * TILESIZE
	var varibles = step(matrix, last_direction, current_tile, corners, pointer)
	while !varibles.empty():
		varibles = step(matrix, varibles.LastDirection, varibles.CurrentTile, corners, varibles.Pointer)
	corners.pop_back()
	var poly = CollisionPolygon2D.new()
	poly.set_polygon(PoolVector2Array(corners))
	$StaticBody2D.add_child(poly)
	for polygon in polygons_pool:
		poly = CollisionPolygon2D.new()
		poly.set_polygon(polygon)
		$StaticBody2D.add_child(poly)

func fill_matrix_outer_wall(matrix, positions: Array, rows, cols):
	for pos in positions:
		if pos.x == 0 or pos.y == 0 or  pos.y == rows - 1 or  pos.x == cols - 1:
			matrix[pos.y][pos.x] = 1
	return matrix

func _generate_navigation_map_way1(polygons_pool):
	var navpoly = NavigationPolygon.new()
	var rect = get_used_rect()
	var x = rect.position.x
	var y = rect.end.x * TILESIZE
	var corners = PoolVector2Array([Vector2(x,x), Vector2(x,y), Vector2(y,y), Vector2(y,x)])
	#navpoly.set_vertices(corners)
	#var indices1 = PoolIntArray([0, 1, 2, 3])
	#navpoly.add_polygon(indices1)
	navpoly.add_outline(corners)
	navpoly.make_polygons_from_outlines()
	
	var vertices = PoolVector2Array([Vector2(10, 10), Vector2(10, 50), Vector2(50, 50), Vector2(50, 10)])
	print(vertices)
	navpoly.set_vertices(vertices)
	var indices = PoolIntArray([0, 1, 2, 3, ])
	navpoly.add_polygon(indices)

#	for polygon in polygons_pool:#range(0, polygons_pool.size()-1, -1):
#		navpoly.add_outline(polygon)
	$NavigationPolygonInstance.set_navigation_polygon(navpoly)

func remove_2(matrix):
	for j in range(matrix.size()):
		for i in range(matrix[j].size()):
			if matrix[j][i] == 2:
				matrix[j][i] = 0
	return matrix

func show_matrix(matrix):
	for row in matrix:
		var line = ""
		for c in row:
			line += str(c) + " "
		print(line)
	

func _generate_navigation_map():
	var navpoly = NavigationPolygon.new()
	var polygons_pool: Array
	var up_left_corners = []
	var rect = get_used_rect()
	var rows = rect.size.y
	var cols = rect.size.x
	var matrix = create_matrix(rows, cols)
	matrix = fill_matrix_wall(matrix, get_used_cells_by_id(TILE_TYPE.WALL))
	matrix = swap_zeros_and_ones(matrix)
	#show_matrix(matrix)
	up_left_corners = [Vector2(1,1)]
	var current_tile = up_left_corners.pop_front()
#	if matrix[current_tile.y][current_tile.x] != 1:
#		continue


	var corners = []
	var last_direction = Vector2.UP
	var pointer = (current_tile + rect.position) * TILESIZE
	####################3var varibles = extended_step(matrix, last_direction, current_tile, corners, pointer)
#	while !varibles.empty():
#		varibles = extended_step(matrix, varibles.LastDirection, varibles.CurrentTile, corners, varibles.Pointer)
#	corners.pop_back()
#	navpoly.add_outline(corners)
#	print("---------------------------------------------------------")
#	#matrix = swap_zeros_and_ones(matrix)
	matrix = create_matrix(rows, cols)
	matrix = fill_matrix_wall(matrix, get_used_cells_by_id(TILE_TYPE.WALL))
	var complex = look_for_complex_walls(matrix, rows, cols)
	complex.pop_front()
	print(complex)
	matrix = create_matrix(rows, cols)
	for row in complex:
		for pos in row:
			var x = pos.x
			var y = pos.y
			matrix[x][y] = 1
	show_matrix(matrix)
#	matrix[5][4] = 1
#	matrix[5][5] = 1
	#matrix[5][6] = 1
#
#	matrix[1][2] = 1
	#matrix[2][1] = 1
#	matrix[2][1] = 1

#	matrix[1][1] = 1
#	matrix[1][2] = 1
#	matrix[2][2] = 1
#
#	matrix[4][1] = 1
#	matrix[5][1] = 1
#	matrix[4][2] = 1
##
#	matrix[5][5] = 1
#	matrix[5][4] = 1
#	matrix[4][5] = 1
	
#	matrix[4][7] = 1
#	matrix[6][6] = 1
#	matrix[6][7] = 1
	up_left_corners = find_up_left_corners(matrix, rows, cols)
	print(up_left_corners)
	while !up_left_corners.empty():
		current_tile = up_left_corners.pop_front()
		print(matrix[current_tile.y][current_tile.x])
		if matrix[current_tile.y][current_tile.x] != 1:
			continue
		var pck = {
			"Matrix": matrix,
			"Vertices": [],
			"LastDirection": Vector2.RIGHT,
			"CurrentTile": current_tile,
			"Pointer": (current_tile + rect.position) * TILESIZE,
		}
		var is_complete = first_extended_step(pck, true, true)
		while !is_complete:
			is_complete = another_extended_step(pck, true, true)
		
#		varibles = extended_step(matrix, last_direction, current_tile, corners, pointer)
#		while !varibles.empty():
#			varibles = extended_step(matrix, varibles.LastDirection, varibles.CurrentTile, corners, varibles.Pointer)
		#pck..pop_back()
		print(pck.Vertices)
		print("--------")
		polygons_pool.append(PoolVector2Array(pck.Vertices))
	print(polygons_pool.size())
	
	for polygon in polygons_pool:#range(0, polygons_pool.size()-1, -1):
		navpoly.add_outline(polygon)
	navpoly.make_polygons_from_outlines()
	$NavigationPolygonInstance.set_navigation_polygon(navpoly)

const EXTENDED_SEQUENCE = [
		[TURN.LEFT],
		[TURN.FOWARD],
		[TURN.FOWARD, TURN.LEFT],
		[TURN.RIGHT],
		[TURN.RIGHT, TURN.LEFT],
		[TURN.BACKWARD],
		[TURN.BACKWARD, TURN.LEFT],
		[TURN.FULL, TURN.LEFT],
]
const EXTEND_MOVMENT = [
		[TURN.LEFT],
		[TURN.FOWARD],
		[TURN.FOWARD, TURN.LEFT],
		[TURN.RIGHT],
		[TURN.RIGHT, TURN.LEFT],
		[TURN.BACKWARD],
		[TURN.BACKWARD, TURN.LEFT],
		[TURN.LEFT, TURN.LEFT],
]
const POLYGON_MARGIN = Vector2(10,10)
const NUMBER_OF_MOVES = {
	TURN.LEFT: 0,
	TURN.FOWARD: 1,
	TURN.RIGHT: 2, 
	TURN.BACKWARD: 3, 
	TURN.FULL: 4, 
}

func next_tile(matrix, last_direction, current_tile, include_diagonals):
	for steps in EXTEND_MOVMENT:
		if include_diagonals == false:
			if steps.size() != 1:
				continue
		var second_direction = Vector2.ZERO
		var first_direction = _turn(last_direction, steps[0])
		if steps.size() == 2:
			second_direction = _turn(first_direction, steps[1])
		var direction = first_direction + second_direction
		var middle_tile = current_tile + first_direction
		var new_tile = current_tile + direction
		if new_tile.y >= 0 and new_tile.y < len(matrix) and \
				new_tile.x >= 0 and new_tile.x < len(matrix[0]) and \
				matrix[new_tile.y][new_tile.x] != 0:
			if steps == [TURN.LEFT, TURN.LEFT]:
				steps = [TURN.FULL, TURN.LEFT]
			var move_date = {
				"Steps": steps,
				"FirstDirection": first_direction,
				"SecondDirection": second_direction,
				"MiddleTile": middle_tile,
				"FinalTile": new_tile,
			}
			return move_date

func extended_step(pck, include_diagonals, use_margin) -> bool:
	var move_data = next_tile(pck.Matrix, pck.LastDirection, pck.CurrentTile, include_diagonals)
	if move_data == null:
		return true
	var steps = move_data.Steps
	var second_direction = move_data.SecondDirection
	var new_tile = move_data.FinalTile
	var middle_tile = move_data.MiddleTile
	var first_direction = move_data.FirstDirection
	for i in range(steps.size()):
		var ref_tile = pck.CurrentTile
		if i == 0:
			ref_tile = pck.CurrentTile
			#pck.LastDirection = first_direction
		elif i == 1:
			ref_tile = middle_tile
			pck.LastDirection = first_direction
		var is_compleated = extended_go(pck, ref_tile, use_margin, steps[i])
		if is_compleated == true:
			return true
	if second_direction != Vector2.ZERO:
		pck.LastDirection = second_direction
	else:
		pck.LastDirection = first_direction
#			pck.PreviousTile = pck.CurrentTile
	pck.CurrentTile = new_tile
	return false

func another_extended_step(pck, include_diagonals, use_margin) -> bool:
	pck.Matrix[pck.CurrentTile.y][pck.CurrentTile.x] = 2
	if extended_step(pck, include_diagonals, use_margin):
		return true
#	if pck.PreviousTile == pck.FirstTile and \
#			!is_first_time:
#		return true
	#if pck.Matrix[pck.CurrentTile.y][pck.CurrentTile.x] != 3:
	return false

func first_extended_step(pck, include_diagonals, use_margin) -> bool:
#	var pointer = pck.Pointer
#	var margin_direction = Vector2.ZERO
#	if use_margin:
#		margin_direction = Vector2(-1, -1)
#	pck.Vertices.push_back(pointer + POLYGON_MARGIN * margin_direction)
	pck.Matrix[pck.CurrentTile.y][pck.CurrentTile.x] = 3
	if extended_step(pck, include_diagonals, use_margin):
		extended_go(pck, pck.CurrentTile, use_margin, TURN.FULL)
		extended_go(pck, pck.CurrentTile, use_margin, TURN.LEFT)
		return true
	return false

func push_vertices(pck, mid_point, use_margin, turn):
	var margin_direction = Vector2.ZERO
	if use_margin:
		margin_direction = Vector2(sign(pck.Pointer.x - mid_point.x), sign(pck.Pointer.y - mid_point.y))
	if pck.Vertices.empty() != true and pck.Vertices.front() == pck.Pointer + POLYGON_MARGIN * margin_direction:
		return true
	pck.Vertices.push_back(pck.Pointer + POLYGON_MARGIN * margin_direction)
	return false
	

func extended_go(pck, ref_tile, use_margin, turn):
	var pointer = pck.Pointer
	var mid_point = map_to_world(ref_tile) + Vector2(TILESIZE * 0.5, TILESIZE * 0.5)
	var margin_direction = Vector2.ZERO
	var is_compleated = false
	
	if turn == TURN.LEFT:
		is_compleated = push_vertices(pck, mid_point, use_margin, turn)
		if is_compleated:
			return true

	if turn == TURN.FOWARD:
		pck.Pointer = pck.Pointer + _turn(pck.LastDirection, TURN.FOWARD) * TILESIZE
	
	if turn == TURN.RIGHT:
		pck.Pointer = pck.Pointer + _turn(pck.LastDirection, TURN.FOWARD) * TILESIZE
		is_compleated = push_vertices(pck, mid_point, use_margin, turn)
		if is_compleated:
			return true
		pck.Pointer = pck.Pointer + _turn(pck.LastDirection, TURN.RIGHT) * TILESIZE
	
	if turn == TURN.BACKWARD:
		pck.Pointer = pck.Pointer + _turn(pck.LastDirection, TURN.FOWARD) * TILESIZE
		is_compleated = push_vertices(pck, mid_point, use_margin, turn)
		if is_compleated:
			return true
		pck.Pointer = pck.Pointer + _turn(pck.LastDirection, TURN.RIGHT) * TILESIZE
		is_compleated = push_vertices(pck, mid_point, use_margin, turn)
		if is_compleated:
			return true
		pck.Pointer = pck.Pointer + _turn(pck.LastDirection, TURN.BACKWARD) * TILESIZE
	
	if turn == TURN.FULL:
		pck.Pointer = pck.Pointer + _turn(pck.LastDirection, TURN.FOWARD) * TILESIZE
		is_compleated = push_vertices(pck, mid_point, use_margin, turn)
		if is_compleated:
			return true
		pck.Pointer = pck.Pointer + _turn(pck.LastDirection, TURN.RIGHT) * TILESIZE
		is_compleated = push_vertices(pck, mid_point, use_margin, turn)
		if is_compleated:
			return true
		pck.Pointer = pck.Pointer + _turn(pck.LastDirection, TURN.BACKWARD) * TILESIZE
		is_compleated = push_vertices(pck, mid_point, use_margin, turn)
		if is_compleated:
			return true
		pck.Pointer = pck.Pointer + _turn(pck.LastDirection, TURN.LEFT) * TILESIZE
	if is_compleated:
		return true
	return false



func extended_go1(steps, last_direction, corners, pointer, current_field):
	var middle_cell = map_to_world(current_field) - Vector2(-TILESIZE * 0.5, TILESIZE * 0.5)
	var margin_direction = Vector2.ZERO
	if steps == 0:
		#print(middle_cell)
		margin_direction = Vector2(sign(pointer.x - middle_cell.x), sign(pointer.y - middle_cell.y))
		#print(margin_direction)
		corners.push_back(pointer + POLYGON_MARGIN * margin_direction)# + Vector2(5, 5))
		return pointer
	pointer = pointer + _turn(last_direction, SEQUENCE[1]) * TILESIZE
	steps -=1
	for move in steps:
		margin_direction = Vector2(sign(pointer.x - middle_cell.x), sign(pointer.y - middle_cell.y))
		corners.push_back(pointer + POLYGON_MARGIN * margin_direction)
		pointer = pointer + _turn(last_direction, SEQUENCE[(move+2)%4]) * TILESIZE
	return pointer

func extended_step1(map, last_direction, current_field, corners, pointer):
	map[current_field.y][current_field.x] = 2
	if len(corners) >= 2 and corners[0] == corners[-1]:
		return []
	elif len(corners) >= 3 and corners[0] == corners[-2]:
		corners.pop_back()
		return []
	for steps in EXTENDED_SEQUENCE:
		var new_direction = Vector2.ZERO
		var a = Vector2(0, 0)
		var old_dir
		for step in steps:
			old_dir = a
			new_direction = _turn(last_direction, step)
			a = a + new_direction
		var check_field = current_field + new_direction
		var new_field = current_field + a
		var middle_field = current_field + old_dir
		if new_field.y >= 0 and new_field.y < len(map)\
				and new_field.x >= 0 and new_field.x < len(map[0])\
				and map[new_field.y][new_field.x] >= 1\
		:
			for step in steps:
				var move = NUMBER_OF_MOVES[step]
				var find_field
				if steps.size() == 2:
					find_field = middle_field
				else:
					find_field = current_field
				pointer = extended_go1(move, last_direction, corners, pointer, find_field)
			return {
				"LastDirection": new_direction,
				"CurrentTile": new_field,
				"Pointer": pointer
			}
	_go(4, last_direction, corners, pointer)
	corners.push_back(pointer)
	corners.push_back(pointer)
	return []







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
		set_cellv(tile_pos, 2)
		remove_avilable_places_until_wall(tile_pos, available_spots, INF)
		remove_avilable_places_in_range(tile_pos, available_spots)
