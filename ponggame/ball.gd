extends RigidBody2D

@export var initial_speed: float = 350.0

func _ready():
	var direction = Vector2(1 if randi() % 2 == 0 else -1, randf() * 0.5 - 0.25).normalized()
	linear_velocity = direction * initial_speed
