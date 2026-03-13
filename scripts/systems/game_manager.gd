extends Node
class_name GameManager

## 游戏管理器 - 核心系统控制器
## 负责游戏状态、流程控制、战斗解析、存档管理

signal game_started
signal game_over
signal game_won
signal battle_started(enemy_data: Dictionary)
signal battle_won(rewards: Dictionary)
signal floor_changed(floor_id: int)
signal item_picked_up(item_data: Dictionary)
signal door_opened(door_type: String)
signal dialog_started(npc_id: String, dialog: String)

enum GameState { MENU, PLAYING, BATTLE, DIALOG, GAME_OVER, VICTORY }
var current_state: GameState = GameState.MENU

var player: Node
var ui_manager: Node
var map_loader: Node
var save_system: Node

var game_data: Dictionary = {
	"start_time": 0,
	"play_time": 0,
	"deaths": 0,
	"monsters_defeated": 0,
	"current_floor": 1,
	"max_floor_reached": 1,
	"items_collected": [],
	"keys": {},
	"total_damage_taken": 0,
	"total_damage_dealt": 0,
	"battles_won": 0,
	"battles_lost": 0
}

var current_floor_data: Dictionary = {}
var floor_enemies_defeated: Array = []

func _ready() -> void:
	print("[GameManager] 初始化完成")
	_find_references()

func _find_references() -> void:
	player = get_node_or_null("../Player")
	ui_manager = get_node_or_null("../UILayer/UIManager")
	map_loader = get_node_or_null("../MapLoader")
	save_system = get_node_or_null("SaveSystem")

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		game_data["play_time"] += delta

func start_game() -> void:
	print("[GameManager] 开始新游戏")
	_reset_game_data()
	
	if player:
		player.current_hp = player.max_hp
		player.attack = 10
		player.defense = 10
		player.gold = 0
		player.current_floor = 1
	
	if map_loader:
		map_loader.load_floor(1)
	
	set_state(GameState.PLAYING)
	game_started.emit()
	print("[GameManager] 游戏已启动")

func _reset_game_data() -> void:
	game_data = {
		"start_time": Time.get_unix_time_from_system(),
		"play_time": 0,
		"deaths": 0,
		"monsters_defeated": 0,
		"current_floor": 1,
		"max_floor_reached": 1,
		"items_collected": [],
		"keys": {},
		"total_damage_taken": 0,
		"total_damage_dealt": 0,
		"battles_won": 0,
		"battles_lost": 0
	}
	floor_enemies_defeated.clear()

func set_state(new_state: GameState) -> void:
	var old_state = current_state
	current_state = new_state
	print("[GameManager] 状态变更：%s -> %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])

func start_battle(enemy_data: Dictionary) -> void:
	if current_state != GameState.PLAYING:
		return
	
	set_state(GameState.BATTLE)
	battle_started.emit(enemy_data)
	print("[GameManager] 战斗开始：", enemy_data.get("name", "敌人"))
	_resolve_battle(enemy_data)

func _resolve_battle(enemy_data: Dictionary) -> void:
	var enemy_stats = enemy_data.get("stats", {})
	var player_stats = player.get_stats() if player else {}
	
	var player_hp = player_stats.get("hp", 1000)
	var player_atk = player_stats.get("attack", 10)
	var player_def = player_stats.get("defense", 10)
	
	var enemy_hp = enemy_stats.get("hp", 100)
	var enemy_atk = enemy_stats.get("attack", 20)
	var enemy_def = enemy_stats.get("defense", 5)
	
	var player_damage = max(0, player_atk - enemy_def)
	var enemy_damage = max(0, enemy_atk - player_def)
	
	if player_damage <= 0:
		print("[GameManager] 无法对敌人造成伤害！")
		_battle_lost()
		return
	
	var turns = ceil(float(enemy_hp) / player_damage)
	var total_damage = enemy_damage * (turns - 1)
	
	game_data["total_damage_dealt"] += enemy_hp
	game_data["total_damage_taken"] += total_damage
	
	if total_damage >= player_hp:
		_battle_lost()
	else:
		_battle_won(enemy_data, total_damage)

func _battle_won(enemy_data: Dictionary, damage_taken: int) -> void:
	if player:
		player.take_damage(damage_taken)
	
	var rewards = {
		"gold": enemy_data.get("stats", {}).get("gold", 0),
		"experience": enemy_data.get("stats", {}).get("experience", 0)
	}
	
	if player:
		player.gain_gold(rewards.gold)
	
	game_data["monsters_defeated"] += 1
	game_data["battles_won"] += 1
	
	var enemy_id = enemy_data.get("id", "")
	if enemy_id and not floor_enemies_defeated.has(enemy_id):
		floor_enemies_defeated.append(enemy_id)
	
	print("[GameManager] 战斗胜利！获得金币：", rewards.gold, " 受到损伤：", damage_taken)
	
	battle_won.emit(rewards)
	set_state(GameState.PLAYING)

func _battle_lost() -> void:
	print("[GameManager] 战斗失败")
	game_data["deaths"] += 1
	game_data["battles_lost"] += 1
	if player:
		player._die()

func change_floor(floor_id: int) -> void:
	print("[GameManager] 切换楼层：%d -> %d" % [game_data["current_floor"], floor_id])
	game_data["current_floor"] = floor_id
	if floor_id > game_data["max_floor_reached"]:
		game_data["max_floor_reached"] = floor_id
	
	if player:
		player.current_floor = floor_id
	
	floor_enemies_defeated.clear()
	
	if map_loader:
		map_loader.load_floor(floor_id)
	
	floor_changed.emit(floor_id)

func pick_up_item(item_data: Dictionary) -> void:
	print("[GameManager] 拾取道具：", item_data.get("name", "未知道具"))
	game_data["items_collected"].append(item_data.get("id", ""))
	
	if player:
		player.add_item(item_data)
	
	item_picked_up.emit(item_data)

func has_key(key_type: String) -> bool:
	return game_data["keys"].get(key_type, 0) > 0

func use_key(key_type: String) -> bool:
	if has_key(key_type):
		game_data["keys"][key_type] -= 1
		print("[GameManager] 使用钥匙：", key_type)
		return true
	return false

func add_key(key_type: String, count: int = 1) -> void:
	game_data["keys"][key_type] = game_data["keys"].get(key_type, 0) + count
	print("[GameManager] 获得钥匙：%s x%d" % [key_type, count])

func open_door(door_type: String) -> void:
	print("[GameManager] 打开门：", door_type)
	door_opened.emit(door_type)

func start_dialog(npc_id: String, dialog: String) -> void:
	set_state(GameState.DIALOG)
	dialog_started.emit(npc_id, dialog)
	print("[GameManager] NPC 对话：", npc_id)

func end_dialog() -> void:
	set_state(GameState.PLAYING)

func get_game_stats() -> Dictionary:
	return {
		"play_time": game_data["play_time"],
		"deaths": game_data["deaths"],
		"monsters_defeated": game_data["monsters_defeated"],
		"max_floor": game_data["max_floor_reached"],
		"battles_won": game_data["battles_won"],
		"battles_lost": game_data["battles_lost"]
	}

func save_game(slot: int) -> bool:
	print("[GameManager] 保存游戏到槽位：", slot)
	if save_system:
		return save_system.save_game(slot, game_data)
	return false

func load_game(slot: int) -> bool:
	print("[GameManager] 从槽位加载：", slot)
	if save_system:
		var loaded_data = save_system.load_game(slot)
		if loaded_data:
			game_data = loaded_data
			if player:
				player.current_floor = game_data["current_floor"]
			if map_loader:
				map_loader.load_floor(game_data["current_floor"])
			set_state(GameState.PLAYING)
			return true
	return false

func game_over() -> void:
	set_state(GameState.GAME_OVER)
	game_over.emit()
	print("[GameManager] 游戏结束")

func game_won() -> void:
	set_state(GameState.VICTORY)
	game_won.emit()
	print("[GameManager] 恭喜通关！")

func quit_game() -> void:
	get_tree().quit()
