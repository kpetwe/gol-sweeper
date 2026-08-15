extends Node

@export var option_screen: MarginContainer
@export var board: Board
@export var page1: MarginContainer
@export var page2: ColorRect
@export var numberbutton: Button


signal newgame
var change = false

func _ready():
	board.trigger_reset.connect(set_change)
	newgame.connect(board.reset)

func set_default():
	get_tree().reload_current_scene()

func quit_pressed():
	get_tree().quit()

func toggle_visibility(object):
	object.visible = !object.visible
		

func options_pressed():
	if option_screen.visible && change:
		change = false
		newgame.emit()
	toggle_visibility(option_screen)
	toggle_visibility(board)
	
	if board.visible:
		page1.visible = false
		page2.visible = false
		numberbutton.visible = false
	else:
		numberbutton.visible = true
		numberbutton.text = "2/2"
		page2.visible = true
		page1.visible = false
	
func set_change():
	change = true
	
func next_pressed():
	toggle_visibility(page1)
	toggle_visibility(page2)
	if page1.is_visible_in_tree():
		numberbutton.text = "1/2"
	else:
		numberbutton.text ="2/2"
