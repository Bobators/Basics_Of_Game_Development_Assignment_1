extends CharacterBody2D

@export var speed: float = 400.0

func _physics_process(delta: float):
	velocity.y = 0
	if Input.is_action_pressed("ui_up"):
		velocity.y -= speed
	if Input.is_action_pressed("ui_down"):
		velocity.y += speed
	move_and_slide()

func _on_area_2d_area_entered(area):
	if area.get_parent() is RigidBody2D:
		var ball = area.get_parent()
		var normal = (ball.global_position - global_position).normalized()
		ball.linear_velocity = ball.linear_velocity.bounce(normal).normalized() * 300.0
