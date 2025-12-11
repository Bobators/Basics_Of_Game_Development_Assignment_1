extends Label

@onready var victory_container: Control = get_parent()

@export var restart_button: Button

func _ready():
	victory_container.hide()

func announce_winner(winner_name: String):
	victory_container.show()
	self.text = winner_name + " wins!"
	
	if restart_button:
		restart_button.show()
		
func _on_restart_button_pressed():
	var error = get_tree().reload_current_scene()
