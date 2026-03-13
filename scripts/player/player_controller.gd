extends CharacterBody2D
class_name PlayerController

## 玩家控制器 - 处理玩家移动和基础交互

# 信号
signal floor_changed(floor_id: int)
signal item_collected(item_id: String)
signal battle_started(enemy_id: String)

# 导出变量
@export var move_speed: float = 200.0
@export var can_move: bool = true

# 玩家属性
var player_data: Dictionary = {
	"hp": 1000,
	"max_hp": 1000,
	"attack": 10,
	"defense": 10,
	"gold": 0,
	"experience": 0,
	"floor": 1,
	"keys": {
		"yellow": 0,
		"blue": 0,
		"red": 0
	}
}

# 内部变量
var _is_in_battle: bool = false
var _current_floor: int = 1

func _ready() -> void:
	print("[Player] 玩家控制器初始化完成")

func _physics_process(delta: float) -> void:
	if not can_move or _is_in_battle:
		return
	
	_handle_movement()

func _handle_movement() -> void:
	var input_direction := Vector2.ZERO
	
	input_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	if input_direction != Vector2.ZERO:
		input_direction = input_direction.normalized()
	
	velocity = input_direction * move_speed
	move_and_slide()

func move_to(direction: Vector2) -> bool:
	"""
	尝试向指定方向移动
	返回：是否成功移动
	"""
	if not can_move or _is_in_battle:
		return false
	
	var target_position = global_position + direction * 32  # 假设格子大小为 32
	
	# 这里需要添加碰撞检测和事件触发
	# 暂时简化处理
	global_position = target_position
	return true

func collect_item(item_id: String, item_data: Dictionary) -> void:
	"""
	收集物品
	"""
	print("[Player] 收集物品：", item_id)
	item_collected.emit(item_id)
	
	# 应用物品效果
	if item_data.has("effect"):
		_apply_item_effect(item_data["effect"])

func _apply_item_effect(effect: Dictionary) -> void:
	"""
	应用物品效果
	"""
	if effect.has("hp"):
		player_data["hp"] = min(player_data["hp"] + effect["hp"], player_data["max_hp"])
	if effect.has("attack"):
		player_data["attack"] += effect["attack"]
	if effect.has("defense"):
		player_data["defense"] += effect["defense"]
	if effect.has("gold"):
		player_data["gold"] += effect["gold"]

func start_battle(enemy_id: String) -> void:
	"""
	开始战斗
	"""
	_is_in_battle = true
	can_move = false
	battle_started.emit(enemy_id)

func end_battle(result: Dictionary) -> void:
	"""
	结束战斗
	"""
	_is_in_battle = false
	can_move = true
	
	# 应用战斗结果
	if result.has("gold"):
		player_data["gold"] += result["gold"]
	if result.has("experience"):
		player_data["experience"] += result["experience"]

func change_floor(new_floor: int) -> void:
	"""
  切换楼层
	"""
	_current_floor = new_floor
	player_data["floor"] = new_floor
	floor_changed.emit(new_floor)
	print("[Player] 到达第 ", new_floor, " 层")

func get_player_data() -> Dictionary:
	"""
	获取玩家数据
	"""
	return player_data.duplicate(true)

func save_data() -> Dictionary:
	"""
	保存玩家数据
	"""
	return {
		"player_data": player_data,
		"position": global_position,
		"floor": _current_floor
	}

func load_data(data: Dictionary) -> void:
	"""
	加载玩家数据
	"""
	if data.has("player_data"):
		player_data = data["player_data"]
	if data.has("position"):
		global_position = data["position"]
	if data.has("floor"):
		_current_floor = data["floor"]
