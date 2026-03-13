extends CharacterBody2D
class_name PlayerController

## 玩家控制器 v2 - 处理玩家移动、交互和战斗

# 信号
signal player_damaged(damage: int)
signal player_healed(amount: int)
signal player_died
signal item_picked_up(item_id: String)
signal key_used(key_type: String)
signal floor_changed(floor_id: int)

# 玩家属性
@export var max_hp: int = 1000
@export var attack: int = 10
@export var defense: int = 10
@export var gold: int = 0
@export var experience: int = 0
@export var level: int = 1

# 当前状态
var current_hp: int = 1000
var current_floor: int = 1
var position_grid: Vector2i = Vector2i(7, 7)

# 钥匙
var keys: Dictionary = {
	"yellow": 0,
	"blue": 0,
	"red": 0
}

# 道具栏
var inventory: Array = []
var equipment: Dictionary = {
	"weapon": null,
	"shield": null
}

# 移动配置
@export var move_speed: float = 200.0
@export var tile_size: int = 32
@export var snap_to_grid: bool = true

# 状态标志
var is_moving: bool = false
var is_in_battle: bool = false
var is_interacting: bool = false

# 引用
var game_manager: Node
var map_loader: Node
var ui_manager: Node

func _ready() -> void:
	print("[Player] 玩家控制器初始化完成")
	current_hp = max_hp
	_find_references()
	_update_ui()

func _find_references() -> void:
	"""
	查找场景中的引用节点
	"""
	game_manager = get_node_or_null("/root/Main/GameManager")
	map_loader = get_node_or_null("/root/Main/MapLoader")
	ui_manager = get_node_or_null("/root/Main/UILayer/UIManager")

func _physics_process(delta: float) -> void:
	if is_moving or is_in_battle or is_interacting:
		return
	
	_handle_input()

func _handle_input() -> void:
	"""
	处理玩家输入
	"""
	var direction = Vector2.ZERO
	
	if Input.is_action_just_pressed("ui_up"):
		direction = Vector2.UP
	elif Input.is_action_just_pressed("ui_down"):
		direction = Vector2.DOWN
	elif Input.is_action_just_pressed("ui_left"):
		direction = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_right"):
		direction = Vector2.RIGHT
	
	if direction != Vector2.ZERO:
		_try_move(direction)
	
	# 交互
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	
	# 菜单
	if Input.is_action_just_pressed("menu"):
		_toggle_menu()

func _try_move(direction: Vector2) -> void:
	"""
	尝试向指定方向移动
	"""
	var new_pos = position_grid + Vector2i(direction)
	
	# 检查碰撞
	if not _is_walkable(new_pos):
		print("[Player] 无法通行：", new_pos)
		return
	
	# 检查门
	var door = _get_door_at(new_pos)
	if door:
		if _try_open_door(door):
			_execute_move(direction, new_pos)
		return
	
	# 检查敌人
	var enemy = _get_enemy_at(new_pos)
	if enemy:
		_start_battle(enemy)
		return
	
	# 执行移动
	_execute_move(direction, new_pos)

func _execute_move(direction: Vector2, new_pos: Vector2i) -> void:
	"""
	执行移动
	"""
	is_moving = true
	position_grid = new_pos
	
	# 平滑移动到目标位置
	var target_pos = Vector2(new_pos.x * tile_size, new_pos.y * tile_size)
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 0.15)
	tween.tween_callback(_on_move_complete)
	
	# 检查拾取
	_check_pickup()
	
	# 检查楼梯
	_check_stairs()

func _on_move_complete() -> void:
	is_moving = false

func _is_walkable(pos: Vector2i) -> bool:
	"""
	检查位置是否可通行
	"""
	if map_loader:
		return map_loader.is_walkable(pos.x, pos.y)
	return true

func _get_door_at(pos: Vector2i) -> Dictionary:
	"""
	获取位置的門
	"""
	# 从地图数据中检查
	if map_loader and map_loader.has_method("get_door_at"):
		return map_loader.get_door_at(pos.x, pos.y)
	return {}

func _try_open_door(door: Dictionary) -> bool:
	"""
	尝试打开门
	"""
	var door_type = door.get("type", "yellow")
	var is_locked = door.get("locked", true)
	
	if not is_locked:
		return true
	
	# 检查钥匙
	if keys.get(door_type, 0) > 0:
		keys[door_type] -= 1
		key_used.emit(door_type)
		print("[Player] 使用 ", door_type, " 钥匙，剩余：", keys[door_type])
		_update_ui()
		return true
	else:
		print("[Player] 没有 ", door_type, " 钥匙")
		return false

func _get_enemy_at(pos: Vector2i) -> Dictionary:
	"""
	获取位置的敌人
	"""
	if map_loader and map_loader.has_method("get_enemy_at"):
		return map_loader.get_enemy_at(pos.x, pos.y)
	return {}

func _start_battle(enemy: Dictionary) -> void:
	"""
	开始战斗
	"""
	is_in_battle = true
	print("[Player] 遭遇敌人：", enemy.get("name", "未知"))
	
	if game_manager and game_manager.has_method("start_battle"):
		game_manager.start_battle(enemy)

func _check_pickup() -> void:
	"""
	检查拾取物品
	"""
	if map_loader and map_loader.has_method("get_item_at"):
		var item = map_loader.get_item_at(position_grid.x, position_grid.y)
		if item:
			_pickup_item(item)

func _pickup_item(item: Dictionary) -> void:
	"""
	拾取物品
	"""
	var item_id = item.get("id", "")
	var item_type = item.get("type", "")
	
	print("[Player] 拾取：", item.get("name", item_id))
	
	match item_type:
		"consumable", "permanent":
			inventory.append(item)
			_apply_item_effect(item)
		"key":
			var key_type = item_id.split("_")[1] if "_" in item_id else "yellow"
			keys[key_type] = keys.get(key_type, 0) + 1
		"equipment":
			inventory.append(item)
	
	item_picked_up.emit(item_id)
	_update_ui()
	
	# 从地图移除
	if map_loader and map_loader.has_method("remove_item_at"):
		map_loader.remove_item_at(position_grid.x, position_grid.y)

func _apply_item_effect(item: Dictionary) -> void:
	"""
	应用道具效果
	"""
	var effect = item.get("effect", {})
	
	if effect.has("hp"):
		heal(effect["hp"])
	if effect.has("attack"):
		attack += effect["attack"]
		print("[Player] 攻击力提升：", effect["attack"])
	if effect.has("defense"):
		defense += effect["defense"]
		print("[Player] 防御力提升：", effect["defense"])

func _check_stairs() -> void:
	"""
	检查楼梯
	"""
	if map_loader and map_loader.has_method("get_stairs_at"):
		var stairs = map_loader.get_stairs_at(position_grid.x, position_grid.y)
		if stairs:
			_use_stairs(stairs)

func _use_stairs(stairs: Dictionary) -> void:
	"""
	使用楼梯
	"""
	var direction = stairs.get("direction", "down")
	var target_floor = current_floor
	
	if direction == "up":
		target_floor += 1
	else:
		target_floor -= 1
	
	if target_floor < 1 or target_floor > 50:
		print("[Player] 无法前往楼层：", target_floor)
		return
	
	print("[Player] 前往第 ", target_floor, " 层")
	current_floor = target_floor
	
	# 加载新楼层
	if map_loader and map_loader.has_method("load_floor"):
		map_loader.load_floor(current_floor)
	
	floor_changed.emit(current_floor)
	_update_ui()

func _try_interact() -> void:
	"""
	尝试交互
	"""
	is_interacting = true
	
	# 检查 NPC
	if map_loader and map_loader.has_method("get_npc_at"):
		var npc = map_loader.get_npc_adjacent(position_grid.x, position_grid.y)
		if npc:
			_talk_to_npc(npc)
	
	is_interacting = false

func _talk_to_npc(npc: Dictionary) -> void:
	"""
	与 NPC 对话
	"""
	var dialog = npc.get("dialog", "...")
	print("[Player] NPC 对话：", dialog)
	
	if ui_manager and ui_manager.has_method("show_dialog"):
		ui_manager.show_dialog(dialog)

func _toggle_menu() -> void:
	"""
 切换菜单
	"""
	if ui_manager and ui_manager.has_method("toggle_menu"):
		ui_manager.toggle_menu()

func take_damage(damage: int) -> void:
	"""
	受到伤害
	"""
	var actual_damage = max(0, damage - defense)
	current_hp -= actual_damage
	
	print("[Player] 受到 ", actual_damage, " 点伤害 (防御减免：", defense, ")")
	
	player_damaged.emit(actual_damage)
	_update_ui()
	
	if current_hp <= 0:
		_die()

func heal(amount: int) -> void:
	"""
	治疗
	"""
	current_hp = min(current_hp + amount, max_hp)
	print("[Player] 恢复 ", amount, " 点 HP")
	
	player_healed.emit(amount)
	_update_ui()

func _die() -> void:
	"""
	死亡处理
	"""
	print("[Player] 玩家死亡")
	player_died.emit()
	
	if game_manager and game_manager.has_method("game_over"):
		game_manager.game_over()

func _update_ui() -> void:
	"""
	更新 UI 显示
	"""
	if ui_manager and ui_manager.has_method("update_player_stats"):
		ui_manager.update_player_stats({
			"hp": current_hp,
			"max_hp": max_hp,
			"gold": gold,
			"attack": attack,
			"defense": defense,
			"floor": current_floor
		})
	
	if ui_manager and ui_manager.has_method("update_keys"):
		ui_manager.update_keys(keys)

func gain_experience(amount: int) -> void:
	"""
	获得经验
	"""
	experience += amount
	print("[Player] 获得 ", amount, " 点经验")
	
	# 检查升级
	var exp_needed = level * 100
	if experience >= exp_needed:
		_level_up()

func _level_up() -> void:
	"""
	升级
	"""
	level += 1
	max_hp += 50
	attack += 5
	defense += 3
	current_hp = max_hp
	
	print("[Player] 升级到 ", level, " 级！")
	print("  HP: ", max_hp)
	print("  攻击：", attack)
	print("  防御：", defense)
	
	_update_ui()

func gain_gold(amount: int) -> void:
	"""
	获得金币
	"""
	gold += amount
	print("[Player] 获得 ", amount, " 金币")
	_update_ui()

func get_stats() -> Dictionary:
	"""
	获取玩家属性
	"""
	return {
		"hp": current_hp,
		"max_hp": max_hp,
		"attack": attack,
		"defense": defense,
		"gold": gold,
		"experience": experience,
		"level": level,
		"floor": current_floor,
		"position": position_grid,
		"keys": keys.duplicate()
	}

func load_stats(stats: Dictionary) -> void:
	"""
	加载玩家属性（读档用）
	"""
	current_hp = stats.get("hp", max_hp)
	max_hp = stats.get("max_hp", 1000)
	attack = stats.get("attack", 10)
	defense = stats.get("defense", 10)
	gold = stats.get("gold", 0)
	experience = stats.get("experience", 0)
	level = stats.get("level", 1)
	current_floor = stats.get("floor", 1)
	keys = stats.get("keys", {"yellow": 0, "blue": 0, "red": 0})
