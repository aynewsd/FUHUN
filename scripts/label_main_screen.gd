extends Label

## 标题文本控制脚本
## 负责初始化文本样式、屏幕对齐、以及基于鼠标悬停的交互式视觉反馈。

var is_hovering: bool = false # 记录鼠标是否悬停的内部状态

# --- 生命周期回调 ---

func _ready() -> void:
	# 1. 文本与样式初始化
	text = "附魂"
	add_theme_font_size_override("font_size", 64) 
	
	# 2. 交互配置：使 Label 能够响应鼠标事件
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 3. 布局与枢轴初始化
	center_me()

func _process(_delta: float) -> void:
	# 只有在非悬停状态下才执行呼吸效果动画
	if not is_hovering:
		# 利用正弦函数随时间产生周期性缩放值 (约 ±5% 的起伏)
		var wave = sin(Time.get_ticks_msec() * 0.005) * 0.05
		scale = Vector2(1.0 + wave, 1.0 + wave)

func _input(event: InputEvent) -> void:
	# 鼠标移动侦测逻辑
	if event is InputEventMouseMotion:
		# 检查当前鼠标全局位置是否在 Label 的矩形区域内
		if get_global_rect().has_point(get_global_mouse_position()):
			_on_hover_enter()
		else:
			_on_hover_exit()

# --- 内部逻辑函数 ---

## 屏幕中心对齐逻辑
func center_me() -> void:
	# 配置锚点为屏幕中心 (0.5 为 50%)
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	
	# 设置生长方向：内容扩展时保持对称，不会偏向一边
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# 初始化枢轴偏移，确保缩放与旋转动作基于文字中心点执行
	pivot_offset = size / 2
	
	# 设置相对于中心点的偏移坐标 (例如为了配合背景图手动微调)
	position = Vector2(-70, -150)

## 悬停反馈动画：放大并改变色调
func _on_hover_enter() -> void:
	if not is_hovering:
		is_hovering = true
		var tween = create_tween().set_parallel(true)
		# 0.1秒内完成放大、变色与微小旋转
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(self, "modulate", Color.GOLDENROD, 0.1)
		tween.tween_property(self, "rotation_degrees", 5.0, 0.1)

## 退出反馈动画：平滑恢复初始状态
func _on_hover_exit() -> void:
	if is_hovering:
		is_hovering = false
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
		tween.tween_property(self, "modulate", Color.WHITE, 0.1)
		tween.tween_property(self, "rotation_degrees", 0.0, 0.1)
