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

var game_over = false

"""
	Initializes Scene
"""
func _ready():
	assert(mines < rows * cols && mines >= 0 && rows > 0 && 
		cols > 0 && rows <= 30 && cols <= 24 && mines < 667)
	clear()
	init_board()
	init_mines()

"""
	Button Signals
"""

func reset():
	game_over = false
	flagged_cells = {}
	checked_cells = {}
	mine_cells = {}
	_ready()
	
signal trigger_reset

func set_gol(toggle:bool):
	gol_on = toggle
	
func set_view_mines(toggle:bool):
	view_mines = toggle
	trigger_reset.emit()
	
func set_rows(r):
	trigger_reset.emit()
	rows = int(r)

func set_cols(c):
	trigger_reset.emit()
	cols = int(c)

func set_mines(m):
	trigger_reset.emit()
	mines = int(m)

	

"""
	Draws a blank board
"""
func init_board():
	print(rows, " ", cols)
	for i in rows:
		for j in cols:
			set_tile_cell(Vector2i(i - rows/2, j-cols/2), "B")

"""
	Stores addresses of initial mines
"""
func init_mines():
	while mine_cells.size() < mines:
		var cell = Vector2i(randi_range(-rows/2, rows/2-1 + rows % 2), 
			randi_range(-cols/2, cols/2-1 + cols % 2))
		mine_cells[cell] = null	
	if (view_mines):
		for mine in mine_cells:
			erase_cell(mine)
			set_tile_cell(mine, "M")
	
"""
	Handle mouse interaction with screen
	@param InputEvent event: event to handle
"""
func _input(event: InputEvent):
	# can change to shade darker when hovering perhaps
	if event is not InputEventMouseButton || !event.pressed || !self.visible:
		return
		
	# turns mouse click into integer/grid coords
	var cell = local_to_map(get_local_mouse_position())
	
	if !in_bounds(cell) || game_over:
		return 

	if event.button_index == 1:
		grid_update(cell, true)
	elif event.button_index == 2:
		flag_update(cell)
	
	print(cell)

"""
	Updates flag on board
	@param Vector2i cell: Cell to add or remove a flag from
"""
func flag_update(cell: Vector2i):
	if (checked_cells.has(cell)):
		return
	if flagged_cells.has(cell):
		erase_cell(cell)
		set_tile_cell(cell, "B")
		flagged_cells.erase(cell)
	elif flagged_cells.size() < mine_cells.size():
		erase_cell(cell)
		set_tile_cell(cell, "F")
		flagged_cells[cell] = null
	elif flagged_cells.size() >= mine_cells.size():
		print("OUT OF FLAGS")	


"""
	Updates Grid display
	@param Vector2i cell: Location of cell that was clicked
	@param bool safe: True if it's safe to perform GOL update 
"""
func grid_update(cell: Vector2i, safe: bool):
	# Unsafe tile hit
	if mine_cells.has(cell):
		print("GAME LOST")
		game_over = true
		reveal_mines()
		set_tile_cell(cell, "RM")
		return
	
	# Reveal neighboring tiles if enough flags placed
	elif checked_cells.has(cell):
		safe = neighbor_update(cell)
	
	# Safe tile hit
	elif !checked_cells.has(cell):
		cell_update(cell)
		
	# Evolves board at end of move
	if gol_on && safe:
		gol_update()
	
	# All safe tiles revealed
	if game_won():
		print("GAME WON")
		game_over = true
		reveal_mines()

"""
	Check if the game is won
"""
func game_won():
	var safe_tiles = (rows*cols - mine_cells.size())
	var known_safe = checked_cells.size()
	if (gol_on):
		# Prevents game for ending early if a dead cells
		# comes to life
		for mine in mine_cells:
			if checked_cells.has(mine):
				known_safe -= 1
	
	return known_safe >= safe_tiles
		
"""
	Display location of mines
"""
func reveal_mines():
	for cell in mine_cells:
		erase_cell(cell)
		set_tile_cell(cell, "M")

"""
	If enough flags have been put down, reveal neighboring
	tiles.
	@param Vector2i cell: Location of cell that was clicked
	@return bool: true if it is safe to perform GOL update
"""
func neighbor_update(cell: Vector2i):
	var mc = count_mines(cell)
	var fc = 0
	var safe = false
	
	# Check that there's a matching number of flags
	for i in range(-1, 2):
		for j in range(-1, 2):
			if flagged_cells.has(Vector2i(i, j) + cell):
				fc += 1
	if mc == fc:
		# Update hidden cells
		for i in range(-1, 2):
			for j in range(-1, 2):
				var tc = Vector2i(i, j) + cell
				# prevent infinite loop and revealing a mine tile as "safe"
				if !checked_cells.has(tc) && !flagged_cells.has(tc):
					grid_update(tc, false)
					safe = true
	return safe
	

"""
	Recursively reveals safe tiles
	@param Vector2i cell: location of cell we're revealing
"""
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

"""
	Perform game of life updates on the board grid
"""	
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
	
	# Update visible cells
	for cell in checked_cells:
		erase_cell(cell)
		if mine_cells.has(cell):
			set_tile_cell(cell, "M")
		else:
			var mc = count_mines(cell)
			set_tile_cell(cell, "%d" % mc)
	

"""
	Counts the number of neighboring mines
	@param Vector2i cell: location of cell we're checking
	@return int: number of mines
"""
func count_mines(cell: Vector2i):
	var mc = 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			if (i!= 0 || j !=0) && mine_cells.has(cell + Vector2i(i, j)):
				mc += 1
	return mc

# Sets tile display
func set_tile_cell(cell:Vector2i, type): 
	set_cell(cell, TILE_SET_ID, CELLS[type])

# Check if cell is on the grid
func in_bounds(cell: Vector2i):
	if (cell.x >= -rows/2 && cell.x <= rows/2 -1 + rows % 2):
		if (cell.y >= -cols/2 && cell.y <= cols/2 - 1 + cols % 2):
			return true
	return false
