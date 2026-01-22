extends Button

## 开始按钮控制脚本
## 负责初始化按钮外观、布局对齐以及点击后的场景跳转逻辑。

# --- 生命周期回调 ---

func _ready() -> void:
	_setup_visuals()
	_setup_layout()

func _process(_delta: float) -> void:
	# 目前无动态逻辑，预留
	pass

# --- 内部初始化逻辑 ---

## 配置按钮的视觉样式
func _setup_visuals() -> void:
	# 设置按钮显示的文本内容
	text = "开始游戏"
	
	# 动态修改字体大小
	# 在 Godot 中，add_theme_font_size_override 用于覆盖主题资源中的默认数值
	add_theme_font_size_override("font_size", 25)

## 配置按钮的屏幕布局
func _setup_layout() -> void:
	# 将锚点和偏移预设设置为“中心”
	# 这会自动处理 anchor_left/right/top/bottom 属性
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	# 设置生长方向：确保文本内容改变时，按钮能从中心向四周对称伸展
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

# --- 交互逻辑 ---

## 重写内置点击回调函数
func _pressed() -> void:
	# 定义目标场景的资源路径（需确保路径与文件系统中完全一致）
	var target_scene: String = "res://Scenes/GameBackground.tscn" 
	
	# 执行场景树跳转：卸载当前场景并加载目标场景
	var error = get_tree().change_scene_to_file(target_scene)
	
	# 容错处理：若跳转失败（如路径错误），在控制台输出错误代码
	if error != OK:
		print("场景跳转失败，错误代码：", error)
