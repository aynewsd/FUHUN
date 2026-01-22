extends CharacterBody2D

## 玩家控制脚本
## 负责处理移动、攻击逻辑、坐标边界限制、动画状态切换及死亡流程。

# --- 信号定义 ---
signal game_ended # 当游戏结束（玩家死亡）时发射

# --- 导出变量 (Inspector) ---
@export_group("属性设置")
@export var speed: int = 1000            # 移动速度
@export var attack_duration: float = 1.0 # 攻击持续时间（秒）
@export var animator: AnimatedSprite2D    # 动画节点引用

# --- 节点引用 ---
@onready var attack_area: Area2D = $AttackArea

# --- 状态变量 ---
var is_game_over: bool = false
var is_attacking: bool = false

# --- 生命周期回调 ---

func _ready() -> void:
	# 初始化：将攻击区域加入特定组，并关闭物理碰撞监测
	attack_area.add_to_group("player_attack")
	attack_area.monitoring = false

func _physics_process(_delta: float) -> void:
	if is_game_over: 
		return

	_handle_movement()
	_apply_position_constraints()
	_update_animations()

func _input(event: InputEvent) -> void:
	if is_game_over: 
		return
	
	# 检测鼠标左键点击，且当前不在攻击状态中
	if event.is_action_pressed("mouse_left") and not is_attacking:
		_execute_attack()

# --- 内部逻辑函数 ---

## 处理基础移动输入与物理滑动
func _handle_movement() -> void:
	# 获取四轴输入向量
	velocity = Input.get_vector("left", "right", "up", "down") * speed
	move_and_slide()

## 限制玩家在指定的像素边界内（Clamp）
func _apply_position_constraints() -> void:
	var min_x = -1200
	var max_x = 1200
	var min_y = -480
	var max_y = 480
	
	# 使用 clamp 确保 global_position 不会超出设定范围
	global_position.x = clamp(global_position.x, min_x, max_x)
	global_position.y = clamp(global_position.y, min_y, max_y)

## 处理动画状态机切换
func _update_animations() -> void:
	# 1. 处理视觉翻转 (Flip)
	if velocity.x < 0:
		animator.flip_h = true  # 向左移动，水平翻转
	elif velocity.x > 0:
		animator.flip_h = false # 向右移动，恢复默认
	
	# 2. 处理动作状态
	if is_attacking:
		animator.play("attack")
	elif velocity == Vector2.ZERO:
		animator.play("idle")
	else:
		animator.play("run")

## 执行攻击序列
func _execute_attack() -> void:
	is_attacking = true
	
	# 使攻击区域（扇形/矩形）朝向当前鼠标位置
	attack_area.rotation = get_local_mouse_position().angle()
	attack_area.monitoring = true # 激活碰撞监测
	
	# 等待攻击持续时间结束
	await get_tree().create_timer(attack_duration).timeout
	
	attack_area.monitoring = false # 关闭碰撞监测
	is_attacking = false

## 游戏结束处理
func game_over() -> void:
	if is_game_over: 
		return
	
	is_game_over = true
	animator.play("death")
	game_ended.emit() # 发射信号，通知如 UI 或 生成器 等其他模块
	
	# 等待死亡动画展示后重启场景
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
