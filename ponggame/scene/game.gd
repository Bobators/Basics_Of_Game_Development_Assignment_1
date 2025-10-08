extends Node2D

@onready var ball = $Ball  
@onready var player_score_label = $playerLabel
@onready var ai_score_label = $aiLabel

var player_score: int = 0
var ai_score: int = 0

func _ready():
	reset_ball()

func reset_ball():
	ball.global_position = Vector2(0,0)  
	ball.linear_velocity = Vector2.ZERO
	# 延迟 1 秒后启动（可选）
	await get_tree().create_timer(1.0).timeout
	var direction = Vector2(1 if randi() % 2 == 0 else -1, randf() * 0.5 - 0.25).normalized()
	ball.linear_velocity = direction * ball.initial_speed

func _on_left_goal_body_entered(body):
	if body.is_in_group("ball"):
		ai_score += 1
		ai_score_label.text = str(ai_score)
		reset_ball()

func _on_right_goal_body_entered(body):
	if body.is_in_group("ball"):
		player_score += 1
		player_score_label.text = str(player_score)
		reset_ball()
