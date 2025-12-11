extends CharacterBody2D

# --- 核心属性 ---
const SPEED = 250.0
const JUMP_VELOCITY = -500.0
const ROLL_SPEED = 400.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- 状态机 ---
enum State { IDLE, RUN, JUMP, FALL, ROLL, ATTACK, AIR_ATTACK, SP_ATTACK, DEFEND, HURT, DEATH }
var current_state = State.IDLE

# --- 连击/技能系统 ---
var combo_count = 0 
var can_combo = false 
var is_active_state = false 

# --- 节点引用 ---
@onready var anim = $AnimatedSprite2D
@onready var hitbox_area = $Hitbox 
@onready var hitbox_col = $Hitbox/CollisionShape2D 
@onready var hitbox_shape = hitbox_col.shape as RectangleShape2D 
@onready var default_hitbox_size = hitbox_shape.size 

var was_on_floor = false

func _ready():
	hitbox_col.disabled = true
	is_active_state = current_state in [State.ROLL, State.ATTACK, State.AIR_ATTACK, State.SP_ATTACK, State.DEFEND, State.HURT]
	
	# 强制初始化状态为 IDLE，确保动画和状态机从地面开始
	set_state(State.IDLE)
	
	# 确保初始朝向为右侧
	anim.flip_h = false
	$Hitbox.scale.x = 1

func _physics_process(delta):
	if current_state == State.DEATH:
		return
	
	was_on_floor = is_on_floor() 
	
	# 1. 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta
		# 只有在 IDLE/RUN/JUMP 状态时，才允许切换到 FALL
		if velocity.y > 0 and not is_active_state and current_state != State.FALL:
			set_state(State.FALL)
		
	# 2. 状态分发
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
	
	move_and_slide()
	
	# 3. 落地状态检查
	check_landing_state() 
	
	update_animation()
	manage_hitbox_active_frames()

# --- 落地检查函数 (保持不变) ---
func check_landing_state():
	if is_on_floor() and not was_on_floor:
		if current_state == State.FALL or current_state == State.JUMP:
			set_state(State.IDLE) 

# --- 输入处理函数 (修复核心逻辑) ---
func handle_move_input():
	if is_active_state: return 

	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * SPEED
		
		# 修复点 2A：仅在状态需要切换时调用 set_state
		if is_on_floor() and current_state != State.RUN:
			set_state(State.RUN)
		
		# 转身逻辑
		if direction < 0:
			anim.flip_h = true
			hitbox_area.scale.x = -1 
		else:
			anim.flip_h = false
			hitbox_area.scale.x = 1
	else:
		# 减速逻辑
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
		# 修复点 2B：仅在状态需要切换且速度已经很接近 0 时才切换到 IDLE
		if is_on_floor() and current_state != State.IDLE and abs(velocity.x) < 5.0:
			set_state(State.IDLE)

	# 跳跃
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		set_state(State.JUMP)

# --- 动画更新 (关键修复点 1：依赖 State 而非 Velocity) ---
func update_animation():
	if is_active_state: return 
	
	match current_state:
		State.IDLE:
			anim.play("idle")
		State.RUN:
			anim.play("run")
		State.JUMP:
			anim.play("jump_up") 
		State.FALL:
			anim.play("jump_down") 
		_:
			# 如果处于其他状态（如ATTACK/ROLL等），由它们自己的启动函数控制动画，这里不做处理
			pass

# --- 状态切换和锁定管理 ---
func set_state(new_state: State):
	if current_state == new_state:
		return

	# 清理旧状态的连击窗口，避免在非ATTACK状态下can_combo仍为true
	if current_state != State.ATTACK:
		can_combo = false
		combo_count = 0
		
	current_state = new_state
	is_active_state = new_state in [State.ROLL, State.ATTACK, State.AIR_ATTACK, State.SP_ATTACK, State.DEFEND, State.HURT]
	
	if not is_active_state:
		hitbox_col.disabled = true
		
# --- 输入处理函数 ---

	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * SPEED
		if is_on_floor(): set_state(State.RUN)
		
		if direction < 0:
			anim.flip_h = true
			hitbox_area.scale.x = -1 
		else:
			anim.flip_h = false
			hitbox_area.scale.x = 1
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor(): set_state(State.IDLE)

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		set_state(State.JUMP)

func handle_action_input():
	if is_active_state and current_state != State.ATTACK: return

	# 攻击输入 (普通攻击 / 连击 / 空中攻击)
	if Input.is_action_just_pressed("ui_accept"):
		# 连击检测已经被 handle_attack_logic 处理
		if current_state == State.ATTACK: 
			# 如果在攻击状态，则交给 handle_attack_logic 处理连击输入
			pass 
		elif is_on_floor():
			start_attack(1)
			return
		elif not is_on_floor():
			start_air_attack()
			return

	# 特殊攻击
	if Input.is_action_just_pressed("sp_attack") and is_on_floor():
		start_special_attack()
		return

	# 翻滚
	if Input.is_action_just_pressed("roll") and is_on_floor():
		start_roll()
		return

	# 防御
	if Input.is_action_pressed("ui_down") and is_on_floor():
		set_state(State.DEFEND)
		anim.play("defend")

func start_attack(combo_stage):
	set_state(State.ATTACK)
	hitbox_area.position = Vector2(0, 0)
	combo_count = combo_stage
	velocity.x = 0 
	# 修复点：这里不设置 can_combo = false，而是交给 manage_hitbox_active_frames 统一处理
	
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
	# 攻击时的摩擦力
	velocity.x = move_toward(velocity.x, 0, 10.0)
	
	# **修复点：连击检测必须在 Input 中进行，避免错过帧**
	if current_state == State.ATTACK and Input.is_action_just_pressed("ui_accept") and can_combo:
		if combo_count == 1:
			start_attack(2)
		elif combo_count == 2:
			start_attack(3)

# --- 动画更新 (保持不变) ---
	
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

# --- 信号连接：动画结束 (保持不变) ---
func _on_animated_sprite_2d_animation_finished():
	var finished_state = current_state
	
	if finished_state == State.ROLL or finished_state == State.AIR_ATTACK or finished_state == State.SP_ATTACK:
		return_to_idle()
		
	elif finished_state == State.ATTACK:
		if combo_count == 3:
			return_to_idle()
		elif not can_combo:
			return_to_idle()
		else:
			# 连击窗口开启，启动计时器等待输入
			get_tree().create_timer(0.1).timeout.connect(reset_after_combo_window, CONNECT_ONE_SHOT)

func reset_after_combo_window():
	# 只有当状态仍是 ATTACK 且 combo_count 尚未更新时，才复位
	if current_state == State.ATTACK:
		# 确保 combo_count 还是上一段攻击的数值
		return_to_idle()


# --- 核心：手动 Hitbox 帧控制和调整 (保持不变) ---
func manage_hitbox_active_frames():
	if not is_active_state or current_state in [State.ROLL, State.DEFEND, State.HURT]:
		hitbox_col.disabled = true
		can_combo = false # 如果不是攻击状态，连击窗口必须关闭
		return
		
	var ani = anim.animation
	var frame = anim.frame
	var dir_x = 1 if not anim.flip_h else -1
	
	hitbox_shape.size = default_hitbox_size
	hitbox_area.position = Vector2(0, 0)
	hitbox_col.disabled = true 
	can_combo = false # 默认关闭，由下面的逻辑开启

	# --- 攻击帧判定与 Hitbox 调整 ---
	
	if ani == "atk_1":
		if frame >= 4 and frame <= 8:
			hitbox_col.disabled = false
			hitbox_shape.size = Vector2(60, 80)
			hitbox_area.position = Vector2(dir_x * 20, 30) 

		if frame >= 6 and frame <= 10:
			can_combo = true # 连击窗口开启

	elif ani == "atk_2":
		if frame >= 3 and frame <= 9:
			hitbox_col.disabled = false
			hitbox_shape.size = Vector2(100, 70) 
			hitbox_area.position = Vector2(dir_x * 10, 0) 

		if frame >= 7 and frame <= 11:
			can_combo = true # 连击窗口开启

	elif ani == "atk_3":
		if frame >= 4 and frame <= 9:
			hitbox_col.disabled = false
			hitbox_shape.size = Vector2(150, 100) 
			hitbox_area.position = Vector2(dir_x * 50, -50)
		
	elif ani == "air_atk":
		if frame >= 3 and frame <= 6:
			hitbox_col.disabled = false
			hitbox_shape.size = Vector2(200, 50) 
			hitbox_area.position = Vector2(dir_x * 100, 0) 

	elif ani == "sp_atk":
		if frame >= 12 and frame <= 15:
			hitbox_col.disabled = false
			hitbox_shape.size = Vector2(250, 150) 
			hitbox_area.position = Vector2(dir_x * 0, 80) 

# --- 信号连接：Hitbox 接触到敌人 Hurtbox (示例) ---
func _on_hitbox_area_entered(area):
	if area.name == "Hurtbox":
		var enemy = area.get_parent()
		if enemy.has_method("take_hit"):
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
