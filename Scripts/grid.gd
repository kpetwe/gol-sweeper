extends TileMapLayer

class_name Board 

# Sprite map
const CELLS = {
	"1": Vector2i(0, 0),
	"2": Vector2i(1, 0),
	"3": Vector2i(2, 0),
	"4": Vector2i(3, 0),
	"5": Vector2i(4, 0),
	"6": Vector2i(0, 1),
	"7": Vector2i(1, 1),
	"8": Vector2i(2, 1),
	"0": Vector2i(3, 1),
	"RM": Vector2i(4, 1),
	"F": Vector2i(0,2),
	"M": Vector2i(1,2),
	"B": Vector2i(2,2)
}

# source color on sprite map
const TILE_SET_ID = 1

# Board specs
@export var rows = 8
@export var cols = 8
@export var mines = 10

"""
	Game of Life Update Maps
	DEAD = Safe tiles
	ALIVE = Mine tiles
	Index = # neighboring mine tiles
	Value = 0 if dead, 1 if alive at next stage
"""
@export var GOL_DEAD = [0, 0, 0, 1, 0, 0, 0, 0, 0]
@export var GOL_ALIVE = [0, 0, 1, 1, 0, 0, 0, 0, 0]
@export var gol_on = false

@export var view_mines = false


# Tracks cells in the game using hashing
var flagged_cells = {}
var checked_cells = {}
var mine_cells = {}
#var minesleft = mines

var game_over = false

# initialize scene
func _ready():
	assert(mines < rows * cols && mines > 0 && rows > 0 && cols > 0)
	clear()
	init_board()
	init_mines()

# draws a blank board
func init_board():
	for i in rows:
		for j in cols:
			set_tile_cell(Vector2i(i - rows/2, j-cols/2), "B")

# saves initial mines in a set
func init_mines():
	while mine_cells.size() < mines:
		var cell = Vector2i(randi_range(-rows/2, rows/2-1), randi_range(-cols/2, cols/2-1))
		mine_cells[cell] = null	
	if (view_mines):
		for mine in mine_cells:
			erase_cell(mine)
			set_tile_cell(mine, "M")
	
# act when grid is clicked
func _input(event: InputEvent):
	# can change to shade darker when hovering perhaps
	if event is not InputEventMouseButton || !event.pressed:
		return
		
	# turns mouse click into integer/grid coords
	var cell = local_to_map(get_local_mouse_position())
	
	if !in_bounds(cell) || game_over:
		return 

	if event.button_index == 1:
		grid_update(cell)
	elif event.button_index == 2:
		flag_update(cell)
	
	print(cell)

# Display flag on board
func flag_update(cell: Vector2i):
	if flagged_cells.has(cell):
		erase_cell(cell)
		set_tile_cell(cell, "B")
		flagged_cells.erase(cell)
	elif flagged_cells.size() < mines:
		erase_cell(cell)
		set_tile_cell(cell, "F")
		flagged_cells[cell] = null
	elif flagged_cells.size() >= mines:
		print("OUT OF FLAGS")	


# update grid display
func grid_update(cell: Vector2i):
	# Unsafe tile hit
	if mine_cells.has(cell):
		print("GAME LOST")
		game_over = true
		reveal_mines()
		set_tile_cell(cell, "RM")
	
	# Safe tile hit
	elif !checked_cells.has(cell):
		cell_update(cell)
		
		# GAME OF LIFE UPDATE
		if gol_on:
			gol_update()
	
	# All safe tiles revealed
	#TODO: Make variable that decrements to 0
	if checked_cells.size() >= (rows*cols - mines):
		print("GAME WON")
		game_over = true
		reveal_mines()
		
# reveal mines at the end of the game
func reveal_mines():
	for cell in mine_cells:
		erase_cell(cell)
		set_tile_cell(cell, "M")

# recursively reveal all neighboring safe tiles
func cell_update(cell: Vector2i):
	if !in_bounds(cell) || checked_cells.has(cell):
		return
	
	var mc = count_mines(cell)
	
	# casts integer to string for numbered tiles
	set_tile_cell(cell, "%d" % mc)
	# add revealed tile to list
	checked_cells[cell] = null

	# add neighboring safe tiles to list
	if mc == 0:
		for i in range(-1, 2):
			for j in range(-1, 2):
				if (i != 0 || j != 0):
					cell_update(cell + Vector2i(i, j))
	return
	
# perform game of life updates on the board grid
# there is a shorter way to write this function but
# custom rules require checking the whole board
func gol_update():
	var new_mine_cells = {}
	
	# loops through grid an updates mines
	for i in rows:
		for j in cols:
			var cell = Vector2i(i - rows/2, j-cols/2)
			var mc = count_mines(cell)
			var res
			if mine_cells.has(cell):
				res = GOL_ALIVE[mc]
			else:
				res = GOL_DEAD[mc]
			if res:
				new_mine_cells[cell] = null
					
	
	# View GOL Updates
	if(view_mines):
		for mine in new_mine_cells:
			if(!mine_cells.has(mine)):
				erase_cell(mine)
				set_tile_cell(mine, "M")
		for mine in mine_cells:
			if(!new_mine_cells.has(mine)):
				erase_cell(mine)
				set_tile_cell(mine, "B")
	
	mine_cells = new_mine_cells
	mines = mine_cells.size()
	
	# Update visible cells
	for cell in checked_cells:
		erase_cell(cell)
		if mine_cells.has(cell):
			set_tile_cell(cell, "M")
		else:
			var mc = count_mines(cell)
			set_tile_cell(cell, "%d" % mc)
	

# counts the number of mines in the neighborhood
func count_mines(cell: Vector2i):
	var mc = 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			if (i!= 0 || j !=0) && mine_cells.has(cell + Vector2i(i, j)):
				mc += 1
	return mc

# Sets tile display
func set_tile_cell(cell:Vector2i, type): set_cell(cell, TILE_SET_ID, CELLS[type])

# Check if cell is on the grid
func in_bounds(cell: Vector2i):
	if (cell.x >= -rows/2 && cell.x <= rows/2 -1):
		if (cell.y >= -cols/2 && cell.y <= cols/2 - 1):
			return true
	return false
