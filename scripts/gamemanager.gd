extends Node2D

## 游戏关卡主控制脚本
## 负责处理怪物的周期性生成逻辑，并监听输入以实现场景切换。

# --- 资源预载 ---

# 将敌人场景预加载为变量，方便在运行时快速实例化
@export var vampire_scene: PackedScene = preload("res://scenes/vampire.tscn")

# --- 生命周期回调 ---

func _ready() -> void:
	# 确保计时器启动。联想：若 Timer 未在编辑器勾选 Autostart，则需手动开启
	if has_node("Timer"):
		$Timer.start()

func _process(_delta: float) -> void:
	# 当前无每帧更新逻辑，保持空实现
	pass

# --- 交互逻辑 ---

func _input(event: InputEvent) -> void:
	# 监听 UI 切换动作。联想：Esc 键通常映射在自定义的 "UI_toggle" 或系统预设 "ui_cancel" 中
	if event.is_action_pressed("UI_toggle"):
		_change_to_ui_scene()

## 执行场景跳转至 UI 界面
func _change_to_ui_scene() -> void:
	var ui_scene_path: String = "res://scenes/ui.tscn"
	
	# 核心跳转逻辑：卸载当前关卡并加载指定的 UI 场景
	var error = get_tree().change_scene_to_file(ui_scene_path)
	
	# 容错处理：若跳转失败则在控制台打印错误码
	if error != OK:
		print("跳转失败，请检查路径是否正确，错误码: ", error)

# --- 核心生成逻辑 ---

## 怪物生成回调函数（由 Timer 信号触发）
func spawn_vampire() -> void:
	print("--- 开始尝试生成怪物 ---")
	
	# 1. 查找玩家节点
	# 注意：Player 节点必须已加入名为 "player" 的分组
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("失败原因: 未找到加入 'player' 组的节点。")
		return
	
	# 2. 状态校验：若游戏已结束，停止生成逻辑
	if player.is_game_over:
		print("失败原因: 玩家状态为 is_game_over，停止刷新。")
		return

	# 3. 路径节点校验
	# 联想：此路径必须与 Player 场景内部的 Node 结构完全对应
	var path_follow = player.get_node_or_null("SpawnPath/PathFollow2D")
	if not path_follow:
		print("失败原因: 在玩家节点下未找到路径 'SpawnPath/PathFollow2D'。")
		return

	# 4. 实例化校验
	if not vampire_scene:
		print("失败原因: vampire_scene 资源加载失败。")
		return
		
	# 5. 执行生成与坐标对齐
	# 在路径上随机选取一个进度点（0.0 - 1.0）
	path_follow.progress_ratio = randf()
	
	var vampire = vampire_scene.instantiate()
	# 获取路径点的全局坐标并同步给怪物
	var spawn_pos: Vector2 = path_follow.global_position
	vampire.global_position = spawn_pos
	
	# 6. 挂载节点至当前场景
	add_child(vampire)
	print("成功: 怪物已实例化并添加至场景，位置: ", spawn_pos)
