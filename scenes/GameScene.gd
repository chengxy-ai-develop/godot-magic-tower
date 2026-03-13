extends Node2D
class_name GameScene

## 游戏主场景 - 整合所有游戏系统
## 负责场景管理、系统初始化、游戏流程控制

@export var start_floor: int = 1

var player: Node
var game_manager: Node
var ui_manager: Node
var battle_system: Node
var save_system: Node
var map_loader: Node

func _ready() -> void:
	print("[GameScene] 游戏场景初始化")
	_find_references()
	_connect_signals()
	
	# 启动游戏
	await get_tree().create_timer(0.5).timeout
	start_new_game()

func _find_references() -> void:
	player = get_node_or_null("Player")
	game_manager = get_node_or_null("GameManager")
	ui_manager = get_node_or_null("UILayer/UIManager")
	battle_system = get_node_or_null("BattleSystem")
	save_system = get_node_or_null("SaveSystem")
	map_loader = get_node_or_null("MapLoader")
	
	if not player:
		print("[GameScene] 警告：未找到玩家节点")
	if not game_manager:
		print("[GameScene] 警告：未找到游戏管理器")
	if not ui_manager:
		print("[GameScene] 警告：未找到 UI 管理器")

func _connect_signals() -> void:
	if game_manager:
		game_manager.battle_started.connect(_on_battle_started)
		game_manager.battle_won.connect(_on_battle_won)
		game_manager.game_over.connect(_on_game_over)
	
	if player:
		player.died.connect(_on_player_died)
		player.hp_changed.connect(_on_hp_changed)

func start_new_game() -> void:
	print("[GameScene] 开始新游戏")
	
	if game_manager:
		game_manager.start_game()
	
	if ui_manager:
		ui_manager.show_message("欢迎来到魔塔！使用方向键移动")
	
	if player:
		player.current_floor = start_floor

func _on_battle_started(enemy_data: Dictionary) -> void:
	print("[GameScene] 战斗开始：", enemy_data.get("name", "敌人"))
	if ui_manager:
		ui_manager.show_battle_start(enemy_data.get("name", "敌人"))

func _on_battle_won(rewards: Dictionary) -> void:
	print("[GameScene] 战斗胜利")
	if ui_manager:
		ui_manager.show_battle_victory(rewards.get("gold", 0))
		ui_manager.update_stats()

func _on_game_over() -> void:
	print("[GameScene] 游戏结束")
	if ui_manager:
		ui_manager.show_message("游戏结束", 3.0)

func _on_player_died() -> void:
	print("[GameScene] 玩家死亡")
	if ui_manager:
		ui_manager.show_battle_defeat()
	
	# 可以选择复活或游戏结束
	# await get_tree().create_timer(2.0).timeout
	# revive_player()

func _on_hp_changed(new_hp: int) -> void:
	if ui_manager:
		ui_manager.update_hp_only()

func revive_player() -> void:
	if player:
		player.current_hp = player.max_hp
		print("[GameScene] 玩家复活")

func save_game(slot: int) -> void:
	if not game_manager or not save_system:
		return
	
	var success = save_system.save_game(slot, game_manager.game_data)
	if ui_manager:
		ui_manager.show_save_slot(slot)
	
	if success:
		print("[GameScene] 游戏已保存到槽位 %d" % slot)

func load_game(slot: int) -> void:
	if not game_manager or not save_system:
		return
	
	var data = save_system.load_game(slot)
	if data.is_empty():
		print("[GameScene] 加载失败：存档不存在")
		return
	
	if ui_manager:
		ui_manager.show_load_slot(slot)
	
	# 恢复游戏数据
	if game_manager:
		game_manager.game_data = data
		if player:
			player.current_floor = data.get("current_floor", 1)
	
	print("[GameScene] 游戏已从槽位 %d 加载" % slot)
