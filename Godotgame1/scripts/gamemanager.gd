extends Node

var score = 0

@onready var scorelabel: Label = $scorelabel

func add_point() -> void:
	score +=1
	scorelabel.text = "You collected "+ str(score) + " coins!"

	
