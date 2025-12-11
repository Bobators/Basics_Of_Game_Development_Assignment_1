extends Node2D

@export var main_scene_path: String = "res://scene/mainscene.tscn"

@onready var main_menu_panel: Control = $CenterContainer/Mainbuttons

@onready var settings_menu_panel: Control = $CenterContainer/settingsmenu

@onready var credits_menu_panel: Control = $CenterContainer/creditsmenu


func _ready():
	_show_menu_panel(main_menu_panel)

func _show_menu_panel(target_panel: Control):
	main_menu_panel.hide()
	settings_menu_panel.hide()
	credits_menu_panel.hide()
	
	target_panel.show()

func _on_play_button_pressed():
	get_tree().paused = false 
	
	var error = get_tree().change_scene_to_file(main_scene_path)

func _on_settings_button_pressed():
	_show_menu_panel(settings_menu_panel)

func _on_credits_button_pressed():
	_show_menu_panel(credits_menu_panel)

func _on_quit_button_pressed():
	get_tree().quit()


func _on_settings_back_button_pressed():
	_show_menu_panel(main_menu_panel)

func _on_credits_back_button_pressed():
	_show_menu_panel(main_menu_panel)
