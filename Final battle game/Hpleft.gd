extends Control

@onready var hp_bar: TextureProgressBar = $MarginContainer/HBoxContainer/TextureProgressBar
@export var victory_manager_node: Node = null
@export var target_player: Node = null  

var max_hp := 100.0
var game_over: bool = false

func _ready():
	await get_tree().process_frame
	if target_player.has_method("get_max_health"):
		max_hp = target_player.get_max_health()
	elif target_player.has_meta("MAX_HEALTH"):
		max_hp = target_player.get_meta("MAX_HEALTH")
	elif "MAX_HEALTH" in target_player:
		max_hp = target_player.MAX_HEALTH
	else:
		max_hp = 100.0
	
	hp_bar.max_value = max_hp
	hp_bar.value = max_hp

func _process(_delta):
	if game_over or target_player == null or hp_bar == null:
		return
		
	var cur_hp = target_player.current_health if "current_health" in target_player else 0
	hp_bar.value = cur_hp
	
	if cur_hp <= 0:
		game_over = true
		
		if victory_manager_node.has_method("announce_winner"):
			victory_manager_node.announce_winner("Fire Knight")
