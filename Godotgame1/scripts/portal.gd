extends Area2D

@export var target_portal: NodePath
@export var teleport_cooldown: float = 2
@export var teleport_offset: Vector2 = Vector2(20, 0) 

var _can_teleport: bool = true
var _timer: Timer

func _ready():
	body_entered.connect(_on_body_entered)
	_timer = Timer.new()
	_timer.wait_time = teleport_cooldown
	_timer.one_shot = true
	_timer.timeout.connect(_on_cooldown_timeout)
	add_child(_timer)

func _on_body_entered(body: Node):
	if body.is_in_group("Player") and _can_teleport:
		var target = get_node_or_null(target_portal)
		if target:
			body.global_position = target.global_position + teleport_offset
			_can_teleport = false
			_timer.start()

func _on_cooldown_timeout():
	_can_teleport = true
