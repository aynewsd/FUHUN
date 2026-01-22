extends Area2D

## 扇形攻击区域控制脚本
## 负责程序化生成扇形碰撞区与视觉区域，并处理实时转向与销毁逻辑。

@export_group("形状设置")
@export var radius: float = 300 : set = _set_radius        # 扇形半径
@export var angle_degrees: float = 90.0 : set = _set_angle # 扇形张角（度）
@export var resolution: int = 64                           # 弧边采样精度（顶点数量）

@export_group("视觉表现")
@export var fill_color: Color = Color(1, 1, 1, 0.1)        # 内部填充颜色
@export var line_color: Color = Color(1, 1, 1, 0.2)        # 边缘线条颜色
@export var line_width: float = 2.0                        # 描边宽度

@onready var visual_area: Polygon2D = $VisualArea
@onready var collision_area: CollisionPolygon2D = $CollisionArea

# 缓存点集，避免在同一帧内重复执行三角函数计算
var _cached_points: PackedVector2Array

# --- 生命周期回调 ---

func _ready() -> void:
	update_sector_shape()
	
	# 连接父节点（Player）信号，实现游戏结束时的状态清理
	var player = get_parent()
	if player.has_signal("game_ended"):
		player.game_ended.connect(_on_player_game_ended)

func _process(_delta: float) -> void:
	# 实时转向逻辑：使扇形中心轴始终指向鼠标位置
	var mouse_pos = get_global_mouse_position()
	var dir = mouse_pos - global_position
	if dir.length() > 0:
		global_rotation = dir.angle()

# --- 核心形状生成逻辑 ---

## 计算并返回扇形的所有顶点坐标
func generate_sector_points() -> PackedVector2Array:
	var points = PackedVector2Array()
	points.append(Vector2.ZERO) # 圆心作为起点
	
	var half_angle_rad = deg_to_rad(angle_degrees / 2.0)
	var total_rad = deg_to_rad(angle_degrees)
	
	# 插值计算圆弧上的采样点
	for i in range(resolution + 1):
		var angle = -half_angle_rad + (total_rad * i / resolution)
		var point = Vector2(cos(angle), sin(angle)) * radius
		points.append(point)
	
	return points

## 刷新函数：同步物理碰撞体、视觉多边形及自定义绘制
func update_sector_shape() -> void:
	_cached_points = generate_sector_points()
	
	# 1. 更新物理碰撞区域 (CollisionPolygon2D)
	if collision_area:
		collision_area.build_mode = CollisionPolygon2D.BUILD_SOLIDS
		collision_area.polygon = _cached_points
	
	# 2. 更新视觉填充区域 (Polygon2D)
	if visual_area:
		visual_area.polygon = _cached_points
		visual_area.color = fill_color
		visual_area.material = null # 清除材质干扰
		visual_area.visible = true
	
	# 3. 请求重绘 CanvasItem 边框
	queue_redraw()

## CanvasItem 自定义绘制：处理外边框线条
func _draw() -> void:
	if _cached_points.size() < 3:
		return
		
	# 构造闭合线段：圆心 -> 弧 -> 连回圆心
	var line_points = _cached_points
	line_points.append(_cached_points[0]) 
	
	draw_polyline(line_points, line_color, line_width, true)

# --- 信号与属性 Setter ---

## 响应玩家游戏结束信号
func _on_player_game_ended() -> void:
	visible = false
	set_process(false) # 停止 _process 转向逻辑，释放性能

## 半径修改钩子
func _set_radius(val: float) -> void:
	radius = val
	if is_inside_tree(): 
		update_sector_shape()

## 角度修改钩子
func _set_angle(val: float) -> void:
	# 限制范围 (0.1, 359.9)，防止物理引擎因多边形重叠或坍缩报错
	angle_degrees = clamp(val, 0.1, 359.9)
	if is_inside_tree(): 
		update_sector_shape()
