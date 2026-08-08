extends Node

@export var option_screen: MarginContainer

func quit_pressed():
	get_tree().quit()

func toggle_visibility(object):
	object.visible = !object.visible

func options_pressed():
	toggle_visibility(option_screen)
