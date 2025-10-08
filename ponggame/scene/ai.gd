extends CharacterBody2D

@export var speed: float = 300.0  # AI 速度稍慢于玩家，增加难度平衡
var ball: Node = null

func _physics_process(delta: float):
	if ball == null:
		ball = get_tree().get_first_node_in_group("ball")  # 查找球（稍后添加组）
	if ball:
			var target_y = ball.global_position.y
			if global_position.y < target_y - 10:
				velocity.y = speed
			elif global_position.y > target_y + 10:
				velocity.y = -speed
			else:
				velocity.y = 0
	move_and_slide()
	
func _on_area_2d_area_entered(area):
	if area.get_parent() is RigidBody2D:
		var ball = area.get_parent()
		var normal = (ball.global_position - global_position).normalized()
		ball.linear_velocity = ball.linear_velocity.bounce(normal).normalized() * 300.0
