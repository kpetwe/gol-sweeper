extends Node

@export var option_screen: MarginContainer
@export var board: Board


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
	
func set_change():
	print("yes")
	change = true
