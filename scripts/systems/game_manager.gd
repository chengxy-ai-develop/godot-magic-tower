extends Node
class_name GameManager

## 游戏管理器 - 处理游戏流程、状态和战斗

# 信号
signal game_started
signal game_over
signal game_won
signal floor_changed(floor_id: int)
signal battle_started(enemy_data: Dictionary)
signal battle_won(rewards: Dictionary)
signal battle_lost

# 游戏状态
enum GameState { MENU, PLAYING, BATTLE, DIALOG, GAME_OVER, VICTORY }
var current_state: GameState = GameState.MENU

# 玩家引用
var player: Node
var ui_manager: Node
var map_loader: Node
var save_system: Node

# 战斗配置
var battle_config: Dictionary = {
	"auto_battle": false,
	"show_damage": true,
	"speed_multiplier": 1.0
}

# 游戏数据
var game_data: Dictionary = {
	"start_time": 0,
	"play_time": 0,
	"deaths": 0,
	"monsters_defeated": 0,
	"items_collected": 0
}

func _ready() -> void:
	print("[GameManager] 游戏管理器初始化完成")
	_find_references()
	_connect_signals()

func _find_references() -> void:
	"""
	查找场景引用
	"""
	player = get_node_or_null("../Player")
	ui_manager = get_node_or_null("../UILayer/UIManager")
	map_loader = get_node_or_null("../MapLoader")
	save_system = get_node_or_null("../SaveSystem")

func _connect_signals() -> void:
	"""
	连接信号
	"""
	if player:
		player.connect("player_damaged", _on_player_damaged)
		player.connect("floor_changed", _on_floor_changed)
		player.connect("player_died", _on_player_died)

func _on_player_damaged(damage: int) -> void:
	"""
	玩家受伤处理
	"""
	print("[GameManager] 玩家受伤：", damage)

func _on_floor_changed(floor_id: int) -> void:
	"""
	楼层变化处理
	"""
	floor_changed.emit(floor_id)
	print("[GameManager] 到达第 ", floor_id, " 层")
	
	# 检查胜利条件
	if floor_id == 50:
		_start_final_battle()

func _on_player_died() -> void:
	"""
	玩家死亡处理
	"""
	game_data["deaths"] += 1
	game_over.emit()
	set_state(GameState.GAME_OVER)
	
	print("[GameManager] 游戏结束")
	print("  死亡次数：", game_data["deaths"])
	print("  游戏时间：", game_data["play_time"], " 秒")

func _process(delta: float) -> void:
	"""
	游戏流程处理
	"""
	if current_state == GameState.PLAYING:
		game_data["play_time"] += delta

func start_game() -> void:
	"""
	开始新游戏
	"""
	print("[GameManager] 开始新游戏")
	
	# 重置玩家状态
	if player:
		player.current_hp = player.max_hp
		player.attack = 10
		player.defense = 10
		player.gold = 0
		player.experience = 0
		player.level = 1
		player.current_floor = 1
		player.position_grid = Vector2i(7, 7)
	
	# 重置游戏数据
	game_data = {
		"start_time": Time.get_unix_time_from_system(),
		"play_time": 0,
		"deaths": 0,
		"monsters_defeated": 0,
		"items_collected": 0
	}
	
	# 加载第 1 层
	if map_loader:
		map_loader.load_floor(1)
	
	set_state(GameState.PLAYING)
	game_started.emit()
	
	# 显示欢迎对话
	if ui_manager:
		ui_manager.show_dialog("欢迎来到魔塔！目标是到达第 50 层...", true, 3.0)

func load_game(slot: int) -> bool:
	"""
	加载存档
	"""
	if not save_system:
		return false
	
	var data = save_system.load_game(slot)
	if data.is_empty():
		return false
	
	# 恢复玩家状态
	if player and data.has("player"):
		player.load_stats(data["player"])
	
	# 恢复游戏数据
	if data.has("game_data"):
		game_data = data["game_data"]
	
	# 加载楼层
	if data.has("floor"):
		if map_loader:
			map_loader.load_floor(data["floor"])
	
	set_state(GameState.PLAYING)
	print("[GameManager] 游戏已加载")
	return true

func save_game(slot: int) -> bool:
	"""
	保存游戏
	"""
	if not save_system:
		return false
	
	var game_state = {
		"player": player.get_stats() if player else {},
		"floor": player.current_floor if player else 1,
		"game_data": game_data
	}
	
	return save_system.save_game(slot, game_state)

func set_state(new_state: GameState) -> void:
	"""
	设置游戏状态
	"""
	current_state = new_state
	print("[GameManager] 状态变更：", GameState.keys()[new_state])

func start_battle(enemy_data: Dictionary) -> void:
	"""
	开始战斗
	"""
	set_state(GameState.BATTLE)
	battle_started.emit(enemy_data)
	
	print("[GameManager] 战斗开始")
	print("  敌人：", enemy_data.get("name", "未知"))
	print("  HP: ", enemy_data.get("stats", {}).get("hp", 0))
	print("  攻击：", enemy_data.get("stats", {}).get("attack", 0))
	print("  防御：", enemy_data.get("stats", {}).get("defense", 0))
	
	# 显示战斗 UI
	if ui_manager and ui_manager.has_method("start_battle_ui"):
		var enemy_stats = enemy_data.get("stats", {})
		ui_manager.start_battle_ui(
			enemy_data.get("name", "敌人"),
			enemy_stats.get("hp", 0),
			player.current_hp if player else 1000
		)
	
	# 执行战斗计算
	if battle_config.auto_battle:
		_resolve_battle_auto(enemy_data)
	else:
		_resolve_battle_manual(enemy_data)

func _resolve_battle_auto(enemy_data: Dictionary) -> void:
	"""
	自动战斗（快速计算）
	"""
	var player_stats = player.get_stats() if player else {}
	var enemy_stats = enemy_data.get("stats", {})
	
	var player_hp = player_stats.get("hp", 1000)
	var player_atk = player_stats.get("attack", 10)
	var player_def = player_stats.get("defense", 10)
	
	var enemy_hp = enemy_stats.get("hp", 100)
	var enemy_atk = enemy_stats.get("attack", 20)
	var enemy_def = enemy_stats.get("defense", 5)
	
	# 计算伤害
	var player_damage = max(0, player_atk - enemy_def)
	var enemy_damage = max(0, enemy_atk - player_def)
	
	print("[Battle] 玩家每次伤害：", player_damage)
	print("[Battle] 敌人每次伤害：", enemy_damage)
	
	if player_damage <= 0:
		# 无法破防，必败
		_battle_lost(enemy_data)
		return
	
	# 计算回合数
	var turns_to_kill_enemy = ceil(float(enemy_hp) / player_damage)
	var turns_to_kill_player = ceil(float(player_hp) / enemy_damage) if enemy_damage > 0 else 999
	
	print("[Battle] 击杀敌人需要：", turns_to_kill_enemy, " 回合")
	print("[Battle] 敌人击杀你需要：", turns_to_kill_player, " 回合")
	
	# 计算总伤害
	var total_damage = enemy_damage * (turns_to_kill_enemy - 1)
	
	if total_damage >= player_hp:
		_battle_lost(enemy_data)
	else:
		_battle_won(enemy_data, total_damage)

func _resolve_battle_manual(enemy_data: Dictionary) -> void:
	"""
	手动战斗（回合制）
	"""
	# 简化实现，使用自动战斗逻辑
	_resolve_battle_auto(enemy_data)

func _battle_won(enemy_data: Dictionary, damage_taken: int) -> void:
	"""
	战斗胜利处理
	"""
	var enemy_stats = enemy_data.get("stats", {})
	
	# 玩家扣血
	if player:
		player.take_damage(damage_taken)
	
	# 奖励
	var rewards = {
		"gold": enemy_stats.get("gold", 0),
		"experience": enemy_stats.get("experience", 0)
	}
	
	if player:
		player.gain_gold(rewards.gold)
		player.gain_experience(rewards.experience)
	
	game_data["monsters_defeated"] += 1
	
	print("[GameManager] 战斗胜利！")
	print("  获得金币：", rewards.gold)
	print("  获得经验：", rewards.experience)
	
	# 更新 UI
	if ui_manager and ui_manager.has_method("end_battle_ui"):
		ui_manager.end_battle_ui({"won": true, "gold": rewards.gold, "experience": rewards.experience})
	
	battle_won.emit(rewards)
	set_state(GameState.PLAYING)
	
	# 从地图移除敌人
	if map_loader and map_loader.has_method("remove_enemy"):
		map_loader.remove_enemy(enemy_data)

func _battle_lost(enemy_data: Dictionary) -> void:
	"""
	战斗失败处理
	"""
	print("[GameManager] 战斗失败！")
	
	if ui_manager and ui_manager.has_method("end_battle_ui"):
		ui_manager.end_battle_ui({"won": false})
	
	battle_lost.emit()
	
	# 玩家死亡
	if player:
		player._die()

func _start_final_battle() -> void:
	"""
	最终 Boss 战
	"""
	print("[GameManager] 最终 Boss 战！")
	
	var final_boss = {
		"id": "guardian_final",
		"name": "最终守护者",
		"stats": {
			"hp": 1500,
			"attack": 150,
			"defense": 80,
			"gold": 500,
			"experience": 200
		}
	}
	
	start_battle(final_boss)

func check_victory() -> void:
	"""
	检查胜利条件
	"""
	if player and player.current_floor == 50:
		_victory()

func _victory() -> void:
	"""
	胜利处理
	"""
	set_state(GameState.VICTORY)
	game_won.emit()
	
	print("[GameManager] 恭喜通关！")
	print("  游戏时间：", game_data["play_time"], " 秒")
	print("  击败怪物：", game_data["monsters_defeated"])
	print("  死亡次数：", game_data["deaths"])
	
	if ui_manager:
		ui_manager.show_dialog("恭喜！你成功登上了魔塔之巅！", true, 5.0)

func pause_game() -> void:
	"""
	暂停游戏
	"""
	get_tree().paused = true
	print("[GameManager] 游戏暂停")

func resume_game() -> void:
	"""
	恢复游戏
	"""
	get_tree().paused = false
	print("[GameManager] 游戏恢复")

func quit_game() -> void:
	"""
	退出游戏
	"""
	print("[GameManager] 退出游戏")
	get_tree().quit()

func get_game_data() -> Dictionary:
	"""
	获取游戏数据
	"""
	return game_data.duplicate()
