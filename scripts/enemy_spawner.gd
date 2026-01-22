extends Node2D

## 敌人生成器脚本
## 负责在指定路径上周期性地实例化敌人，并处理生成逻辑的开启与关闭。

@export_group("生成设置")
@export var enemy_scene: PackedScene = preload("res://Player/vampire.tscn") # 待生成的敌人预制体
@export var spawn_interval: float = 1.0                                    # 每次生成的间隔时间（秒）

@onready var spawn_path: PathFollow2D = $SpawnPath/PathFollow2D            # 生成位置参考路径
@onready var timer: Timer = $Timer                                         # 定时器引用

# --- 生命周期回调 ---

func _ready() -> void:
	_setup_timer()
	# 联想：如果路径节点是动态挂载在玩家身上的，可在此处进行动态寻址绑定

# --- 核心逻辑函数 ---

## 初始化并启动定时器
func _setup_timer() -> void:
	# 健壮性检查：若场景中未手动添加 Timer 节点，则程序化创建一个
	if not has_node("Timer"):
		timer = Timer.new()
		add_child(timer)
	
	# 配置定时器属性：利用 Timer 节点控制节奏，比在 _process 中计算 delta 更节省性能
	timer.wait_time = spawn_interval
	# 连接超时信号到生成回调函数
	if not timer.timeout.is_connected(_on_spawn_timer_timeout):
		timer.timeout.connect(_on_spawn_timer_timeout)
	timer.start()

## 执行敌人实例化与位置分配
func spawn_enemy() -> void:
	# 1. 资源校验
	if not enemy_scene: return
	
	# 2. 确定位置
	# progress_ratio (0.0 - 1.0) 代表路径长度的百分比，实现沿路径随机选点
	spawn_path.progress_ratio = randf()
	var spawn_pos: Vector2 = spawn_path.global_position
	
	# 3. 实例化与初始化
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	
	# 4. 节点挂载
	# 将敌人添加到当前活动场景根部，确保其在世界空间独立活动，不随生成器位移
	get_tree().current_scene.add_child(enemy)

# --- 信号处理与条件控制 ---

## 定时器超时回调：执行生成前的条件判定
func _on_spawn_timer_timeout() -> void:
	# 举一反三：性能优化逻辑
	# 寻找玩家节点。若玩家已不存在或游戏结束，则停止刷新以节省计算资源
	var players = get_tree().get_nodes_in_group("player")
	
	if players.size() == 0 or players[0].is_game_over:
		timer.stop()
		print("检测到游戏结束，怪兽刷新器已停止。")
		return

	spawn_enemy()
