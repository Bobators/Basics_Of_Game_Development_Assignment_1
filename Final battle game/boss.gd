extends CharacterBody2D
class_name BossPlayer

#Core Attributes
const MAX_HEALTH = 150
var current_health = MAX_HEALTH
const KNOCKBACK_FORCE = 300.0 
var knockback_dir = Vector2.ZERO
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const ROLL_SPEED = 300.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum State { IDLE, RUN, JUMP, FALL, ROLL, ATTACK, AIR_ATTACK, SP_ATTACK, DEFEND, HURT, DEATH }
var current_state = State.IDLE

var combo_count = 0 
var can_combo = false 
var is_active_state = false 

@onready var anim = $AnimatedSprite2D
@onready var hitbox_area = $Hitbox 
@onready var hitbox_col = $Hitbox/CollisionShape2D 
@onready var hitbox_shape = hitbox_col.shape as RectangleShape2D 
@onready var default_hitbox_size = hitbox_shape.size 

func _ready():
	hitbox_col.disabled = true
	is_active_state = current_state in [State.ROLL, State.ATTACK, State.AIR_ATTACK, State.SP_ATTACK, State.DEFEND, State.HURT]
	self.name = "BossPlayer" 

func _physics_process(delta):
	if current_state == State.DEATH:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
		if velocity.y > 0 and not is_active_state:
			set_state(State.FALL)
	
	#Status Distribution
	match current_state:
		State.IDLE, State.RUN, State.JUMP, State.FALL:
			handle_move_input()
			handle_action_input()
		State.ROLL:
			handle_roll_logic()
		State.ATTACK, State.AIR_ATTACK, State.SP_ATTACK:
			handle_attack_logic()
		State.DEFEND:
			velocity.x = 0
			if Input.is_action_just_released("ui_down"): 
				set_state(State.IDLE)
		State.HURT:
			# When hit, horizontal velocity decays
			velocity.x = move_toward(velocity.x, 0, 1000.0 * delta)

	move_and_slide()
	update_animation()
	
	# Real-Time Attack Detection Management
	manage_hitbox_active_frames()

#State Switching and Lock Management
func set_state(new_state: State):
	if current_state == new_state:
		return

	if current_state != State.ATTACK:
		can_combo = false
		combo_count = 0
		
	current_state = new_state
	is_active_state = new_state in [State.ROLL, State.ATTACK, State.AIR_ATTACK, State.SP_ATTACK, State.DEFEND, State.HURT]
	
	if not is_active_state:
		hitbox_col.disabled = true
		

func handle_move_input():
	if is_active_state: return 
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		if is_on_floor(): set_state(State.RUN)
		if direction < 0:
			anim.flip_h = true
			hitbox_area.scale.x = 1
		else:
			anim.flip_h = false
			hitbox_area.scale.x = -1
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor(): set_state(State.IDLE)

	if Input.is_action_just_pressed("ui_up") and is_on_floor(): 
		velocity.y = JUMP_VELOCITY
		set_state(State.JUMP)

func handle_action_input():
	if is_active_state and current_state != State.ATTACK: return

	# Attack Input
	if Input.is_action_just_pressed("ui_accept"): 
		if current_state == State.ATTACK and can_combo: 
			pass 
		elif is_on_floor():
			start_attack(1)
			return
		elif not is_on_floor():
			start_air_attack()
			return

	if Input.is_action_just_pressed("sp_attack") and is_on_floor(): 
		start_special_attack()
		return

	if Input.is_action_just_pressed("roll") and is_on_floor(): 
		start_roll()
		return

	if Input.is_action_pressed("ui_down") and is_on_floor(): 
		set_state(State.DEFEND)
		anim.play("defend")

#Attack/Action
func start_attack(combo_stage):
	set_state(State.ATTACK)
	hitbox_area.position = Vector2(0, 0)
	combo_count = combo_stage
	velocity.x = 0 
	
	var anim_name = "atk_1"
	if combo_count == 2:
		anim_name = "atk_2"
	elif combo_count == 3:
		anim_name = "atk_3"

	anim.play(anim_name)

func start_air_attack():
	set_state(State.AIR_ATTACK)
	velocity.x = 0
	anim.play("air_atk")

func start_special_attack():
	set_state(State.SP_ATTACK)
	velocity.x = 0
	anim.play("sp_atk")

func start_roll():
	set_state(State.ROLL)
	anim.play("roll")
	var dir = -1 if anim.flip_h else 1
	velocity.x = dir * ROLL_SPEED

func handle_roll_logic():
	pass 

func handle_attack_logic():
	velocity.x = move_toward(velocity.x, 0, 10.0)
	
	# Combo Detection
	if current_state == State.ATTACK and Input.is_action_just_pressed("ui_accept") and can_combo:
		if combo_count == 1:
			start_attack(2)
		elif combo_count == 2:
			start_attack(3)

#Animation Logic-
func update_animation():
	if is_active_state: return 
	
	if is_on_floor():
		if velocity.x != 0:
			anim.play("run")
		else:
			anim.play("idle")
	else:
		if velocity.y < 0:
			anim.play("jump_up") 
		else:
			anim.play("jump_down") 

func return_to_idle():
	if is_on_floor():
		set_state(State.IDLE)
	else:
		set_state(State.FALL)

func _on_animated_sprite_2d_animation_finished():
	var finished_state = current_state
	
	if finished_state == State.DEATH:
		queue_free()
		return

	if finished_state == State.ROLL or finished_state == State.AIR_ATTACK or finished_state == State.SP_ATTACK:
		return_to_idle()
		
	elif finished_state == State.ATTACK:
		if combo_count == 3:
			return_to_idle()
		elif not can_combo:
			return_to_idle()
		else:
			get_tree().create_timer(0.1).timeout.connect(reset_after_combo_window, CONNECT_ONE_SHOT)

func reset_after_combo_window():
	if current_state == State.ATTACK:
		return_to_idle()

#Manual Hitbox Frame Control
func manage_hitbox_active_frames():
	if not is_active_state or current_state in [State.ROLL, State.DEFEND, State.HURT, State.DEATH]:
		hitbox_col.disabled = true
		can_combo = false 
		return
		
	var ani = anim.animation
	var frame = anim.frame
	var dir_x = 1 if not anim.flip_h else -1
	
	hitbox_shape.size = default_hitbox_size
	hitbox_area.position = Vector2(0, 0)
	hitbox_col.disabled = true 
	can_combo = false 

	
	if ani == "atk_1":
		if frame >= 4 and frame <= 8:
			hitbox_col.disabled = false
			hitbox_shape.size = Vector2(40, 60)
			hitbox_area.position = Vector2(dir_x * 15 , 0) 

		if frame >= 6 and frame <= 10:
			can_combo = true 

	elif ani == "atk_2":
		if frame >= 3 and frame <= 9:
			hitbox_col.disabled = false
			hitbox_shape.size = Vector2(80, 70) 
			hitbox_area.position = Vector2(dir_x * 10, 0) 

		if frame >= 7 and frame <= 11:
			can_combo = true

	elif ani == "atk_3":
		if frame >= 4 and frame <= 9:
			hitbox_col.disabled = false
			hitbox_shape.size = Vector2(70, 80) 
			hitbox_area.position = Vector2(dir_x * 30, -25)
		
	elif ani == "air_atk":
		if frame >= 3 and frame <= 6:
			hitbox_col.disabled = false
			hitbox_shape.size = Vector2(100, 50) 
			hitbox_area.position = Vector2(dir_x * 20, 0) 

	elif ani == "sp_atk":
		if frame >= 12 and frame <= 15:
			hitbox_col.disabled = false
			hitbox_shape.size = Vector2(120, 150) 
			hitbox_area.position = Vector2(dir_x * 20, -20) 

# Hitbox Hurtbox
func _on_hitbox_area_entered(area):
	if area.name == "Hurtbox":
		var enemy = area.get_parent()
		if enemy != self and enemy.has_method("take_hit"):
			var damage = 10
			
			if current_state == State.ATTACK:
				if combo_count == 2: damage = 15
				if combo_count == 3: damage = 25
			elif current_state == State.AIR_ATTACK:
				damage = 15
			elif current_state == State.SP_ATTACK:
				damage = 50 
				
			var knockback_direction = (enemy.global_position - global_position).normalized()
			enemy.take_hit(damage, knockback_direction)
			
			hitbox_col.disabled = true
			
func take_hit(damage: int, knockback_direction: Vector2):
	if current_state == State.DEATH or current_state == State.HURT or current_state == State.ROLL:
		return

	if current_state == State.DEFEND:
		print(self.name, "Blocked, taking chip damage!")
		
		damage = 5
		
		current_health -= damage
		print(self.name, " took chip damage: ", damage, ". Remaining HP: ", current_health)
		if current_health <= 0:
			set_state(State.DEATH)
			anim.play("death")
		return
		
	current_health -= damage
	print(self.name, " took damage: ", damage, ". Remaining HP: ", current_health)

	if current_health <= 0:
		set_state(State.DEATH)
		anim.play("death")
		return
	else:
		set_state(State.HURT)
		
		var knockback_x = KNOCKBACK_FORCE * knockback_direction.x
		var knockback_y = JUMP_VELOCITY * 0.4
		
		velocity.x = knockback_x
		velocity.y = knockback_y if is_on_floor() else velocity.y 
		
		anim.play("take_hit")
		
		await anim.animation_finished
		
		if current_state == State.HURT:
			return_from_hurt()

func return_from_hurt():
	velocity.x = 0
	
	if is_on_floor():
		set_state(State.IDLE)
	else:
		set_state(State.FALL)
		
func get_max_health() -> int:
	return MAX_HEALTH
