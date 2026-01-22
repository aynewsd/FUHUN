extends Area2D

## 敌人（吸血鬼）AI 脚本
## 负责追踪玩家、处理受击判定、执行死亡动画以及碰撞玩家后的游戏结束逻辑。

# --- 属性设置 ---
@export var speed: float = 300.0          # 怪物移动速度

# --- 节点引用与状态 ---
@onready var animator: AnimatedSprite2D = $AnimatedSprite2D

var is_dead: bool = false
var player: Node2D = null                 # 目标玩家引用

# --- 生命周期回调 ---

func _ready() -> void:
	# 1. 查找目标：通过组（Group）定位玩家，比直接查找节点路径更稳健
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		# 2. 信号监听：当玩家死亡时，停止所有怪物的物理逻辑以节省性能
		if player.has_signal("game_ended"):
			player.game_ended.connect(_on_player_game_ended)

func _physics_process(delta: float) -> void:
	# 若怪物已死或未找到玩家，则不执行任何逻辑
	if is_dead or player == null: 
		return
	
	_handle_chase_logic(delta)

# --- 核心逻辑函数 ---

## 处理追踪移动与视觉翻转
func _handle_chase_logic(delta: float) -> void:
	# 计算指向玩家的方向向量并归一化
	var direction = (player.global_position - global_position).normalized()
	
	# 向玩家位置平移
	global_position += direction * speed * delta
	
	# 视觉转向：根据移动方向的 X 轴分量决定是否水平翻转
	if direction.x < 0:
		animator.flip_h = true 
	elif direction.x > 0:
		animator.flip_h = false

## 执行死亡序列
func die() -> void:
	if is_dead: return
	is_dead = true
	
	# 播放预设的死亡动画
	animator.play("death") 
	
	# 视觉效果：利用 Tween 创建平滑的透明度淡出效果
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.5)
	
	# 等待动画播放完毕后将对象从内存中移除
	await get_tree().create_timer(0.5).timeout
	queue_free()

# --- 信号处理函数 ---

## 接收玩家游戏结束信号的回调
func _on_player_game_ended() -> void:
	# 彻底停止当前节点的物理更新
	set_physics_process(false)

## 碰撞判定：当攻击区域进入
func _on_area_entered(area: Area2D) -> void:
	# 判定条件：名称匹配或属于攻击组、非死亡状态且攻击判定处于激活(monitoring)状态
	var is_player_attack = area.name == "AttackArea" or area.is_in_group("player_attack")
	if is_player_attack and not is_dead and area.monitoring:
		die()

## 碰撞判定：当撞击到玩家身体
func _on_body_entered(body: Node2D) -> void:
	# 若怪物已死，则无法再对玩家造成伤害
	if is_dead: return 
	
	# 若撞击对象是玩家并具备游戏结束方法，则触发
	if body.is_in_group("player") and body.has_method("game_over"):
		body.game_over()
